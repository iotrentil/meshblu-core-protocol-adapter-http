debug = require('debug')('meshblu-server-http:messages-controller')
_     = require 'lodash'
JobToHttp = require '../helpers/job-to-http'
MeshbluAuthParser = require '../helpers/meshblu-auth-parser'

class MessagesController
  constructor: ({@jobManager}) ->
    @authParser = new MeshbluAuthParser

  create: (req, res) =>
    auth = @authParser.parse req
    job = JobToHttp.requestToJob jobType: 'GetDevice', request: req, toUuid: auth.uuid

    @jobManager.do 'request', 'response', job, (error, response) =>
      return res.status(error.code ? 500).send(error.message) if error?
      res.status(response.metadata.code).end()

module.exports = MessagesController
