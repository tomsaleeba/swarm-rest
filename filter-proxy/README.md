> a reverse proxy to face the attack of the public internet

The internet is a dangerous place. Exposing `mitmproxy` directly results in a flood of warnings/errors. It still serves requests but CPU load is much higher than we'd like.

To combat that, we're deploying this nginx as a reverse proxy in front to try to filter out as much rubbish as we can.

Run the example docker stack with:
```bash
docker-compose -f test-docker-compose.yml up --build -d
curl locahost:30000/200
# successful response
curl -X POST localhost:30000/200
# 403!
siege -v -b -r 1 -c 50 http://localhost:30000
# some requests will be allowed, the rest will be 503'd due to rate limiting
docker-compose -f test-docker-compose.yml down
```
