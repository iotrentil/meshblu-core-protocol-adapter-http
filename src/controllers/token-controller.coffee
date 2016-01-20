MeshbluAuthParser = require '../helpers/meshblu-auth-parser'
debug = require('debug')('meshblu-server-http:get-device-controller')
_     = require 'lodash'
JobToHttp = require '../helpers/job-to-http'

class DeviceV2Controller
  constructor: ({@jobManager}) ->

  revokeByQuery: (req, res) =>
    job = JobToHttp.requestToJob jobType: 'RevokeTokenByQuery', request: req, toUuid: req.params.uuid
    job.data = req.query

    debug('dispatching request', job)
    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      if error?
        jsonError =
          code: error.code
          message: error.message
        return res.status(error.code ? 500).send jsonError

      data = JSON.parse jobResponse.rawData

      _.each jobResponse.metadata, (value, key) => res.set "x-meshblu-#{key}", value
      res.status(jobResponse.metadata.code).send JSON.parse(jobResponse.rawData)

module.exports = DeviceV2Controller
