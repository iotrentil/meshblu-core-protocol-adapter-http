MeshbluAuthParser = require '../helpers/meshblu-auth-parser'
debug = require('debug')('meshblu-server-http:authenticate-controller')
_     = require 'lodash'

class AuthenticateController
  constructor: ({@jobManager}) ->
    @authParser = new MeshbluAuthParser

  create: (req, res) =>
    auth = @authParser.parse req

    options =
      metadata:
        auth: auth
        jobType: 'Authenticate'

    @jobManager.do 'request', 'response', options, (error, jobResponse) =>
      return res.sendError error if error?
      _.each jobResponse.metadata, (value, key) => res.set "x-meshblu-#{key}", value
      res.status(jobResponse.metadata.code).end()

module.exports = AuthenticateController
