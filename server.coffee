bodyParser         = require 'body-parser'
errorHandler       = require 'errorhandler'
express            = require 'express'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
morgan             = require 'morgan'
redis              = require 'redis'
debug              = require('debug')('meshblu-server-http:server')
RedisNS            = require '@octoblu/redis-ns'
ConnectionPool     = require './src/models/connection-pool'

AuthenticateController  = require './src/controllers/authenticate-controller'
MessagesController      = require './src/controllers/messages-controller'
SubscriptionsController = require './src/controllers/subscriptions-controller'
WhoamiController        = require './src/controllers/whoami-controller'

PORT      = process.env.PORT ? 80
NAMESPACE = process.env.NAMESPACE ? 'meshblu'
JOB_TIMEOUT_SECONDS = process.env.JOB_TIMEOUT_SECONDS ? 30

authenticateController  = new AuthenticateController timeoutSeconds: JOB_TIMEOUT_SECONDS
messagesController      = new MessagesController
subscriptionsController = new SubscriptionsController timeoutSeconds: JOB_TIMEOUT_SECONDS
whoamiController        = new WhoamiController timeoutSeconds: JOB_TIMEOUT_SECONDS

connectionPool = new ConnectionPool
  max: 100
  min: 0
  returnToHead: true # sets connection pool to stack instead of queue behavior
  create: (callback) =>
    callback null, new RedisNS(NAMESPACE, redis.createClient(process.env.REDIS_URI))
  destroy: (client) =>
    client.end true

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
app.get '/v2/whoami', whoamiController.whoami

setInterval (=> debug 'connectionPool', JSON.stringify(connectionPool.getInfo())), 30000

server = app.listen PORT, ->
  host = server.address().address
  port = server.address().port

  console.log "Server running on #{host}:#{port}"
