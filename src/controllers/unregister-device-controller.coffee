JobToHttp = require '../helpers/job-to-http'
debug     = require('debug')('meshblu-server-http:unregister-device-controller')
_         = require 'lodash'

class UnregisterDeviceController
  constructor: ({@jobManager, @jobToHttp}) ->

  unregister: (req, res) =>
    {uuid} = req.params
    job = @jobToHttp.httpToJob jobType: 'UnregisterDevice', request: req, toUuid: uuid

    debug('dispatching request', job)
    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.sendError error if error?
      {code} = jobResponse.metadata
      code = 200 if code == 204
      res.status(code).send({uuid: uuid})

module.exports = UnregisterDeviceController
