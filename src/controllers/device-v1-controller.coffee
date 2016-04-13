JobToHttp = require '../helpers/job-to-http'
debug = require('debug')('meshblu-core-protocol-adapter-http:get-device-controller')
_     = require 'lodash'

class DeviceV1Controller
  constructor: ({@jobManager, @jobToHttp}) ->

  get: (req, res) =>
    job = @jobToHttp.httpToJob jobType: 'GetDevice', request: req, toUuid: req.params.uuid

    debug('dispatching request', job)
    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      if !error? && jobResponse.metadata?.code == 403
        error = code: 404, message: 'Devices not found'

      if error?
        if error.code == 403 # backwards compatibility with meshblu
          error.code = 404
          error.message = 'Devices not found'

        jsonError =
          code: error.code
          message: error.message
        return res.status(error.code ? 500).send jsonError

      # mutate to old meshblu devices array
      data = JSON.parse jobResponse.rawData
      jobResponse.rawData = JSON.stringify devices: [data]

      return @jobToHttp.sendJobResponse {res, jobResponse}

  getPublicKey: (req, res) =>
    job = @jobToHttp.httpToJob jobType: 'GetDevicePublicKey', request: req, toUuid: req.params.uuid
    debug('dispatching request', job)

    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.sendError error if error?
      @jobToHttp.sendJobResponse {jobResponse, res}

module.exports = DeviceV1Controller
