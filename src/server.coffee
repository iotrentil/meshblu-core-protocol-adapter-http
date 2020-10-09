_                       = require 'lodash'
colors                  = require 'colors'
Redis                   = require 'ioredis'
Express                 = require 'express'
octobluExpress          = require 'express-octoblu'
RedisNS                 = require '@octoblu/redis-ns'
RateLimitChecker        = require 'meshblu-core-rate-limit-checker'
JobLogger               = require 'job-logger'
debug                   = require('debug')('meshblu-core-protocol-adapter-http:server')
{ JobManagerRequester } = require 'meshblu-core-job-manager'
enableDestroy           = require 'server-destroy'

Router                  = require './router'
JobToHttp               = require './helpers/job-to-http'
MeshbluAuthParser       = require './helpers/meshblu-auth-parser'

class Server
  constructor: (options)->
    {
      @disableLogging
      @port
      @aliasServerUri
      @redisUri
      @cacheRedisUri
      @namespace
      @maxConnections
      @jobTimeoutSeconds
      @jobLogSampleRate
      @jobLogSampleRateOverrideUuids
      @jobLogRedisUri
      @jobLogQueue
      @requestQueueName
      @responseQueueName
    } = options
    @panic 'missing @jobLogQueue', 2 unless @jobLogQueue?
    @panic 'missing @jobLogRedisUri', 2 unless @jobLogRedisUri?
    @panic 'missing @redisUri', 2 unless @redisUri?
    @panic 'missing @cacheRedisUri', 2 unless @cacheRedisUri?
    @panic 'missing @jobLogSampleRate', 2 unless @jobLogSampleRate?
    @panic 'missing @requestQueueName', 2 if _.isEmpty @requestQueueName
    @panic 'missing @responseQueueName', 2 if _.isEmpty @responseQueueName

    @cacheClient = new Redis @cacheRedisUri, dropBufferSupport: true
    rateLimitCheckerClient = new RedisNS 'meshblu-count', @cacheClient
    @rateLimitChecker = new RateLimitChecker {
      client: rateLimitCheckerClient
      msgRateLimit: 100 * 60
    }
    @authParser = new MeshbluAuthParser

  address: =>
    @server.address()

  panic: (message, exitCode, error) =>
    error ?= new Error('generic error')
    console.error colors.red message
    console.error error?.stack
    process.exit exitCode

  run: (callback) =>
    app = octobluExpress({ @disableLogging, bodyLimit: '10mb' })
    app.use(Express.static('public'))

    app.use '/proofoflife', (req, res) =>
      @jobManager.healthcheck (error, healthy) =>
        return res.sendError error if error?
        return res.sendError new Error("Job Manager Unhealthy") unless healthy
        @cacheClient.set 'test:write', Date.now(), (error) =>
          return res.sendError error if error?
          res.send online: true

    rateLimit = (req, res, next) =>
      as = req.get 'x-meshblu-as'
      auth = @authParser.parse req
      uuid = as ? auth?.uuid
      return next() unless uuid?
      @rateLimitChecker.isLimited {uuid}, (error, result) =>
        return res.sendError error if error?
        return res.status(429).send(message: 'Too Many Requests') if result
        next()
    app.use rateLimit

    jobLogger = new JobLogger
      client: new Redis @jobLogRedisUri, dropBufferSupport: true
      indexPrefix: 'metric:meshblu-core-protocol-adapter-http'
      type: 'meshblu-core-protocol-adapter-http:request'
      jobLogQueue: @jobLogQueue

    @jobManager = new JobManagerRequester {
      @namespace
      @redisUri
      @jobTimeoutSeconds
      @jobLogSampleRate
      @jobLogSampleRateOverrideUuids
      @requestQueueName
      @responseQueueName
      queueTimeoutSeconds: @jobTimeoutSeconds
      maxConnections: 2
    }

    @jobManager.once 'error', (error) =>
      @stop =>
        @panic 'fatal job manager error', 1, error

    @jobManager.once 'factoryCreateError', (error) =>
      @stop =>
        @panic 'fatal job manager factoryCreateError', 1, error

    @jobManager._do = @jobManager.do
    @jobManager.do = (request, callback) =>
      @jobManager._do request, (error, response) =>
        jobLogger.log { error, request, response }, (jobLoggerError) =>
          return callback jobLoggerError if jobLoggerError?
          callback error, response

    @jobManager.start (error) =>
      return callback error if error?

      jobToHttp = new JobToHttp
      router = new Router { @jobManager, jobToHttp }
      router.route app

      @server = app.listen @port, (error) =>
        return callback error if error?
        debug 'meshblu-http listening on port', @port
        callback null
      enableDestroy @server

  destroy: (callback) =>
    @server.destroy =>
      @jobManager.stop callback

  stop: (callback) =>
    @server.close =>
      @jobManager.stop callback

module.exports = Server
