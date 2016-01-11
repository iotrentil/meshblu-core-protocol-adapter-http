MeshbluAuthParser = require '../helpers/meshblu-auth-parser'
debug = require('debug')('meshblu-server-http:get-device-controller')
_     = require 'lodash'

class DeviceV2Controller
  constructor: ({@jobManager}) ->
    @authParser = new MeshbluAuthParser

  get: (req, res) =>
    auth = @authParser.parse req

    job =
      metadata:
        auth: auth
        fromUuid: req.get('x-meshblu-as') ? req.get('x-as')
        toUuid: req.params.uuid
        jobType: 'GetDevice'

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

      data = JSON.parse jobResponse.rawData
      unless data?
        jsonError =
          code: 404
          message: 'Devices not found'
        return res.status(404).send jsonError

      _.each jobResponse.metadata, (value, key) => res.set "x-meshblu-#{key}", value
      res.status(jobResponse.metadata.code).send JSON.parse(jobResponse.rawData)

module.exports = DeviceV2Controller
