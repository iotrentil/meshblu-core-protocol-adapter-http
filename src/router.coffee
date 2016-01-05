AuthenticateController  = require './controllers/authenticate-controller'
MessagesController      = require './controllers/messages-controller'
SubscriptionsController = require './controllers/subscriptions-controller'
WhoamiController        = require './controllers/whoami-controller'
DeviceV1Controller      = require './controllers/device-v1-controller'
DeviceV2Controller      = require './controllers/device-v2-controller'
DeviceV3Controller      = require './controllers/device-v3-controller'
SearchDeviceController  = require './controllers/search-device-controller'
TokenController         = require './controllers/token-controller'
PooledJobManager        = require './pooled-job-manager'

class Router
  constructor: ({jobManager})->
    @authenticateController  = new AuthenticateController {jobManager}
    @messagesController      = new MessagesController {jobManager}
    @subscriptionsController = new SubscriptionsController {jobManager}
    @whoamiController        = new WhoamiController {jobManager}
    @deviceV1Controller      = new DeviceV1Controller {jobManager}
    @deviceV2Controller      = new DeviceV2Controller {jobManager}
    @deviceV3Controller      = new DeviceV3Controller {jobManager}
    @searchDeviceController  = new SearchDeviceController {jobManager}
    @tokenController         = new TokenController {jobManager}

  route: (app) =>
    app.post '/authenticate', @authenticateController.create
    app.post '/messages', @messagesController.create
    app.get '/devices/:uuid/subscriptions', @subscriptionsController.list
    app.get '/v2/whoami', @whoamiController.show
    app.get '/devices/:uuid', @deviceV1Controller.get
    app.get '/devices/:uuid/publickey', @deviceV1Controller.getPublicKey
    app.get '/v2/devices/:uuid', @deviceV2Controller.get
    app.get '/v3/devices/:uuid', @deviceV3Controller.get
    app.post '/search/devices', @searchDeviceController.search
    app.delete '/devices/:uuid/tokens', @tokenController.revokeByQuery

module.exports = Router
