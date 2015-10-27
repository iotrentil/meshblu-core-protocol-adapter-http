async = require 'async'
debug = require('debug')('meshblu-http-server:redis-job')

class RedisJob
  constructor: (options={}) ->
    {@namespace,@client} = options

  createRequest: (options, callback)=>
    {metadata,data,responseId,rawData} = options
    data ?= null

    metadataStr = JSON.stringify metadata
    rawData ?= JSON.stringify data

    debug "@client.hset", "#{@namespace}:#{responseId}", 'request:metadata', metadataStr
    async.series [
      async.apply @client.hset, "#{@namespace}:#{responseId}", 'request:metadata', metadataStr
      async.apply @client.hset, "#{@namespace}:#{responseId}", 'request:data', rawData
      async.apply @client.lpush, "#{@namespace}:request:queue", "#{@namespace}:#{responseId}"
    ], callback

  createResponse: (options, callback)=>
    {metadata,data,responseId,rawData} = options
    data ?= null

    metadataStr = JSON.stringify metadata
    rawData ?= JSON.stringify data

    debug "@client.hset", "#{@namespace}:#{responseId}", 'response:metadata', metadataStr
    async.series [
      async.apply @client.hset, "#{@namespace}:#{responseId}", 'response:metadata', metadataStr
      async.apply @client.hset, "#{@namespace}:#{responseId}", 'response:data', rawData
      async.apply @client.lpush, "#{@namespace}:response:#{responseId}", "#{@namespace}:#{responseId}"
    ], callback

module.exports = RedisJob
