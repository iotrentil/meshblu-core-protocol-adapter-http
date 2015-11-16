Authenticator     = require '../models/authenticator'
MeshbluAuthParser = require '../helpers/meshblu-auth-parser'
debug = require('debug')('meshblu-server-http:authenticate-controller')

class AuthenticateController
  constructor: ({@timeoutSeconds}={})->

  authenticate: (request, response) =>
    {uuid,token} = new MeshbluAuthParser().parse request

    authenticator = new Authenticator
      client: request.connection
      timeoutSeconds: @timeoutSeconds

    authenticator.authenticate uuid, token, (error, authResponse) =>
      return response.status(502).end() if error?
      response.status(authResponse.metadata.code).end()

module.exports = AuthenticateController
