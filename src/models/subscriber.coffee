uuid       = require 'uuid'
JobManager = require 'meshblu-core-job-manager'

class Subscriber
  constructor: (options={}, dependencies={}) ->
    {client,timeoutSeconds} = options
    {@uuid} = dependencies

    timeoutSeconds ?= 30
    @jobManager = new JobManager client: client, timeoutSeconds: timeoutSeconds
    @uuid ?= uuid

  getSubscriptions: (options, callback) =>
    responseId = @uuid.v4()

    request =
      metadata:
        auth: options.auth
        fromUuid: options.fromUuid ? options.auth.uuid
        toUuid: options.toUuid
        jobType: 'SubscriptionList'
        responseId: responseId

    @jobManager.createRequest 'request', request, (error) =>
      return callback error if error?
      @_waitForResponse responseId, callback

  _waitForResponse: (responseId, callback) =>
    @jobManager.getResponse 'response', responseId, (error, response) =>
      return callback error if error?
      return callback new Error('Response timeout exceeded') unless response?
      callback null,
        code: response.metadata.code
        status: response.metadata.status
        data: JSON.parse response.rawData


module.exports = Subscriber
