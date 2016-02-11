debug     = require('debug')('meshblu-server-http:subscription-controller')
_         = require 'lodash'
JobToHttp = require '../helpers/job-to-http'

class SubscriptionsController
  constructor: ({@jobManager, @jobToHttp}) ->

  list: (req, res) =>
    job = @jobToHttp.httpToJob jobType: 'SubscriptionList', request: req, toUuid: req.params.uuid

    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.status(error.code ? 500).send(error.message) if error?
      return res.sendStatus(500) unless jobResponse?

      _.each jobResponse.metadata, (value, key) => res.set "x-meshblu-#{_.kebabCase(key)}", value
      return res.sendStatus jobResponse.metadata.code unless jobResponse.rawData?
      subscriptions = _.map JSON.parse(jobResponse.rawData), (subscription) =>
        uuid: subscription.emitterUuid
        type: subscription.type
        
      res.status(200).send(subscriptions)


module.exports = SubscriptionsController
