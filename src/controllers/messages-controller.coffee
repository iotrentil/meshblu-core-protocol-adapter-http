debug = require('debug')('nanocyte-engine-simple:messages-controller')
MeshbluAuthParser = require '../helpers/meshblu-auth-parser'
MeshbluQueue      = require '../models/meshblu-queue'

class MessagesController
  constructor: (options={}) ->
    {@client} = options
    @authParser = new MeshbluAuthParser

  create: (req, res) =>
    {uuid,token} = @authParser.parse req

    meshbluQueue = new MeshbluQueue client: @client

    messageToQueue =
      auth:
        uuid:  uuid
        token: token
      message: req.body

    meshbluQueue.queueMessage messageToQueue
    res.status(200).send()

module.exports = MessagesController
