MeshbluAuthParser = require '../helpers/meshblu-auth-parser'
debug = require('debug')('meshblu-server-http:get-device-controller')
_     = require 'lodash'

class DeviceV2Controller
  constructor: ({@jobManager}) ->
    @authParser = new MeshbluAuthParser

  revokeByQuery: (request, response) =>
    auth = @authParser.parse request

    job =
      metadata:
        auth: auth
        fromUuid: request.get('x-as') ? auth.uuid
        toUuid: request.params.uuid
        jobType: 'RevokeTokenByQuery'
      data: request.query

    debug('dispatching request', job)
    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      if error?
        jsonError =
          code: error.code
          message: error.message
        return response.status(error.code ? 500).send jsonError

      data = JSON.parse jobResponse.rawData

      _.each jobResponse.metadata, (value, key) => response.set "x-meshblu-#{key}", value
      response.status(jobResponse.metadata.code).send JSON.parse(jobResponse.rawData)

module.exports = DeviceV2Controller
