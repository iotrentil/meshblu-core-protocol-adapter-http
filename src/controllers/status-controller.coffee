debug = require('debug')('meshblu-core-protocol-adapter-http:get-status-controller')
_     = require 'lodash'

class StatusController
  constructor: ({@jobManager}) ->

  get: (req, res) =>
    options =
      metadata:
        jobType: 'GetStatus'

    @jobManager.do 'request', 'response', options, (error, jobResponse) =>
      return res.sendError error if error?
      _.each jobResponse.metadata, (value, key) => res.set "x-meshblu-#{key}", value
      res.status(jobResponse.metadata.code).send(JSON.parse jobResponse.rawData)

module.exports = StatusController
