MeshbluAuthParser = require '../helpers/meshblu-auth-parser'
debug = require('debug')('meshblu-server-http:subscription-controller')
_     = require 'lodash'

class SubscriptionsController
  constructor: ({@jobManager}) ->
    @authParser = new MeshbluAuthParser

  list: (req, res) =>
    auth = @authParser.parse req

    options =
      metadata:
        auth: auth
        fromUuid: req.get('x-meshblu-as') ? auth.uuid
        toUuid: req.params.uuid
        jobType: 'SubscriptionList'

    @jobManager.do 'request', 'response', options, (error, jobResponse) =>
      return res.status(error.code ? 500).send(error.message) if error?
      _.each jobResponse.metadata, (value, key) => res.set "x-meshblu-#{key}", value
      res.status(jobResponse.metadata.code).send JSON.parse(jobResponse.rawData)

module.exports = SubscriptionsController
