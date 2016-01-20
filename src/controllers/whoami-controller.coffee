debug = require('debug')('meshblu-server-http:whoami-controller')
_ = require 'lodash'
JobToHttp = require '../helpers/job-to-http'
MeshbluAuthParser = require '../helpers/meshblu-auth-parser'

class WhoamiController
  constructor: ({@jobManager}) ->
    @authParser = new MeshbluAuthParser

  show: (req, res) =>
    auth = @authParser.parse req
    job = JobToHttp.requestToJob jobType: 'GetDevice', request: req, toUuid: auth.uuid

    debug('dispatching request', job)
    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.status(error.code ? 500).send(error.message) if error?
      _.each jobResponse.metadata, (value, key) => res.set "x-meshblu-#{key}", value
      res.status(jobResponse.metadata.code).send JSON.parse(jobResponse.rawData)

module.exports = WhoamiController
