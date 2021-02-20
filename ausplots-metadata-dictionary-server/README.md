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

## Maintenance
If you see the following message in the logs
```
Programmer problem: Could not find variable code mapping for ID=http://linked.data.gov.au/def/ausplots-cv/1e3327d0-e572-4c6b-8836-b4e226adc089
```
...then it means the TERN linked data service is returning a vocab that this
server doesn't know how to handle. As a developer for this project, you'll need to update the code to handle this new value, by:

  1. the ID is a URL, so go to the URL and see what vocab it's for. In the case
     of the one above, the vocab is *Vegetation strata values*.
  1. figure out if this vocab is something that is returned in an AusplotsR
     data frame. You should know this because the postgREST component of this
     stack is what provides the data to AusplotsR, so if you've just added a
     new column to one of the views in `../script.sql` then this new vocab is
     probably something you need to handle.
  1. if you *are* adding support, add this new ID either as a new item in the
     `getVariableCodeMappings()` lookup function or the `nonVocabVarsToProcess`
     array depending on if it's an enum vocab or scalar values.
  1. if you are *not* supporting this new vocab, you can ignore it by adding
     the ID to the `ignoreList` array. For our example ID above, we don't need
     to add support because we explicitly have the values for ground, mid and
     upper stratum species but we don't have a column that uses this vocab.
  1. save, test, lint, commit, push, etc like you would with any other code
     change. Then update the prod server to run the new code.

# How to deploy
  1. Launch with:
      ```bash
      yarn start:prod
      ```
  1. use the service
      ```bash
      curl localhost:3000/ -H 'accept:application/json'
      ```
