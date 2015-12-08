{Pool} = require 'generic-pool'

class ConnectionPool
  constructor: (options) ->
    @pool = Pool options

  acquire: (request,response,next) =>
    @pool.acquire (error, client) =>
      request.connection = client
      response.on 'finish', =>
        @pool.release client
      next()

  gateway: (request,response,next) =>
    return response.status(502).send("Connection Pool error") unless request.connection?
    next()

  getInfo: =>
    name: @pool.getName()
    poolSize: @pool.getPoolSize()
    availableObjectsCount: @pool.availableObjectsCount()
    waitingClientsCount: @pool.waitingClientsCount()
    maxPoolSize: @pool.getMaxPoolSize()

module.exports = ConnectionPool
