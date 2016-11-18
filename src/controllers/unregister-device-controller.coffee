JobToHttp = require '../helpers/job-to-http'
debug     = require('debug')('meshblu-core-protocol-adapter-http:unregister-device-controller')
_         = require 'lodash'

class UnregisterDeviceController
  constructor: ({@jobManager, @jobToHttp}) ->

  unregister: (req, res) =>
    {uuid} = req.params
    job = @jobToHttp.httpToJob jobType: 'UnregisterDevice', request: req, toUuid: uuid

    debug('dispatching request', job)
    @jobManager.do job, (error, jobResponse) =>
      return res.sendError error if error?
      if jobResponse.metadata.code == 204
        jobResponse.metadata.code = 200
        jobResponse.rawData = JSON.stringify {uuid}
      @jobToHttp.sendJobResponse {jobResponse, res}

module.exports = UnregisterDeviceController
