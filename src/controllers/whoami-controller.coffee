Device     = require '../models/device'
MeshbluAuthParser = require '../helpers/meshblu-auth-parser'

class WhoamiController
  constructor: ({@timeoutSeconds}={}) ->
    @authParser = new MeshbluAuthParser

  whoami: (request, response) =>
    device = new Device
      client: request.connection
      timeoutSeconds: @timeoutSeconds

    auth = @authParser.parse request

    internalRequest =
      auth:     auth
      fromUuid: auth.uuid ? request.get('x-as')
      toUuid:   auth.uuid ? request.get('x-as')

    device.getDevice internalRequest, (error, deviceResponse) =>
      return response.status(error.code ? 502).send error.message if error?
      {code,data} = deviceResponse
      response.status(code).json data

module.exports = WhoamiController
