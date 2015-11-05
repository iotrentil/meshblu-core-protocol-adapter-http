Subscriber     = require '../models/subscriber'
MeshbluAuthParser = require '../helpers/meshblu-auth-parser'

class SubscriptionsController
  constructor: (options, dependencies={}) ->
    {@subscriber} = dependencies
    @subscriber ?= new Subscriber
      client: new RedisNS('meshblu', redis.createClient(process.env.REDIS_URI))
    @authParser = new MeshbluAuthParser

  getAll: (request, response)=>
    auth = @authParser.parse request

    internalRequest =
      metadata:
        auth: auth
        fromUuid: request.get('x-as') ? auth.uuid
        toUuid: request.params.uuid

    @subscriber.getSubscriptions internalRequest, (error, subscribeResponse) =>
      return response.status(502).end() if error?
      {code} = subscribeResponse.metadata
      response.status(code).json subscribeResponse.data

module.exports = SubscriptionsController
