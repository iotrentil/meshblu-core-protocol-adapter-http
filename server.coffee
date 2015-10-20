express            = require 'express'
bodyParser         = require 'body-parser'
errorHandler       = require 'errorhandler'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
morgan             = require 'morgan'
MessagesController = require './src/controllers/messages-controller'

messagesController = new MessagesController

PORT  = process.env.PORT ? 80

app = express()
app.use morgan('combined', immediate: false)
app.use bodyParser.json({limit: '50mb'})
app.use errorHandler()
app.use meshbluHealthcheck()

app.post '/messages', messagesController.create

server = app.listen PORT, ->
  host = server.address().address
  port = server.address().port

  console.log "Server running on #{host}:#{port}"
