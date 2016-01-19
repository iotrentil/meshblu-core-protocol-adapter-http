MeshbluAuthParser = require '../helpers/meshblu-auth-parser'
debug = require('debug')('meshblu-server-http:messages-controller')

class MessagesController
  constructor: ({@jobManager}) ->
    @authParser = new MeshbluAuthParser

  create: (req, res) =>
    auth = @authParser.parse req
    options =
      metadata:
        auth:     auth
        fromUuid: req.get('x-meshblu-as')
        toUuid:   auth.uuid
        jobType: 'SendMessage'
      data: req.body

    @jobManager.do 'request', 'response', options, (error, response) =>
      return res.status(error.code ? 500).send(error.message) if error?
      res.status(response.metadata.code).end()

module.exports = MessagesController
