MeshbluAuthParser = require '../helpers/meshblu-auth-parser'
debug = require('debug')('meshblu-server-http:token-controller')
_     = require 'lodash'
JobToHttp = require '../helpers/job-to-http'

class TokenController
  constructor: ({@jobManager, @jobToHttp}) ->

  create: (req, res) =>
    job = @jobToHttp.httpToJob
      jobType: 'CreateSessionToken'
      request: req
      toUuid: req.params.uuid
      data: req.body

    debug('dispatching request', job)
    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.sendError error if error?
      @jobToHttp.sendJobResponse {jobResponse, res}

  destroy: (req, res) =>
    job = @jobToHttp.httpToJob
      jobType: 'RevokeSessionToken'
      request: req
      toUuid: req.params.uuid
      data:
        token: req.params.token
        
    debug('dispatching request', job)
    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.sendError error if error?
      @jobToHttp.sendJobResponse {jobResponse, res}

  revokeByQuery: (req, res) =>
    job = @jobToHttp.httpToJob
      jobType: 'RevokeTokenByQuery'
      request: req
      toUuid: req.params.uuid
      data: req.query

    debug('dispatching request', job)
    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.sendError error if error?
      @jobToHttp.sendJobResponse {jobResponse, res}

  resetToken: (req, res) =>
    job = @jobToHttp.httpToJob
      jobType: 'ResetToken'
      request: req
      toUuid: req.params.uuid

    debug('dispatching request', job)
    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.sendError error if error?
      @jobToHttp.sendJobResponse {jobResponse, res}

module.exports = TokenController
