AuthenticateController     = require './controllers/authenticate-controller'
DeviceV1Controller         = require './controllers/device-v1-controller'
DeviceV2Controller         = require './controllers/device-v2-controller'
DeviceV3Controller         = require './controllers/device-v3-controller'
GlobalPublicKeyController  = require './controllers/global-public-key-controller'
MessagesController         = require './controllers/messages-controller'
MessengerController        = require './controllers/messenger-controller'
RegisterDeviceController   = require './controllers/register-device-controller'
SearchDeviceController     = require './controllers/search-device-controller'
StatusController           = require './controllers/status-controller'
SubscriptionsController    = require './controllers/subscriptions-controller'
TokenController            = require './controllers/token-controller'
UnregisterDeviceController = require './controllers/unregister-device-controller'
WhoamiController           = require './controllers/whoami-controller'
request                    = require 'request'
url                        = require 'url'

class Router
  constructor: ({jobManager, jobToHttp, messengerClientFactory, uuidAliasResolver})->
    @authenticateController     = new AuthenticateController {jobManager, jobToHttp}
    @deviceV1Controller         = new DeviceV1Controller {jobManager, jobToHttp}
    @deviceV2Controller         = new DeviceV2Controller {jobManager, jobToHttp}
    @deviceV3Controller         = new DeviceV3Controller {jobManager, jobToHttp}
    @globalPublicKeyController  = new GlobalPublicKeyController {jobManager, jobToHttp}
    @messagesController         = new MessagesController {jobManager, jobToHttp}
    @messengerController        = new MessengerController {jobManager, jobToHttp, messengerClientFactory, uuidAliasResolver}
    @registerDeviceController   = new RegisterDeviceController {jobManager}
    @searchDeviceController     = new SearchDeviceController {jobManager, jobToHttp}
    @statusController           = new StatusController {jobManager}
    @subscriptionsController    = new SubscriptionsController {jobManager, jobToHttp}
    @tokenController            = new TokenController {jobManager, jobToHttp}
    @unregisterDeviceController = new UnregisterDeviceController {jobManager, jobToHttp}
    @whoamiController           = new WhoamiController {jobManager, jobToHttp}

  route: (app) =>
    app.get '/publickey', @globalPublicKeyController.get
    app.post '/authenticate', @authenticateController.create
    app.post '/messages', @messagesController.create
    app.get '/v2/devices/:uuid/subscriptions', @subscriptionsController.list
    app.get '/v2/whoami', @whoamiController.show
    app.post '/devices', @registerDeviceController.register
    app.delete '/devices/:uuid', @unregisterDeviceController.unregister
    app.get '/devices/:uuid', @deviceV1Controller.get
    app.get '/devices/:uuid/publickey', @deviceV1Controller.getPublicKey
    app.put '/devices/:uuid', @deviceV2Controller.update
    app.get '/v2/devices/:uuid', @deviceV2Controller.get
    app.patch '/v2/devices/:uuid', @deviceV2Controller.update
    app.put '/v2/devices/:uuid', @deviceV2Controller.updateDangerously
    app.get '/v3/devices/:uuid', @deviceV3Controller.get
    app.get '/mydevices', @searchDeviceController.mydevices
    app.get '/devices', @searchDeviceController.searchV1
    app.get '/v2/devices', @searchDeviceController.searchV2
    app.post '/search/devices', @searchDeviceController.searchV3
    app.get '/status', @statusController.get
    app.delete '/devices/:uuid/tokens', @tokenController.revokeByQuery
    app.get '/subscribe', @messengerController.subscribeSelf
    app.get '/subscribe/:uuid', @messengerController.subscribe
    app.get '/subscribe/:uuid/broadcast', @messengerController.subscribeBroadcast
    app.get '/subscribe/:uuid/sent', @messengerController.subscribeSent
    app.get '/subscribe/:uuid/received', @messengerController.subscribeReceived

module.exports = Router
