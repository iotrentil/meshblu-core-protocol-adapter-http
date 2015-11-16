_          = require 'lodash'
uuid       = require 'uuid'
async      = require 'async'
JobManager = require 'meshblu-core-job-manager'

class AuthenticatorError extends Error
  name: 'AuthenticatorError'
  constructor: (@code, @status) ->
    @message = "#{@code}: #{@status}"

class Authenticator
  constructor: (options={}, dependencies={}) ->
    {client,timeoutSeconds} = options

    timeoutSeconds ?= 30
    timeoutSeconds = 1 if timeoutSeconds < 1

    @jobManager = new JobManager
      client: client
      timeoutSeconds: timeoutSeconds

    {@uuid} = dependencies
    @uuid ?= uuid

  authenticate: (id, token, callback) ->
    responseId = @uuid.v1()

    metadata =
      auth:
        uuid:  id
        token: token
      jobType: 'Authenticate'
      responseId: responseId

    options =
      responseId: responseId
      metadata: metadata

    @jobManager.createRequest 'request', options, (error) =>
      return callback error if error?

      @listenForResponse metadata.responseId, callback

  listenForResponse: (responseId, callback) =>
    @jobManager.getResponse 'response', responseId, (error, response) =>
      return callback error if error?
      return callback new Error('No response from authenticate worker') unless response?

      {metadata} = response

      callback null, metadata: _.pick(metadata, 'code', 'status')

module.exports = Authenticator
