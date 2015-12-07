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
ConnectionPool     = require './helpers/connection-pool'

class Server
  constructor: (options)->
    {@disableLogging, @port} = options
    {@connectionPoolMaxConnections, @redisUri, @namespace, @jobTimeoutSeconds} = options

  address: =>
    @server.address()

  run: (callback) =>
    app = express()
    app.use morgan 'dev', immediate: false unless @disableLogging
    app.use errorHandler()
    app.use meshbluHealthcheck()
    app.use cors()
    app.use bodyParser.urlencoded limit: '50mb', extended : true
    app.use bodyParser.json limit : '50mb'

    connectionPool = @_createConnectionPool()
    app.use connectionPool.acquire
    app.use connectionPool.gateway

    router = new Router timeoutSeconds: @jobTimeoutSeconds

    router.route app

    @server = app.listen @port, callback

  stop: (callback) =>
    @server.close callback

  _createConnectionPool: =>
    connectionPool = new ConnectionPool
      max: @connectionPoolMaxConnections
      min: 0
      returnToHead: true # sets connection pool to stack instead of queue behavior
      create: (callback) =>
        callback null, new RedisNS @namespace, redis.createClient(@redisUri)
      destroy: (client) =>
        client.end true
    setInterval (=> debug 'connectionPool', JSON.stringify(connectionPool.getInfo())), 30000
    return connectionPool

module.exports = Server
