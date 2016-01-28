_                  = require 'lodash'
colors             = require 'colors'
morgan             = require 'morgan'
express            = require 'express'
bodyParser         = require 'body-parser'
cors               = require 'cors'
errorHandler       = require 'errorhandler'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
redis              = require 'redis'
RedisNS            = require '@octoblu/redis-ns'
debug              = require('debug')('meshblu-server-http:server')
Router             = require './router'
{Pool}             = require 'generic-pool'
PooledJobManager   = require './pooled-job-manager'
JobLogger          = require 'job-logger'
JobToHttp          = require './helpers/job-to-http'
PackageJSON        = require '../package.json'

class Server
  constructor: (options)->
    {@disableLogging, @port} = options
    {@connectionPoolMaxConnections, @redisUri, @namespace, @jobTimeoutSeconds} = options
    {@jobLogRedisUri, @jobLogQueue} = options
    @panic 'missing @jobLogQueue', 2 unless @jobLogQueue?

  address: =>
    @server.address()

  panic: (message, exitCode, error) =>
    error ?= new Error('generic error')
    console.error colors.red message
    console.error error?.stack
    process.exit exitCode

  run: (callback) =>
    app = express()
    app.use morgan 'dev', immediate: false unless @disableLogging
    app.use errorHandler()
    app.use meshbluHealthcheck()
    app.use cors()
    app.use bodyParser.urlencoded limit: '50mb', extended : true
    app.use bodyParser.json limit : '50mb'

    jobLogger = new JobLogger
      jobLogQueue: @jobLogQueue
      indexPrefix: 'meshblu_http'
      type: 'meshblu-server-http'
      client: redis.createClient(@jobLogRedisUri)

    connectionPool = @_createConnectionPool()
    jobManager = new PooledJobManager
      timeoutSeconds: @jobTimeoutSeconds
      pool: connectionPool
      jobLogger: jobLogger

    jobToHttp = new JobToHttp
    router = new Router {jobManager, jobToHttp}

    router.route app

    @server = app.listen @port, callback

  stop: (callback) =>
    @server.close callback

  _createConnectionPool: =>
    connectionPool = new Pool
      max: @connectionPoolMaxConnections
      min: 0
      returnToHead: true # sets connection pool to stack instead of queue behavior
      create: (callback) =>
        client = _.bindAll new RedisNS @namespace, redis.createClient(@redisUri)

        client.on 'end', ->
          client.hasError = new Error 'ended'

        client.on 'error', (error) ->
          client.hasError = error
          callback error if callback?

        client.once 'ready', ->
          callback null, client
          callback = null

      destroy: (client) => client.end true
      validate: (client) => !client.hasError?

    return connectionPool

module.exports = Server
