debug = require('debug')('meshblu-core-protocol-adapter-http:global-public-key-controller')

class GlobalPublicKeyController
  constructor: ({@jobManager, @jobToHttp}) ->

  get: (req, res) =>
    job = @jobToHttp.httpToJob
      request: req
      jobType: 'GetGlobalPublicKey'

    debug('dispatching request', job)
    @jobManager.do job, (error, jobResponse) =>
      return res.sendError error if error?
      @jobToHttp.sendJobResponse {jobResponse, res}

module.exports = GlobalPublicKeyController
