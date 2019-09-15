JobToHttp = require '../helpers/job-to-http'
debug = require('debug')('meshblu-core-protocol-adapter-http:get-device-controller')
_     = require 'lodash'

class DeviceV2Controller
  constructor: ({@jobManager, @jobToHttp}) ->

  get: (req, res) =>
    job = @jobToHttp.httpToJob jobType: 'GetDevice', request: req, toUuid: req.params.uuid

    debug('dispatching request', job)
    @jobManager.do job, (error, jobResponse) =>
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

      return @jobToHttp.sendJobResponse {res, jobResponse}

  getExport: (req, res) =>
    job = @jobToHttp.httpToJob jobType: 'GetDevice', request: req, toUuid: req.params.uuid

    debug('dispatching request', job)
    @jobManager.do job, (error, jobResponse) =>
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
      device = JSON.parse jobResponse.rawData
      result = _.omit device, ['meshblu', 'schemas']
      jobResponse.rawData = JSON.stringify result
      return @jobToHttp.sendJobResponse {res, jobResponse}

  update: (req, res) =>
    # insert $set first
    unless _.isPlainObject req.body
      return res.status(422).send message: 'Invalid Request'
    body = req.body
    delete body.uuid
    delete body.token
    req.body = $set: body
    job = @jobToHttp.httpToJob jobType: 'UpdateDevice', request: req, toUuid: req.params.uuid

    debug('dispatching request', job)
    @jobManager.do job, (error, jobResponse) =>
      return res.sendError error if error?
      return @jobToHttp.sendJobResponse {res, jobResponse}

  updateDangerously: (req, res) =>
    job = @jobToHttp.httpToJob jobType: 'UpdateDevice', request: req, toUuid: req.params.uuid

    debug('dispatching request', job)
    @jobManager.do job, (error, jobResponse) =>
      return res.sendError error if error?
      return @jobToHttp.sendJobResponse {res, jobResponse}

  findAndUpdate: (req, res) =>
    job = @jobToHttp.httpToJob jobType: 'FindAndUpdateDevice', request: req, toUuid: req.params.uuid

    debug('dispatching request', job)
    @jobManager.do job, (error, jobResponse) =>
      return res.sendError error if error?
      return @jobToHttp.sendJobResponse {res, jobResponse}

module.exports = DeviceV2Controller
