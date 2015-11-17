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

PORT      = process.env.PORT ? 80
NAMESPACE = process.env.NAMESPACE ? 'meshblu'
JOB_TIMEOUT_SECONDS = process.env.JOB_TIMEOUT_SECONDS ? 30

authenticateController  = new AuthenticateController timeoutSeconds: JOB_TIMEOUT_SECONDS
subscriptionsController = new SubscriptionsController timeoutSeconds: JOB_TIMEOUT_SECONDS
messagesController = new MessagesController client: new RedisNS(NAMESPACE, redis.createClient(process.env.REDIS_URI))


connectionPool = new ConnectionPool
  max: 100
  min: 2
  create: (callback) =>
    callback null, new RedisNS(NAMESPACE, redis.createClient(process.env.REDIS_URI))
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
