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
    return response.status(502).end() unless request.connection?
    next()

module.exports = ConnectionPool
