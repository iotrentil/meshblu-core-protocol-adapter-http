debug             = require('debug')('meshblu-server-http:whoami-controller')
MeshbluAuthParser = require '../helpers/meshblu-auth-parser'

class WhoamiController
  constructor: ({@jobManager, @jobToHttp}) ->
    @authParser = new MeshbluAuthParser

  show: (req, res) =>
    auth = @authParser.parse req
    job = @jobToHttp.httpToJob jobType: 'GetDevice', request: req, toUuid: auth.uuid

    debug('dispatching request', job)
    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.status(error.code ? 500).send(error.message) if error?
      @jobToHttp.sendJobResponse {jobResponse, res}

module.exports = WhoamiController
