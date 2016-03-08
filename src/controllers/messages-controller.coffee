debug = require('debug')('meshblu-server-http:messages-controller')
_     = require 'lodash'
JobToHttp = require '../helpers/job-to-http'
MeshbluAuthParser = require '../helpers/meshblu-auth-parser'

class MessagesController
  constructor: ({@jobManager, @jobToHttp}) ->
    @authParser = new MeshbluAuthParser

  create: (req, res) =>
    auth = @authParser.parse req
    job = @jobToHttp.httpToJob jobType: 'SendMessage', request: req, toUuid: auth.uuid

    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.sendError error if error?
      @jobToHttp.sendJobResponse {jobResponse, res}

module.exports = MessagesController
