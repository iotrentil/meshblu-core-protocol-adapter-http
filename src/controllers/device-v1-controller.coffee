JobManager = require 'meshblu-core-job-manager'
MeshbluAuthParser = require '../helpers/meshblu-auth-parser'
debug = require('debug')('meshblu-server-http:get-device-controller')
_     = require 'lodash'

class DeviceV1Controller
  constructor: ({@timeoutSeconds}) ->
    @authParser = new MeshbluAuthParser

  get: (req, res) =>
    jobManager = new JobManager
      client: req.connection
      timeoutSeconds: @timeoutSeconds

    auth = @authParser.parse req

    job =
      metadata:
        auth: auth
        fromUuid: req.get('x-as') ? auth.uuid
        toUuid: req.params.uuid
        jobType: 'GetDevice'

    debug('dispatching request', job)
    jobManager.do 'request', 'response', job, (error, jobResponse) =>
      if error?.code == 404 # backwards compatibility with meshblu
        error.message = 'Devices not found'
      return res.status(error.code ? 500).send(error.message) if error?
      _.each jobResponse.metadata, (value, key) => res.set "x-meshblu-#{key}", value
      data = JSON.parse jobResponse.rawData
      res.status(jobResponse.metadata.code).send devices: [data]

module.exports = DeviceV1Controller
