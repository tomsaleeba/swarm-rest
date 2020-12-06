import io
import os
from functools import reduce
import requests
import flask
from matplotlib.backends.backend_agg import FigureCanvasAgg
from matplotlib.figure import Figure

es_url_prefix = os.getenv('ES_URL_PREFIX', default='http://localhost:9200')
page_size = 200
addr_agg_name = 'addr_agg'
min_agg_name = 'min_agg'

app = flask.Flask(__name__)


def make_post_body(after):
    some_key = 'magical_unicorns'
    comp = {
        "size": page_size,
        "sources": [{
            some_key: {
                "terms": {
                    "field": "remoteAddr.keyword",
                }
            }
        }]
    }
    if after:
        comp['after'] = after
    return {
        "size": 0,  # no records, only agg results
        "query": {
            "terms": {
                # these resources are used as part of get_ausplots, so this is
                # our proxy for ausplotsR users, as opposed to other callers of
                # the API.
                "resource.keyword": ["/site", "/search"]
            }
        },
        "aggs": {
            addr_agg_name: {
                "composite": comp,
                "aggs": {
                    min_agg_name: {
                        "min": {
                            "field": "eventDate"
                        }
                    }
                }
            }
        }
    }


def reducer(accum, curr):
    key = curr[min_agg_name]['value_as_string'][:7]
    try:
        accum[key] += 1
    except KeyError:
        accum[key] = 1
    return accum


def get_data():
    the_url = f'{es_url_prefix}/swarm-rest/_search'
    app.logger.info(f'Getting data from ES with URL={the_url}')
    is_more = True
    after_key = None
    count_dict = {}
    while is_more:
        post_body = make_post_body(after_key)
        app.logger.debug(f'POST body is: {str(post_body)}')
        resp = requests.post(the_url, json=post_body)
        if not resp.ok:
            raise Exception(f'Failed to make HTTP call to ES: {resp.text}')
        app.logger.info('Parsing ES response')
        resp_body = resp.json()
        agg_results = resp_body['aggregations'][addr_agg_name]
        vals = agg_results['buckets']
        count_dict = reduce(reducer, vals, count_dict)
        try:
            after_key = agg_results['after_key']
            is_more = True
            app.logger.info('Another page exists')
        except KeyError:
            is_more = False
            app.logger.info('No more pages')
    count_list = list(count_dict.items())
    count_list.sort()

    def do_cumulation(accum, curr):
        try:
            prev = accum[-1]
            prev_count = prev[1]
            val = prev_count + curr[1]
        except IndexError:
            val = curr[1]
        curr_year = curr[0]
        accum.append((curr_year, val))
        return accum

    cumulative_list = reduce(do_cumulation, count_list, [])
    return cumulative_list


@app.route('/')
def users_over_time_png():
    data = get_data()
    app.logger.info(f'Dataset size={len(data)}')
    years = list(map(lambda x: x[0], data))
    counts = list(map(lambda x: x[1], data))

    # thanks https://stackoverflow.com/a/50728936/1410035
    fig = Figure()
    axis = fig.add_subplot(1, 1, 1)
    axis.stackplot(years, counts)
    axis.set(xlabel='months',
             ylabel='Count of users',
             title='AusplotsR cumulative user growth')
    # axis.tick_params(axis='x', labelrotation=65) # falls off the bottom
    # thanks https://deanla.com/spacious-matplotlib-tickss.html
    axis.set_xticks(axis.get_xticks()[::6])

    output = io.BytesIO()
    FigureCanvasAgg(fig).print_png(output)
    return flask.Response(output.getvalue(), mimetype='image/png')


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=30006, debug=True)
