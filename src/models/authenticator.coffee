uuid = require 'uuid'
redis = require 'redis'

class AuthenticatorError extends Error
  name: 'AuthenticatorError'
  constructor: (@code, @status) ->
    @message = "#{@code}: #{@status}"

class Authenticator
  constructor: (options={}, dependencies={}) ->
    {@namespace,@timeoutSeconds} = options
    @namespace ?= 'meshblu'
    @timeoutSeconds ?= 30
    @timeoutSeconds = 1 if @timeoutSeconds < 1

    {@uuid} = dependencies
    @uuid ?= uuid

  authenticate: (id, token, callback) ->
    client = redis.createClient
      host: process.env.REDIS_HOST
      port: process.env.REDIS_PORT

    metadata =
      uuid:  id
      token: token
      jobType: 'authenticate'
      responseId: @uuid.v1()

    requestStr = JSON.stringify [metadata]

    client.lpush "#{@namespace}:request:queue", requestStr, (error) =>
      return callback error if error?
      @listenForResponse client, metadata.responseId, callback

  listenForResponse: (client, responseId, callback) =>
    client.brpop "#{@namespace}:response:#{responseId}", @timeoutSeconds, (error, result) =>
      return callback error if error?
      return callback new Error('No response from authenticate worker') unless result?

      [queueName,meshbluResult] = result
      [metadata,response] = JSON.parse meshbluResult

      return callback new AuthenticatorError(metadata.code, metadata.status) if metadata.code > 299
      callback null, response.authenticated

module.exports = Authenticator
