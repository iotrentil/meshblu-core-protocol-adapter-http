MeshbluAuthParser = require '../helpers/meshblu-auth-parser'
debug = require('debug')('meshblu-server-http:authenticate-controller')
_     = require 'lodash'

class AuthenticateController
  constructor: ({@jobManager,@jobToHttp}) ->
    @authParser = new MeshbluAuthParser

  create: (req, res) =>
    job = @jobToHttp.httpToJob jobType: 'Authenticate', request: req

    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.sendError error if error?
      @jobToHttp.sendJobResponse {jobResponse, res}

module.exports = AuthenticateController
