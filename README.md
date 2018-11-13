> RESTful HTTP API to serve up Ausplots data from a postgres database using postgREST

This directory contains the files required to run the HTTP REST API server that the [ausplotsR client](https://github.com/GregGuerin/ausplotsR) talks to.

The DB init script (`script.sql`) does a number of things:
  1. create a schema just for the API, named `api`
  1. create a role that can SELECT from (only) the `api` schema
  1. create a number of views in the `api` schema that pull from tables in the `public` schema

postgREST will then serve everything from the `api` schema and because they're just views, they'll be read-only.

## Running the stack

Make sure you meet the requirements:

  1. docker >= 18.06
  1. docker-compose >= 1.22.0
  1. a recent PG dump of the SWARM DB
  1. AWS credentials for IAM user to store ElasticSearch snapshots (use `./create-aws-s3-user-and-bucket.sh` script to create)

To start the stack:

  1. clone this repo and `cd` into the workspace
  1. [allow more virtual memory](https://www.elastic.co/guide/en/elasticsearch/reference/current/vm-max-map-count.html#vm-max-map-count) on the host (ES needs this)
      ```bash
      sysctl -w vm.max_map_count=262144
      ```
  1. copy the runner script
      ```bash
      cp start-or-restart.sh.example start-or-restart.sh
      chmod +x start-or-restart.sh
      ```
  1. edit the runner script `start-or-restart.sh` to define the needed environmental variables
      ```bash
      vim start-or-restart.sh
      ```
  1. start the stack
      ```bash
      ./start-or-restart.sh
      # or if you need to force a rebuild of the 'curl-cron' image
      ./start-or-restart.sh --build
      ```
  1. restore the DB dump (any format pg_restore supports) to the `app_db` database
      ```bash
      cat swarm.dump | docker exec -i swarm-rest_db_1 sh -c 'pg_restore --no-owner -U postgres -d swarm -v'
      ```
  1. connect as a superuser and run the `./script.sql` file to create all required objects for the API to run
      ```bash
      cat script.sql | docker exec -i swarm-rest_db_1 sh -c 'psql -U postgres -d swarm'
      ```
  1. use the service
      ```bash
      curl -v <hostname>:3000/site?limit=1
      # the response should be a JSON array of objects, e.g. [{"site_location_name":"...
      ```
  1. check the Kibana dashboard for metrics at http://<hostname>:5601 (port can be changed in `.env`)

## Running health check tests

There are some brief health check tests you can run against a live service to make sure it's returning what you expect. First, make sure you satisfy the requirements:

  1. python 2.7
  1. python `requests`

You can run it with:
```bash
./tests.py <base URL>
```

For example, you could pass a URL like
```bash
./tests.py http://swarmapi.ausplots.aekos.org.au:3000
```

## Stopping the stack
The stack is design to always keep running, even after a server restart, until you manually stop it. The data for postgres and ElasticSearch are stored in Docker data volumes. This means you can stop and destroy the stack, but **keep the data** with:
```bash
docker-compose down
```

If you want to completely clean up and have the data volumes also removed, you can do this with:
```bash
docker-compose down --volumes
```

## Connect to DB with psql
You can connect to the DB if you SSH to the docker host, then run:
```bash
docker exec -it swarm-rest_db_1 sh -c 'psql -U app_user -d app_db'
```

## Known problems
  1. Sometimes Kibana times out (exhausts the 30 seconds of waiting to start) when starting. I don't know why but the container will keep restarting until it finally comes up. Just wait I guess.

