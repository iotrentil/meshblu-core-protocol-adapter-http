cors                  = require 'cors'
_                     = require 'lodash'
colors                = require 'colors'
morgan                = require 'morgan'
express               = require 'express'
redis                 = require 'ioredis'
bodyParser            = require 'body-parser'
compression           = require 'compression'
OctobluRaven          = require 'octoblu-raven'
RedisNS               = require '@octoblu/redis-ns'
expressVersion        = require 'express-package-version'
meshbluHealthcheck    = require 'express-meshblu-healthcheck'
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
      @namespace
      @maxConnections
      @jobTimeoutSeconds
      @jobLogSampleRate
      @jobLogRedisUri
      @jobLogQueue
      @octobluRaven
    } = options
    @panic 'missing @jobLogQueue', 2 unless @jobLogQueue?
    @panic 'missing @jobLogRedisUri', 2 unless @jobLogRedisUri?
    @panic 'missing @jobLogSampleRate', 2 unless @jobLogSampleRate?
    @octobluRaven ?= new OctobluRaven()
    rateLimitCheckerClient = new RedisNS 'meshblu-count', redis.createClient(@redisUri, dropBufferSupport: true)
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
    app = express()
    @octobluRaven.expressBundle({ app })
    app.use compression()
    app.use expressVersion({format: '{"version": "%s"}'})
    app.use meshbluHealthcheck()
    skip = (request, response) =>
      return response.statusCode < 400
    app.use morgan 'dev', { immediate: false, skip } unless @disableLogging
    app.use cors()
    app.use bodyParser.urlencoded limit: '50mb', extended : true
    app.use bodyParser.json limit : '50mb'

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
