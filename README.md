> RESTful HTTP API to serve up Ausplots data from a postgres database using postgREST

This directory contains the files required to run the HTTP REST API server that the [ausplotsR client](https://github.com/ternaustralia/ausplotsR) talks to.

The DB init script (`script.sql`) does a number of things:
  1. create a schema just for the API, named `api`
  1. create a role that can SELECT from (only) the `api` schema
  1. create a number of views in the `api` schema that pull from tables in the `public` schema

postgREST will then serve everything from the `api` schema and because they're just views, they'll be read-only.

We collect usage metrics on the service by intercepting all traffic to the API and then store these metrics in
ElasticSearch. Kibana is included for visualising the usage. The ES data is also periodcally snapshotted onto
S3 for safe keeping.

As this is just a mirror of production, we have a container to periodically synchronise the data in SWARM
production into our DB.

We also have a read-only user auto-created so the DB can be used as a safe way to share a fresh-ish mirror of
production.

## Running the stack

Make sure you meet the requirements:

  1. docker >= 18.06
  1. docker-compose >= 1.22.0
  1. credentials for perform SELECT queries on the production Ausplots SWARM postgres DB, or another DB if you choose. See section below for creating this user.
  1. AWS credentials for IAM user to store ElasticSearch snapshots (use `./create-aws-s3-user-and-bucket.sh` script to create)

To start the stack:

  1. clone this repo and `cd` into the workspace
  1. [allow more virtual memory](https://www.elastic.co/guide/en/elasticsearch/reference/current/vm-max-map-count.html#vm-max-map-count) on the host (ES needs this)
      ```bash
      echo vm.max_map_count=262144 | sudo tee -a /etc/sysctl.conf # only run this once for a host
      sudo sysctl -p # read the new config
      ```
  1. copy the runner script
      ```bash
      cp start-or-restart.sh.example start-or-restart.sh
      chmod +x start-or-restart.sh
      ```
  1. edit the runner script `start-or-restart.sh` to define the needed sensitive environmental variables
      ```bash
      vim start-or-restart.sh
      ```
  1. start the stack
      ```bash
      ./start-or-restart.sh
      # or if you need to force a rebuild of the 'curl-cron' and 'db-sync' images, which you should do after a `git pull`
      ./start-or-restart.sh --build
      # or if you don't want the ElasticSearch related infrastructure (like during dev)
      env NO_ES=1 ./start-or-restart.sh
      ```
  1. wait until the `db` container is up and running (shouldn't take long):
      ```console
      $ docker logs --tail 10 swarmrest_db
      PostgreSQL init process complete; ready for start up.

      2018-11-15 02:19:24.920 UTC [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
      2018-11-15 02:19:24.920 UTC [1] LOG:  listening on IPv6 address "::", port 5432
      2018-11-15 02:19:24.934 UTC [1] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
      2018-11-15 02:19:24.964 UTC [70] LOG:  database system was shut down at 2018-11-15 02:19:24 UTC
      2018-11-15 02:19:24.976 UTC [1] LOG:  database system is ready to accept connections
      ```
  1. trigger a schema-only sync (should take less than a minute)
      ```bash
      docker exec -i swarmrest_db_sync sh -c 'SCHEMA_ONLY=1 sh /app/run.sh'
      ```
  1. trigger a data sync to get us up and running (should take around a minute)
      ```bash
      docker exec -i swarmrest_db_sync sh -c 'sh /app/run.sh'
      ```
  1. connect as a superuser and run the `./script.sql` file to create all required objects for the API to run.
     See section 'Modifying our copy of the schema' for more discussion about re-running.
      ```bash
      cat script.sql | docker exec -i swarmrest_db sh -c 'psql -U $POSTGRES_USER -d $POSTGRES_DB --set=ON_ERROR_STOP=1'
      ```
  1. look for the success output at the end of the script:
      ```
      outcome
      ---------
      success
      (1 row)
      ```
  1. if you're re-creating a prod instance, check the section below about restoring ES snapshots
  1. use the service
      ```bash
      curl -v '<hostname:port>/site?limit=1'
      # the response should be a JSON array of objects, e.g. [{"site_location_name":"...
      ```
  1. check the Kibana dashboard for metrics at http://<hostname>:5601 (port can be changed in `.env`)

Warning: the Kibana (ELK stack) instance has no security/auth so don't expose it to the internet. Or if you
do, add some security. A nice way to connect to the Kibana dashboard on a VM without opening the firewall is
to use SSH local port forwarding
(https://help.ubuntu.com/community/SSH/OpenSSH/PortForwarding#Local_Port_Forwarding).

## Running health check tests

There are some brief health check tests you can run against a live service to make sure it's returning what
you expect. First, make sure you satisfy the requirements:

  1. python 2.7
  1. python `requests`

You can run it with:
```bash
./tests/tests.py <base URL>
```

For example, you could pass a URL like
```bash
./tests/tests.py http://swarmapi.ausplots.aekos.org.au
```

## Modifying our copy of the schema
In the set up steps, we first sync the schema, then sync the data then run our script to create the bits we
need. Future data syncs won't touch the schema, which means our script can make changes -- like adding row
level security or granting access -- to our copy of the schema. If you ever do another sync of the schema, you
*must* re-run the script. If it re-running doesn't work for any reason, you can recover by killing the PG
container and starting again:

  1. stop the stack
      ```bash
      docker-compose down
      ```
  1. destroy the volume from the postgres container
      ```bash
      docker volume rm swarm-rest_swarm-pgdata
      ```
  1. continue with the steps in the initial setup starting from running the `start-or-restart.sh` script

## Stopping the stack
The stack is designed to always keep running, even after a server restart, until you manually stop it. The
data for postgres and ElasticSearch are stored in Docker data volumes. This means you can stop and destroy the
stack, but **keep the data** with:
```bash
docker-compose down
```

If you want to completely clean up and have the **data volumes also removed**, you can do this with:
```bash
docker-compose down --volumes
```

## Creating a role in SWARM production to use for DB sync
Use these queries to create a user that you can use for the DB sync process:

```sql
CREATE ROLE syncuser PASSWORD 'somegoodpassword';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO syncuser;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO syncuser;
```

## Restoring ElasticSearch snapshots

The name of the snapshot repo is defined in the `.env` file as `ES_SNAPSHOT_REPO`. For this example, let's
assume that it's `swarm-s3-backup`. Also, as we don't expose the ES instance to the public internet, you'll
need to run these command on the docker host to have access (or through an SSH tunnel if you're fancy).

  1. let's list all the available snapshots
      ```console
      $ curl 'http://localhost:9200/_snapshot/swarm-s3-backup/_all'
      [
        {
          "snapshot": "swarm-metrics.20181115_0903",
          "uuid": "XoHfmTbaROqgKlI0jvEWjw",
          "indices": [
            "swarm-rest",
            ".kibana"
          ],
          "state": "SUCCESS",
          "start_time": "2018-11-15T09:03:00.836Z",
          ...
        },
        ...
      ]
      ```
  1. pick a snapshot to restore, and let's restore it
      ```console
      $ curl -X POST 'http://localhost:9200/_snapshot/swarm-s3-backup/swarm-metrics.20181115_0903/_restore?wait_for_completion'
      {
        "snapshot": {
          "snapshot": "swarm-metrics.20181115_0903",
          "indices": [
            ".kibana",
            "swarm-rest"
          ],
          "shards": {
            "total": 6,
            "failed": 0,
            "successful": 6
          }
        }
      }
      ```
  1. if you get an error that indicies are already open, you can remove the ES container and its volume, then
     create a fresh one to start from a clean slate:
      ```bash
      docker rm -f swarmrest_elk
      docker volume rm swarmrest_elk-data
      ./start-or-restart.sh
      docker logs --tail 10 -f swarmrest_elk # watch the logs until Kibana has started up
      # <control-> to stop tailing logs...
      # ...then try the restore again
      ```

## Connect to DB with psql
You can connect to the DB as the superuser if you SSH to the docker host, then run:
```bash
docker exec -it swarmrest_db sh -c 'psql -U $POSTGRES_USER -d $POSTGRES_DB'
```

## Known problems
  1. Kibana has no auth so we can't open it to the public yet
  1. sometimes ES dies inside the ELK stack but Docker can't see it. We're using a health check and the
     autoheal container but as an alternative we could go for the official, separate images for Kibana and ES
     so they're PID 1 and can be monitored and bounced by docker if they die.
  1. consider adding fail2ban to the stack to help nginx provide protection. Maybe something like https://github.com/crazy-max/docker-fail2ban but that writes error.log to stderr so that needs to be piped into file too so f2b can read it.

