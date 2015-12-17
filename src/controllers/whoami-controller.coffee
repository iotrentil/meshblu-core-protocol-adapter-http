JobManager = require 'meshblu-core-job-manager'
MeshbluAuthParser = require '../helpers/meshblu-auth-parser'
debug = require('debug')('meshblu-server-http:whoami-controller')
_ = require 'lodash'

class WhoamiController
  constructor: ({@timeoutSeconds}) ->
    @authParser = new MeshbluAuthParser

  show: (req, res) =>
    jobManager = new JobManager
      client: req.connection
      timeoutSeconds: @timeoutSeconds

    auth = @authParser.parse req

    job =
      metadata:
        auth: auth
        fromUuid: req.get('x-as')  ? auth.uuid
        toUuid: req.get('x-as') ? auth.uuid
        jobType: 'GetDevice'

    debug('dispatching request', job)
    jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.status(error.code ? 500).send(error.message) if error?

      _.each jobResponse.metadata, (value, key) => res.set "x-meshblu-#{key}", value
      res.status(jobResponse.metadata.code).send JSON.parse(jobResponse.rawData)

module.exports = WhoamiController
