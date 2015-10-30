redis             = require 'redis'
RedisNS           = require '@octoblu/redis-ns'
Authenticator     = require '../models/authenticator'
MeshbluAuthParser = require '../helpers/meshblu-auth-parser'
debug = require('debug')('meshblu-http-server:authenticate-controller')

class AuthenticateController
  constructor: (options={}, dependencies={}) ->
    {@authenticator} = dependencies

    @authenticator ?= new Authenticator
      client: new RedisNS('meshblu', redis.createClient(process.env.REDIS_URI))

    @authParser = new MeshbluAuthParser

  authenticate: (request, response) =>
    {uuid,token} = @authParser.parse request

    @authenticator.authenticate uuid, token, (error, authResponse) =>
      return response.status(502).end() if error?
      response.status(authResponse.metadata.code).end()

module.exports = AuthenticateController
