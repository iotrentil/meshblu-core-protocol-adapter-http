_             = require 'lodash'
Server        = require './src/server'

class Command
  constructor: ->
    @serverOptions =
      port:                         process.env.PORT || 80
      redisUri:                     process.env.REDIS_URI
      namespace:                    process.env.NAMESPACE || 'meshblu'
      jobTimeoutSeconds:            process.env.JOB_TIMEOUT_SECONDS || 30
      connectionPoolMaxConnections: process.env.CONNECTION_POOL_MAX_CONNECTIONS || 100
      disableLogging:               process.env.DISABLE_LOGGING == "true"

  panic: (error) =>
    console.error error.stack
    process.exit 1

  run: =>
    server = new Server @serverOptions
    server.run (error) =>
      return @panic error if error?

      {address,port} = server.address()
      console.log "Server listening on #{address}:#{port}"

command = new Command()
command.run()
