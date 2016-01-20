debug = require('debug')('meshblu-server-http:search-device-controller')
_     = require 'lodash'
JobToHttp = require '../helpers/job-to-http'

class SearchDeviceController
  constructor: ({@jobManager, @jobToHttp}) ->

  search: (req, res) =>
    job = @jobToHttp.httpToJob jobType: 'SearchDevices', request: req

    debug('dispatching request', job)
    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      @jobToHttp.sendJobResponse {jobResponse, res}


module.exports = SearchDeviceController
