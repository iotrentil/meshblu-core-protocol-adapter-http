JobManager = require 'meshblu-core-job-manager'
MeshbluAuthParser = require '../helpers/meshblu-auth-parser'
debug = require('debug')('meshblu-server-http:get-device-controller')
_     = require 'lodash'
class GetDeviceController
  constructor: ({@timeoutSeconds}) ->
    @authParser = new MeshbluAuthParser

  get: (req, res) =>
    jobManager = new JobManager
      client: req.connection
      timeoutSeconds: @timeoutSeconds

    auth = @authParser.parse req

    options =
      metadata:
        auth: auth
        fromUuid: req.get('x-as') ? auth.uuid
        toUuid: req.params.uuid
        jobType: 'GetDevice'

    debug('dispatching request', options)
    jobManager.do 'request', 'response', options, (error, jobResponse) =>
      return res.status(error.code ? 500).send(error.message) if error?
      _.each jobResponse.metadata, (value, key) => res.set "x-meshblu-#{key}", value
      res.status(jobResponse.metadata.code).send JSON.parse(jobResponse.rawData)

module.exports = GetDeviceController
