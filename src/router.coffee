AuthenticateController     = require './controllers/authenticate-controller'
BroadcastsController       = require './controllers/broadcasts-controller'
DeviceV1Controller         = require './controllers/device-v1-controller'
DeviceV2Controller         = require './controllers/device-v2-controller'
DeviceV3Controller         = require './controllers/device-v3-controller'
GlobalPublicKeyController  = require './controllers/global-public-key-controller'
MessagesController         = require './controllers/messages-controller'
RegisterDeviceController   = require './controllers/register-device-controller'
SearchDeviceController     = require './controllers/search-device-controller'
SearchTokenController      = require './controllers/search-token-controller'
StatusController           = require './controllers/status-controller'
SubscriptionsController    = require './controllers/subscriptions-controller'
TokenController            = require './controllers/token-controller'
UnregisterDeviceController = require './controllers/unregister-device-controller'
WhoamiController           = require './controllers/whoami-controller'
request                    = require 'request'
url                        = require 'url'

class Router
  constructor: ({jobManager, jobToHttp}) ->
    @authenticateController     = new AuthenticateController {jobManager, jobToHttp}
    @broadcastsController       = new BroadcastsController {jobManager, jobToHttp}
    @deviceV1Controller         = new DeviceV1Controller {jobManager, jobToHttp}
    @deviceV2Controller         = new DeviceV2Controller {jobManager, jobToHttp}
    @deviceV3Controller         = new DeviceV3Controller {jobManager, jobToHttp}
    @globalPublicKeyController  = new GlobalPublicKeyController {jobManager, jobToHttp}
    @messagesController         = new MessagesController {jobManager, jobToHttp}
    @registerDeviceController   = new RegisterDeviceController {jobManager, jobToHttp}
    @searchDeviceController     = new SearchDeviceController {jobManager, jobToHttp}
    @searchTokenController      = new SearchTokenController {jobManager, jobToHttp}
    @statusController           = new StatusController {jobManager, jobToHttp}
    @subscriptionsController    = new SubscriptionsController {jobManager, jobToHttp}
    @tokenController            = new TokenController {jobManager, jobToHttp}
    @unregisterDeviceController = new UnregisterDeviceController {jobManager, jobToHttp}
    @whoamiController           = new WhoamiController {jobManager, jobToHttp}

  route: (app) =>
    app.get    '/ping', (req, res) => res.send(online: true)
    app.get    '/authenticate/:uuid', @authenticateController.checkDevice
    app.post   '/authenticate', @authenticateController.check
    app.post   '/broadcasts', @broadcastsController.create
    app.post   '/claimdevice/:uuid', @deviceV1Controller.claimdevice
    app.get    '/devices', @searchDeviceController.searchV1
    app.post   '/devices', @registerDeviceController.register
    app.put    '/devices/:uuid', @deviceV2Controller.update
    app.get    '/devices/:uuid', @deviceV1Controller.get
    app.delete '/devices/:uuid', @unregisterDeviceController.unregister
    app.get    '/devices/:uuid/publickey', @deviceV1Controller.getPublicKey
    app.post   '/devices/:uuid/token', @tokenController.resetToken
    app.post   '/devices/:uuid/tokens', @tokenController.create
    app.delete '/devices/:uuid/tokens', @tokenController.revokeByQuery
    app.delete '/devices/:uuid/tokens/:token', @tokenController.destroy
    app.post   '/messages', @messagesController.create
    app.get    '/mydevices', @searchDeviceController.mydevices
    app.get    '/publickey', @globalPublicKeyController.get
    app.post   '/search/devices', @searchDeviceController.searchV3
    app.post   '/search/tokens', @searchTokenController.search
    app.get    '/status', @statusController.get
    app.get    '/subscribe*', (req, res) =>
      proto = req.header('x-forwarded-proto') ? 'https'
      host = 'meshblu-http-streaming.octoblu.com'
      url = "#{proto}://#{host}#{req.url}"
      res.redirect(301, url)
    app.get    '/v2/devices', @searchDeviceController.searchV2
    app.get    '/v2/devices/:uuid', @deviceV2Controller.get
    app.patch  '/v2/devices/:uuid', @deviceV2Controller.update
    app.put    '/v2/devices/:uuid', @deviceV2Controller.updateDangerously
    app.put    '/v2/devices/:uuid/find-and-update', @deviceV2Controller.findAndUpdate
    app.get    '/v2/devices/:uuid/subscriptions', @subscriptionsController.list
    app.delete '/v2/devices/:subscriberUuid/subscriptions', @subscriptionsController.removeMany
    app.post   '/v2/devices/:subscriberUuid/subscriptions/:emitterUuid/:type', @subscriptionsController.create
    app.delete '/v2/devices/:subscriberUuid/subscriptions/:emitterUuid/:type', @subscriptionsController.remove
    app.get    '/v3/devices/:uuid', @deviceV3Controller.get
    app.get    '/v2/whoami', @whoamiController.show

    # Export APIs
    ###
    @apiDefine Auth
      @apiHeader {String} Authorization Basic UUID:TOKEN \
        See http://www.ietf.org/rfc/rfc2617.txt
    ###

    ###
    @apiName MyDevices
    @apiGroup Devices
    @api {get} /export/mydevices Get my devices
    @apiVersion 1.0.0
    @apiDescription Returns all information of all devices or nodes belonging to a user's UUID \
        (identified with an "owner" property and user's UUID i.e. "owner":"0d1234a0-1234-11e3-b09c-1234e847b2cc")
    @apiUse Auth
    @apiContentType application/json
    ###
    app.get    '/export/mydevices', @searchDeviceController.mydevicesExport

    ###
    @apiName RegisterDevice
    @apiGroup Devices
    @api {post} /export/devices Register a device
    @apiVersion 1.0.0
    @apiDescription Registers a node or device. \
        It returns a UUID device id and security token. You can pass any key/value pairs.
    @apiUse Auth
    @apiContentType application/json
    ###
    app.post   '/export/devices', @registerDeviceController.registerExport

    ###
    @apiName DeleteDevice
    @apiGroup Devices
    @api {delete} /export/devices/:uuid Delete a device
    @apiVersion 1.0.0
    @apiDescription Deletes or unregisters a node or device currently registered that you have access to update.
    @apiUse Auth
    @apiParam {String} uuid device's uuid
    @apiContentType application/json
    ###
    app.delete '/export/devices/:uuid', @unregisterDeviceController.unregister

    ###
    @apiName GetDevice
    @apiGroup Devices
    @api {get} /export/devices/:uuid Get a device
    @apiVersion 1.0.0
    @apiDescription Returns all information (except the token) of a specific device or node
    @apiUse Auth
    @apiParam {String} uuid device's uuid
    @apiContentType application/json
    @apiSuccess {Object} device     all information of specific device
    ###
    app.get    '/export/devices/:uuid', @deviceV2Controller.getExport

    ###
    @apiName UpdateDevice
    @apiGroup Devices
    @api {patch} /export/devices/:uuid Update a device
    @apiVersion 1.0.0
    @apiDescription Updates a node or device that you have access to update. \
        You can pass any key/value pairs to update object.
    @apiUse Auth
    @apiParam {String} uuid device's uuid
    @apiContentType application/json
    ###
    app.patch  '/export/devices/:uuid', @deviceV2Controller.update

module.exports = Router
