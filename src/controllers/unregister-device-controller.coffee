JobToHttp = require '../helpers/job-to-http'
debug     = require('debug')('meshblu-server-http:unregister-device-controller')
_         = require 'lodash'

class UnregisterDeviceController
  constructor: ({@jobManager, @jobToHttp}) ->

  unregister: (req, res) =>
    job = @jobToHttp.httpToJob jobType: 'UnregisterDevice', request: req, toUuid: req.params.uuid

    debug('dispatching request', job)
    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.sendError error if error?
      res.sendStatus jobResponse.metadata.code

module.exports = UnregisterDeviceController
