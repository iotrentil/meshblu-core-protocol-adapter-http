debug = require('debug')('meshblu-server-http:search-device-controller')
_     = require 'lodash'
JobToHttp = require '../helpers/job-to-http'

class SearchDeviceController
  constructor: ({@jobManager, @jobToHttp}) ->

  mydevices: (req, res) =>
    job = @_oldFormatToJob req
    job.data.owner = job.metadata.fromUuid

    debug('dispatching request mydevices', job)
    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.sendError error if error?
      res.status(jobResponse.metadata.code).send devices: JSON.parse jobResponse.rawData

  searchV1: (req, res) =>
    job = @_oldFormatToJob req

    debug('dispatching request v1', job)
    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.sendError error if error?
      res.status(jobResponse.metadata.code).send devices: JSON.parse jobResponse.rawData

  searchV2: (req, res) =>
    job = @_oldFormatToJob req

    debug('dispatching request v2', job)
    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.sendError error if error?
      @jobToHttp.sendJobResponse {jobResponse, res}

  searchV3: (req, res) =>
    job = @jobToHttp.httpToJob jobType: 'SearchDevices', request: req

    debug('dispatching request v3', job)
    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.sendError error if error?
      @jobToHttp.sendJobResponse {jobResponse, res}

  _oldFormatToJob: (req) =>
    req.body = _.extend {}, req.body, req.query
    job = @jobToHttp.httpToJob jobType: 'SearchDevices', request: req
    {uuid, token} = req.body

    if req.body.online?
      req.body.online = req.body.online == 'true'

    _.each req.body, (value, key) =>
      if value == 'null' || value == ''
        req.body[key] = $exists: false

    if uuid? and token?
      job.metadata.auth = {uuid, token}
      delete job.data.token
    return job

module.exports = SearchDeviceController
