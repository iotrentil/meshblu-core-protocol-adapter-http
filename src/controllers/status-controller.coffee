debug = require('debug')('meshblu-core-protocol-adapter-http:get-status-controller')
_     = require 'lodash'

class StatusController
  constructor: ({@jobManager,@jobToHttp}) ->

  get: (req, res) =>
    job = @jobToHttp.httpToJob jobType: 'GetStatus', request: req, toUuid: req.params.uuid

    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.sendError error if error?
      @jobToHttp.sendJobResponse {res, jobResponse}

module.exports = StatusController
