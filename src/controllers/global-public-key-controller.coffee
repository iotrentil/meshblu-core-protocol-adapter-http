debug = require('debug')('meshblu-server-http:global-public-key-controller')

class GlobalPublicKeyController
  constructor: ({@jobManager, @jobToHttp}) ->

  get: (req, res) =>
    job = @jobToHttp.httpToJob
      request: req
      jobType: 'GetGlobalPublicKey'

    debug('dispatching request', job)
    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.sendError error if error?
      @jobToHttp.sendJobResponse {jobResponse, res}

module.exports = GlobalPublicKeyController
