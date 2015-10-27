redis             = require 'redis'
Authenticator     = require '../models/authenticator'
MeshbluAuthParser = require '../helpers/meshblu-auth-parser'

class AuthenticateController
  constructor: (options={}, dependencies={}) ->
    {@authenticator} = dependencies

    @authenticator ?= new Authenticator
      client: redis.createClient process.env.REDIS_URI
    @authParser = new MeshbluAuthParser

  authenticate: (request, response) =>
    {uuid,token} = @authParser.parse request

    return response.status(401).end() unless uuid?

    @authenticator.authenticate uuid, token, (error, isAuthenticated) =>
      return response.status(502).end() if error?
      return response.status(403).end() unless isAuthenticated
      response.status(204).end()


module.exports = AuthenticateController
