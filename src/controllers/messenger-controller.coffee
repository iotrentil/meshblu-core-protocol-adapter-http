_                 = require 'lodash'
debug             = require('debug')('meshblu-server-http:whoami-controller')
{Readable}        = require 'stream'
MeshbluAuthParser = require '../helpers/meshblu-auth-parser'
MessengerManager  = require 'meshblu-core-manager-messenger'

class MessengerController
  constructor: ({@jobManager, @jobToHttp, @messengerClientFactory}) ->
    @authParser = new MeshbluAuthParser

  subscribeSelf: (req, res) =>
    auth = @authParser.parse req
    req.body = _.extend {}, req.query, req.body
    job = @jobToHttp.httpToJob jobType: 'GetAuthorizedSubscriptionTypes', request: req, toUuid: auth.uuid

    debug('dispatching request', job)
    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.sendError error if error?
      if jobResponse?.metadata?.code != 204
        return @jobToHttp.sendJobResponse {jobResponse, res}

      client = @messengerClientFactory.build()
      readStream = new Readable
      readStream._read = _.noop
      readStream.pipe res

      messenger = new MessengerManager {client}
      data = JSON.parse jobResponse.rawData
      {types} = data

      _.each types, (type) =>
        messenger.subscribe type, auth.uuid

      messenger.on 'message', (channel, message) =>
        readStream.push JSON.stringify(message) + '\n'



module.exports = MessengerController
