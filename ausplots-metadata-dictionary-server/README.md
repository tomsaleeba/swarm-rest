> ExpressJS HTTP server that acts as a facade to the TERN LinkedData repository
> and does an on-the-fly transformation of the Ausplots vocabulary to make it
> easier to consume.

# Developer quickstart
  1. clone repo
  1. install dependencies
      ```bash
      yarn
      ```
  1. run the server
      ```bash
      yarn start:watch
      # alternatively you can override where the data is pulled from
      JSONLD_URL=http://localhost:8080/test.json yarn start:watch
      ```
  1. use the service
      ```bash
      curl localhost:3000/ -H 'accept:application/json'
      ```

# How to deploy
  1. Launch with:
      ```bash
      yarn start:prod
      ```
  1. use the service
      ```bash
      curl localhost:3000/ -H 'accept:application/json'
      ```
