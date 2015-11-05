bodyParser         = require 'body-parser'
errorHandler       = require 'errorhandler'
express            = require 'express'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
morgan             = require 'morgan'
redis              = require 'redis'
RedisNS            = require '@octoblu/redis-ns'
ConnectionPool     = require './src/models/connection-pool'

AuthenticateController  = require './src/controllers/authenticate-controller'
MessagesController      = require './src/controllers/messages-controller'
SubscriptionsController = require './src/controllers/subscriptions-controller'

authenticateController  = new AuthenticateController
messagesController      = new MessagesController
subscriptionsController = new SubscriptionsController timeoutSeconds: process.env.JOB_TIMEOUT_SECONDS

PORT  = process.env.PORT ? 80

connectionPool = new ConnectionPool
  max: 100
  min: 2
  create: (callback) =>
    client = new RedisNS('meshblu', redis.createClient(process.env.REDIS_URI))
    uuid = require 'uuid'
    client.secretId = uuid.v4()
    callback null, client
  destroy: (client) =>
    client.quit()

app = express()
app.use morgan('combined', immediate: false)
app.use bodyParser.json({limit: '50mb'})
app.use errorHandler()
app.use meshbluHealthcheck()
app.use connectionPool.acquire
app.use connectionPool.gateway

app.post '/authenticate', authenticateController.authenticate
app.post '/messages', messagesController.create
app.get '/devices/:uuid/subscriptions', subscriptionsController.getAll

server = app.listen PORT, ->
  host = server.address().address
  port = server.address().port

  console.log "Server running on #{host}:#{port}"
