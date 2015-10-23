uuid = require 'uuid'
redis = require 'redis'

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

    job =
      uuid:  id
      token: token
      responseUuid: @uuid.v1()

    client.lpush "#{@namespace}:request:queue", JSON.stringify job
    @listenForResponse client, job.responseUuid, callback

  listenForResponse: (client, responseUuid, callback) =>
    client.brpop "#{@namespace}:response:#{responseUuid}", @timeoutSeconds, (error, result) =>
      return callback error if error?
      return callback new Error('No response from authenticate worker') unless result?

      [queueName,meshbluResult] = result
      [errorObj,response] = JSON.parse meshbluResult

      return callback new Error(errorObj.message) if errorObj?
      callback null, response.authenticated

module.exports = Authenticator
