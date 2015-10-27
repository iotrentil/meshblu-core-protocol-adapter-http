_ = require 'lodash'
uuid = require 'uuid'
async = require 'async'
RedisJob = require './redis-job'

class AuthenticatorError extends Error
  name: 'AuthenticatorError'
  constructor: (@code, @status) ->
    @message = "#{@code}: #{@status}"

class Authenticator
  constructor: (options={}, dependencies={}) ->
    {client,@namespace,@timeoutSeconds} = options
    @namespace ?= 'meshblu'
    @client = _.bindAll client
    @timeoutSeconds ?= 30
    @timeoutSeconds = 1 if @timeoutSeconds < 1
    @redisJob = new RedisJob namespace: @namespace, client: @client

    {@uuid} = dependencies
    @uuid ?= uuid

  authenticate: (id, token, callback) ->
    responseId = @uuid.v1()

    metadata =
      uuid:  id
      token: token
      jobType: 'authenticate'
      responseId: responseId

    @redisJob.createRequest responseId: responseId, metadata: metadata, (error) =>
      return callback error if error?
      @listenForResponse metadata.responseId, callback

  listenForResponse: (responseId, callback) =>
    @client.brpop "#{@namespace}:response:#{responseId}", @timeoutSeconds, (error, result) =>
      return callback error if error?
      return callback new Error('No response from authenticate worker') unless result?

      [channel,key] = result

      async.parallel
        metadata: async.apply @client.hget, key, 'response:metadata'
        data: async.apply @client.hget, key, 'response:data'
      , (error, result) =>
        metadata = JSON.parse result.metadata
        data     = JSON.parse result.data

        return callback new AuthenticatorError(metadata.code, metadata.status) if metadata.code > 299
        callback null, data.authenticated

module.exports = Authenticator
