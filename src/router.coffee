AuthenticateController  = require './controllers/authenticate-controller'
MessagesController      = require './controllers/messages-controller'
SubscriptionsController = require './controllers/subscriptions-controller'
WhoamiController        = require './controllers/whoami-controller'
DeviceV1Controller     = require './controllers/device-v1-controller'
DeviceV2Controller     = require './controllers/device-v2-controller'
DeviceV3Controller     = require './controllers/device-v3-controller'
SearchDeviceController  = require './controllers/search-device-controller'

class Router
  constructor: ({timeoutSeconds})->
    @authenticateController  = new AuthenticateController {timeoutSeconds}
    @messagesController      = new MessagesController {timeoutSeconds}
    @subscriptionsController = new SubscriptionsController {timeoutSeconds}
    @whoamiController        = new WhoamiController {timeoutSeconds}
    @deviceV1Controller      = new DeviceV1Controller {timeoutSeconds}
    @deviceV2Controller      = new DeviceV2Controller {timeoutSeconds}
    @deviceV3Controller      = new DeviceV3Controller {timeoutSeconds}
    @searchDeviceController  = new SearchDeviceController {timeoutSeconds}

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

module.exports = Router
