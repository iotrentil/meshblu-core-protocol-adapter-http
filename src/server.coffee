_                     = require 'lodash'
colors                = require 'colors'
redis                 = require 'ioredis'
octobluExpress        = require 'express-octoblu'
RedisNS               = require '@octoblu/redis-ns'
RateLimitChecker      = require 'meshblu-core-rate-limit-checker'
RedisPooledJobManager = require 'meshblu-core-redis-pooled-job-manager'
debug                 = require('debug')('meshblu-core-protocol-adapter-http:server')

Router                = require './router'
JobToHttp             = require './helpers/job-to-http'
MeshbluAuthParser     = require './helpers/meshblu-auth-parser'

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
      @jobLogRedisUri
      @jobLogQueue
    } = options
    @panic 'missing @jobLogQueue', 2 unless @jobLogQueue?
    @panic 'missing @jobLogRedisUri', 2 unless @jobLogRedisUri?
    @panic 'missing @jobLogSampleRate', 2 unless @jobLogSampleRate?

    cacheClient = redis.createClient @cacheRedisUri, dropBufferSupport: true
    rateLimitCheckerClient = new RedisNS 'meshblu-count', cacheClient
    @rateLimitChecker = new RateLimitChecker client: rateLimitCheckerClient
    @authParser = new MeshbluAuthParser

  address: =>
    @server.address()

  panic: (message, exitCode, error) =>
    error ?= new Error('generic error')
    console.error colors.red message
    console.error error?.stack
    process.exit exitCode

  run: (callback) =>
    app = octobluExpress({ @disableLogging })

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

    jobManager = new RedisPooledJobManager {
      jobLogIndexPrefix: 'metric:meshblu-core-protocol-adapter-http'
      jobLogType: 'meshblu-core-protocol-adapter-http:request'
      idleTimeoutMillis: 5*60*1000
      minConnections: 5
      @jobTimeoutSeconds
      @jobLogQueue
      @jobLogRedisUri
      @jobLogSampleRate
      @maxConnections
      @redisUri
      @namespace
    }

    jobToHttp = new JobToHttp

    router = new Router {jobManager, jobToHttp}

    router.route app

    @server = app.listen @port, callback

  stop: (callback) =>
    @server.close callback

module.exports = Server
