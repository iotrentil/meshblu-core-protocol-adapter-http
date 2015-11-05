Subscriber     = require '../models/subscriber'
MeshbluAuthParser = require '../helpers/meshblu-auth-parser'
redis = require 'redis'
RedisNS = require '@octoblu/redis-ns'

class SubscriptionsController
  constructor: (options, dependencies={}) ->
    {@subscriber} = dependencies
    @subscriber ?= new Subscriber
      client: new RedisNS('meshblu', redis.createClient(process.env.REDIS_URI))
    @authParser = new MeshbluAuthParser

  getAll: (request, response)=>
    internalRequest =
      auth:     @authParser.parse request
      fromUuid: request.get('x-as')
      toUuid:   request.params.uuid

    @subscriber.getSubscriptions internalRequest, (error, subscribeResponse) =>
      return response.status(502).end() if error?
      {code} = subscribeResponse.metadata
      response.status(code).json subscribeResponse.data

module.exports = SubscriptionsController
