debug = require('debug')('nanocyte-engine-simple:messages-controller')
MeshbluQueue = require '../models/meshblu-queue'

class MessagesController
  constructor: (options={}) ->
    @meshbluQueue = new MeshbluQueue

  create: (req, res) =>
    {uuid,token} = @getAuthUuidAndToken req

    messageToQueue =
      auth:
        uuid:  uuid
        token: token
      message: req.body

    @meshbluQueue.queueMessage messageToQueue
    res.status(200).send()

  getAuthUuidAndToken: (req) =>
    authUuid = undefined
    authToken = undefined

    if req.headers.authorization
      parts = req.headers.authorization.split(' ')
      scheme = parts[0]
      encodedToken = parts[1]
      token = new Buffer(encodedToken, 'base64').toString().split(':')
      authUuid = token[0]
      authToken = token[1]

    if req.header('skynet_auth_uuid') and req.header('skynet_auth_token')
      authUuid = req.header('skynet_auth_uuid')
      authToken = req.header('skynet_auth_token')

    if req.header('meshblu_auth_uuid') and req.header('meshblu_auth_token')
      authUuid = req.header('meshblu_auth_uuid')
      authToken = req.header('meshblu_auth_token')

    if req.header('X-Meshblu-UUID') and req.header('X-Meshblu-Token')
      authUuid = req.header('X-Meshblu-UUID')
      authToken = req.header('X-Meshblu-Token')

    if authUuid
      authUuid = authUuid.trim()

    if authToken
      authToken = authToken.trim()

    {
      uuid: authUuid
      token: authToken
    }



module.exports = MessagesController
