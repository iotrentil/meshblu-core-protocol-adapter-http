AuthenticateController  = require './controllers/authenticate-controller'
MessagesController      = require './controllers/messages-controller'
SubscriptionsController = require './controllers/subscriptions-controller'
WhoamiController        = require './controllers/whoami-controller'

class Router
  constructor: ({timeoutSeconds})->
    @authenticateController  = new AuthenticateController {timeoutSeconds}
    @messagesController      = new MessagesController {timeoutSeconds}
    @subscriptionsController = new SubscriptionsController {timeoutSeconds}
    @whoamiController        = new WhoamiController {timeoutSeconds}

  route: (app) =>
    app.post '/authenticate', @authenticateController.create
    app.post '/messages', @messagesController.create
    app.get '/devices/:uuid/subscriptions', @subscriptionsController.list
    app.get '/v2/whoami', @whoamiController.show

module.exports = Router
