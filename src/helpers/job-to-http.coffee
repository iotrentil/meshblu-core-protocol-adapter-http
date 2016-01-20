MeshbluAuthParser = require '../helpers/meshblu-auth-parser'

class JobToHttp
  @requestToJob: ({jobType, request, toUuid}) ->
    authParser = new MeshbluAuthParser

    auth  = authParser.parse request
    job =
      metadata:
        auth: auth
        fromUuid: request.get('x-meshblu-as') ? auth.uuid
        toUuid: toUuid
        jobType: jobType
      data: request.body

    job

  @sendJobResponse: ({job, response}) ->


  module.exports = JobToHttp
