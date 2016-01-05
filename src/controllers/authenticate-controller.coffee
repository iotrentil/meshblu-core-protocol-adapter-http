MeshbluAuthParser = require '../helpers/meshblu-auth-parser'
debug = require('debug')('meshblu-server-http:authenticate-controller')

class AuthenticateController
  constructor: ({@jobManager}) ->
    @authParser = new MeshbluAuthParser

  create: (req, res) =>
    auth = @authParser.parse req

    options =
      metadata:
        auth: auth
        jobType: 'Authenticate'

    @jobManager.do 'request', 'response', options, (error, response) =>
      return res.status(error.code ? 500).send(error.message) if error?
      res.status(response.metadata.code).end()

module.exports = AuthenticateController
