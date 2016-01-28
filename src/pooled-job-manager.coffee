JobManager = require 'meshblu-core-job-manager'
debug = require('debug')('meshblu-server-http:pooled-job-manager')
Benchmark = require 'simple-benchmark'
colors = require 'colors'

class PooledJobManager
  constructor: ({@pool,@timeoutSeconds,@jobLogger}) ->
    @panic 'PooledJobManager needs a jobLogger', 1 unless @jobLogger?

  poolStats: =>
    name: @pool.getName()
    poolSize: @pool.getPoolSize()
    availableObjects: @pool.availableObjectsCount()
    waitingClients: @pool.waitingClientsCount()
    max: @pool.getMaxPoolSize()
    min: @pool.getMinPoolSize()

  do: (requestQueue, responseQueue, request, callback) =>
    benchmark = new Benchmark label: 'pooled-job-manager'
    debug 'Stats:', JSON.stringify @poolStats()
    @pool.acquire (error, client) =>
      debug '@pool.acquire', benchmark.toString()
      return callback error if error?

      jobManager = new JobManager client: client, timeoutSeconds: @timeoutSeconds
      jobManager.do requestQueue, responseQueue, request, (error, response) =>
        @pool.release client
        debug '@pool.release', benchmark.toString()

        @jobLogger.log {error,request,response,elapsedTime:benchmark.elapsed()}, (error) =>
          return @panic 'Failed to log job', 6, error if error?
          callback error, response

  panic: (message, exitCode, error) =>
    console.error colors.red message
    console.error error?.stack
    process.exit exitCode

module.exports = PooledJobManager
