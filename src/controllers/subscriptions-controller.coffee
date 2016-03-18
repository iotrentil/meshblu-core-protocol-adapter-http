debug     = require('debug')('meshblu-server-http:subscription-controller')
_         = require 'lodash'
JobToHttp = require '../helpers/job-to-http'

class SubscriptionsController
  constructor: ({@jobManager, @jobToHttp}) ->

  list: (req, res) =>
    job = @jobToHttp.httpToJob jobType: 'SubscriptionList', request: req, toUuid: req.params.uuid

    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.sendError error if error?
      return res.sendError new Error('Did not receive jobResponse') unless jobResponse?

      _.each jobResponse.metadata, (value, key) => res.set "x-meshblu-#{_.kebabCase(key)}", value
      return res.sendStatus jobResponse.metadata.code unless jobResponse.rawData?
      subscriptions = _.map JSON.parse(jobResponse.rawData), (subscription) =>
        uuid: subscription.emitterUuid
        type: subscription.type

      res.status(200).send(subscriptions)

  create: (req, res) =>
    req.body = _.pick req.params, ['subscriberUuid', 'emitterUuid', 'type']
    job = @jobToHttp.httpToJob jobType: 'CreateSubscription', request: req, toUuid: req.params.emitterUuid

    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.sendError error if error?
      return res.sendError new Error('Did not receive jobResponse') unless jobResponse?
      jobResponse.metadata.code = 204 if jobResponse.metadata.code == 304
      jobResponse.metadata.code = 204 if jobResponse.metadata.code == 201
      @jobToHttp.sendJobResponse {jobResponse, res}

  remove: (req, res) =>
    req.body = _.pick req.params, ['subscriberUuid', 'emitterUuid', 'type']
    job = @jobToHttp.httpToJob jobType: 'RemoveSubscription', request: req, toUuid: req.params.emitterUuid

    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.sendError error if error?
      return res.sendError new Error('Did not receive jobResponse') unless jobResponse?
      @jobToHttp.sendJobResponse {jobResponse, res}

module.exports = SubscriptionsController
