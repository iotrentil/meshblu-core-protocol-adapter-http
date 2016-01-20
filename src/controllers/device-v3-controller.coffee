JobToHttp = require '../helpers/job-to-http'
debug = require('debug')('meshblu-server-http:get-device-controller')
_     = require 'lodash'

class DeviceV3Controller
  constructor: ({@jobManager, @jobToHttp}) ->

  get: (req, res) =>
    job = @jobToHttp.httpToJob jobType: 'GetDevice', request: req, toUuid: req.params.uuid

    debug('dispatching request', job)
    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      @jobToHttp.sendJobResponse {jobResponse, res}

module.exports = DeviceV3Controller
