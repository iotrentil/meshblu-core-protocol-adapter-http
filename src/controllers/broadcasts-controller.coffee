debug = require('debug')('meshblu-core-protocol-adapter-http:messages-controller')
_     = require 'lodash'
JobToHttp = require '../helpers/job-to-http'
MeshbluAuthParser = require '../helpers/meshblu-auth-parser'

class BroadcastsController
  constructor: ({@jobManager, @jobToHttp}) ->
    @authParser = new MeshbluAuthParser

  create: (req, res) =>
    auth = @authParser.parse req
    req.body = {} if _.isEmpty req.body

    return res.sendStatus(422) unless _.isPlainObject req.body

    job = @jobToHttp.httpToJob jobType: 'SendMessage', request: req, toUuid: auth.uuid
    job.data.devices = ['*']
    @jobManager.do job, (error, jobResponse) =>
      return res.sendError error if error?
      @jobToHttp.sendJobResponse {jobResponse, res}

module.exports = BroadcastsController
