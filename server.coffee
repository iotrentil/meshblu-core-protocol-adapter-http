bodyParser         = require 'body-parser'
errorHandler       = require 'errorhandler'
express            = require 'express'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
morgan             = require 'morgan'
AuthenticateController = require './src/controllers/authenticate-controller'
MessagesController     = require './src/controllers/messages-controller'

authenticateController = new AuthenticateController
messagesController     = new MessagesController

PORT  = process.env.PORT ? 80

app = express()
app.use morgan('combined', immediate: false)
app.use bodyParser.json({limit: '50mb'})
app.use errorHandler()
app.use meshbluHealthcheck()

app.post '/authenticate', authenticateController.authenticate
app.post '/messages', messagesController.create

server = app.listen PORT, ->
  host = server.address().address
  port = server.address().port

  console.log "Server running on #{host}:#{port}"
