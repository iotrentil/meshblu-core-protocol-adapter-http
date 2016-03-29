MeshbluAuthParser = require '../helpers/meshblu-auth-parser'
debug = require('debug')('meshblu-core-protocol-adapter-http:authenticate-controller')
_     = require 'lodash'

class AuthenticateController
  constructor: ({@jobManager,@jobToHttp}) ->
    @authParser = new MeshbluAuthParser

  check: (req, res) =>
    job = @jobToHttp.httpToJob jobType: 'Authenticate', request: req, toUuid: req.params.uuid

    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.sendError error if error?
      @jobToHttp.sendJobResponse {jobResponse, res}

  checkDevice: (req, res) =>
    {uuid} = req.params
    {token} = req.query
    job = @jobToHttp.httpToJob jobType: 'Authenticate', request: req
    job.metadata.auth = {uuid, token}
    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.sendError error if error?
      {code} = jobResponse.metadata
      return res.status(code).send JSON.parse jobResponse.rawData unless code == 204
      res.status(200).send(uuid: uuid, authentication: true)

module.exports = AuthenticateController
