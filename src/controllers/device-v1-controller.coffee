JobToHttp = require '../helpers/job-to-http'
debug = require('debug')('meshblu-server-http:get-device-controller')
_     = require 'lodash'

class DeviceV1Controller
  constructor: ({@jobManager}) ->
    
  get: (req, res) =>
    job = JobToHttp.requestToJob jobType: 'GetDevice', request: req, toUuid: req.params.uuid

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

      _.each jobResponse.metadata, (value, key) => res.set "x-meshblu-#{key}", value
      data = JSON.parse jobResponse.rawData
      res.status(jobResponse.metadata.code).send devices: [data]

  getPublicKey: (req, res) =>
    job = JobToHttp.requestToJob jobType: 'GetDevicePublicKey', request: req, toUuid: req.params.uuid
    debug('dispatching request', job)

    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.status(error.code ? 500).send(error: error.message) if error?

      _.each jobResponse.metadata, (value, key) => res.set "x-meshblu-#{key}", value
      res.status(jobResponse.metadata.code).send JSON.parse jobResponse.rawData

module.exports = DeviceV1Controller
