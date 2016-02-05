MeshbluAuthParser = require '../helpers/meshblu-auth-parser'
debug = require('debug')('meshblu-server-http:get-device-controller')
_     = require 'lodash'
JobToHttp = require '../helpers/job-to-http'

class DeviceV2Controller
  constructor: ({@jobManager, @jobToHttp}) ->

  revokeByQuery: (req, res) =>
    job = @jobToHttp.httpToJob
      jobType: 'RevokeTokenByQuery'
      request: req
      toUuid: req.params.uuid
      data: req.query

    debug('dispatching request', job)
    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.status(error.code ? 500).send(error.message) if error?
      @jobToHttp.sendJobResponse {jobResponse, res}

module.exports = DeviceV2Controller
