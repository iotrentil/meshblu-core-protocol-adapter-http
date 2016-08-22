debug = require('debug')('meshblu-core-protocol-adapter-http:search-token-controller')
_     = require 'lodash'
JobToHttp = require '../helpers/job-to-http'

class SearchTokenController
  constructor: ({@jobManager, @jobToHttp}) ->

  search: (req, res) =>
    job = @jobToHttp.httpToJob jobType: 'SearchTokens', request: req
    if job.metadata.projection?
      try
        job.metadata.projection = JSON.parse job.metadata.projection
      catch error

    debug('dispatching request', job)
    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.sendError error if error?
      @jobToHttp.sendJobResponse {jobResponse, res}

module.exports = SearchTokenController
