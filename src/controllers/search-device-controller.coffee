debug = require('debug')('meshblu-server-http:search-device-controller')
_     = require 'lodash'
JobToHttp = require '../helpers/job-to-http'

class SearchDeviceController
  constructor: ({@jobManager}) ->

  search: (req, res) =>
    job = JobToHttp.requestToJob jobType: 'SearchDevices', request: req

    debug('dispatching request', job)
    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.status(error.code ? 500).send(error.message) if error?
      _.each jobResponse.metadata, (value, key) => res.set "x-meshblu-#{key}", value
      res.status(jobResponse.metadata.code).send JSON.parse(jobResponse.rawData)

module.exports = SearchDeviceController
