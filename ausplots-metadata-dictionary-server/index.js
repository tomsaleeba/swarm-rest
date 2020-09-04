const util = require('util')
const express = require('express')
const axios = require('axios')
const pino = require('pino')
const expressPino = require('express-pino-logger')
const jsonld = require('jsonld')

const port = process.env.PORT || 3000
let cachedValue = null
let cacheLastUpdated = 0
const cacheExpirySeconds =
  parseInt(process.env.CACHE_EXPIRY_SECONDS) || 4 * 60 * 60
const jsonLdSourceUrl = (() => {
  const defaultJsonLdSourceUrl =
    'https://linkeddata.tern.org.au/viewer/ausplots/download?format=json-ld'
  return process.env.JSONLD_URL || defaultJsonLdSourceUrl
})()

const app = express()
const logger = pino({ level: process.env.LOG_LEVEL || 'info' })
const expressLogger = expressPino({ logger })
app.use(expressLogger)

app.get('/', async (req, res) => {
  try {
    const result = await getResult()
    res.send(result)
  } catch (err) {
    logger.error(err)
    res.status(500).send({ status: 500, msg: 'Internal Server Error' })
  }
})

async function getResult() {
  const isCacheExpired =
    Date.now() > cacheLastUpdated + cacheExpirySeconds * 1000
  if (cachedValue && !isCacheExpired) {
    logger.info('Using cached data')
    return cachedValue
  }
  logger.info('Cache is empty or expired, rebuilding')
  cacheLastUpdated = Date.now()
  const allJsonLdData = await getAllJsonLdData()
  const result = await parseData(allJsonLdData)
  cachedValue = result
  return cachedValue
}

async function getAllJsonLdData() {
  logger.debug(`Using JSON-LD source URL: ${jsonLdSourceUrl}`)
  const resp = await axios.get(jsonLdSourceUrl)
  return resp.data
}

async function parseData(data) {
  const context = {
    // unsure if context is available from somewhere, so I hand-crafted it
    prefLabel: 'http://www.w3.org/2004/02/skos/core#prefLabel',
    notation: 'http://www.w3.org/2004/02/skos/core#notation',
    label: 'http://www.w3.org/2000/01/rdf-schema#label',
    description: 'http://purl.org/dc/terms/description',
    definition: 'http://www.w3.org/2004/02/skos/core#definition',
    member: {
      '@id': 'http://www.w3.org/2004/02/skos/core#member',
      '@type': '@id',
    },
  }
  const compacted = await jsonld.compact(data, context)
  debugger // FIXME delete line
  const graph = compacted['@graph']
  const variables = graph
    .filter(e => {
      const isCollection =
        e['@type'] === 'http://www.w3.org/2004/02/skos/core#Collection'
      const isProbablyMethod =
        !e.label || e.label.toLowerCase().includes('method')
      return isCollection && !isProbablyMethod
    })
    .reduce((accum, currVar) => {
      const values = processValues(currVar, graph)
      for (const currValue of values) {
        accum.push({
          // FIXME need our snake_case name for the variable
          variableCode:
            'FIXME, maybe ' + currVar.label.toLowerCase().replace(/ /g, '_'), // FIXME
          variableLabel: currVar.label,
          variableDefinition: currVar.definition,
          variableValueCode: currValue.code,
          variableValueLabel: currValue.label,
          variableValueDefinition: currValue.definition,
        })
      }
      return accum
    }, [])
  return variables
}

function processValues(parent, graph) {
  return parent.member.map(memberId => {
    const record = graph.find(v => v['@id'] === memberId)
    if (!record) {
      throw new Error(`Could not find record with @id=${memberId}`)
    }
    return {
      code: record.notation,
      label: record.label,
      definition: record.definition,
    }
  })
}

app.listen(port, () => {
  logger.info(`Ausplots metadata dictionary server running!
    Listening on port:    ${port}
    Cache expiry seconds: ${cacheExpirySeconds}
    Source URL:           ${jsonLdSourceUrl}`)
})
