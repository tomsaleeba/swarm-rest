> a reverse proxy to face the attack of the public internet

The internet is a dangerous place. Exposing `mitmproxy` directly results in a flood of warnings/errors. It still serves requests but CPU load is much higher than we'd like.

To combat that, we're deploying this nginx as a reverse proxy in front to try to filter out as much rubbish as we can.

Run the example docker stack with:
```bash
docker-compose -f test-docker-compose.yml up --build -d
curl localhost:30000/200
# successful response
curl -X POST localhost:30000/200
# 403, we only support GET and HEAD
siege -v -b -r 1 -c 50 http://localhost:30000
# some requests will be allowed, the rest will be 503'd due to rate limiting
curl -v localhost:30000
# successful response, because 'localhost' is a valid host
curl -v -H 'host: swarmapi.ausplots.aekos.org.au' localhost:30000
# successful response, because 'swarmapi.ausplots.aekos.org.au' is a valid host
curl -v -H 'host: some.other.host' localhost:30000
# 404 because we don't listen on that host
echo -e 'GET http://some.other.host/ HTTP/1.1\nHost: swarmapi.ausplots.aekos.org.au\nAccept: */*\n' | nc -q 2 localhost 30000
# 404 because the garbage first line in the HTTP request overrides the Host header

docker-compose -f test-docker-compose.yml down
```
