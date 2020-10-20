> a reverse proxy to face the attack of the public internet

The internet is a dangerous place. This reverse proxy will filter out "bad" requests so only "good" ones hit the app server

We apply filters like:
  1. only allow GET and HEAD methods
  1. ignore any url that contains `.php`
  1. only repond to requests for a host that we serve under

## Example

Run the example docker stack with:
```bash
cd example/
docker-compose up --build -d

curl -v localhost:30000
# 200, successful response, because 'localhost' is a valid host and GET is suported

curl --head localhost:30000
# 200, successful response because HEAD is supported

curl -X POST localhost:30000
# 403, we only support GET and HEAD

siege -v -b -r 1 -c 30 http://localhost:30000
# some requests will be allowed, the rest will be 503'd due to rate limiting

curl -v -H 'host: some.host' localhost:30000
# 200, successful response, because 'some.host' is a valid host

curl -v -H 'host: some.other.host' localhost:30000
# 404 because we don't listen on that host

echo 'GET http://some.other.host/ HTTP/1.1
Host: some.host
Accept: */*
' | nc -q 2 localhost 30000
# 404 because the garbage first line in the HTTP request overrides the (valid) Host header

docker-compose down
```

## Caching
By default, we have caching enabled. If you don't want *any* caching, you can disable it by
setting the env var on the container `NO_CACHE=1`.
