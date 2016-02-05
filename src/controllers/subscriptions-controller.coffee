debug     = require('debug')('meshblu-server-http:subscription-controller')
_         = require 'lodash'
JobToHttp = require '../helpers/job-to-http'

class SubscriptionsController
  constructor: ({@jobManager, @jobToHttp}) ->

  list: (req, res) =>
    job = @jobToHttp.httpToJob jobType: 'SubscriptionList', request: req, toUuid: req.params.uuid

    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.status(error.code ? 500).send(error.message) if error?
      @jobToHttp.sendJobResponse {jobResponse, res}

module.exports = SubscriptionsController
