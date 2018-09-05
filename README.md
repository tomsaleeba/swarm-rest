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

To start the stack:

  1. clone the repo
  1. start the stack
      ```bash
      docker-compose -d up
      ```
  1. restore the DB dump to the `app_db` database
  1. connect as a superuser and run the `./script.sql` file to create all required objects for the API to run
  1. test the service
      ```bash
      curl -v <hostname>:3000/site?limit=1
      # the response should be a JSON array of objects, e.g. [{"site_location_name":"...
      ```

