_ = require 'lodash'
MeshbluAuthParser = require '../helpers/meshblu-auth-parser'

class JobToHttp
  constructor: () ->
    @authParser = new MeshbluAuthParser

  httpToJob: ({jobType, request, toUuid, data}) ->
    auth  = @authParser.parse request
    job =
      metadata:
        auth: auth
        fromUuid: request.get('x-meshblu-as') ? auth.uuid
        toUuid: toUuid
        jobType: jobType
      data: data ? request.body

    job

  sendJobResponse: ({jobResponse, res}) ->
    return res.status(error.code ? 500).send(error.message) if error?
    _.each jobResponse.metadata, (value, key) => res.set "x-meshblu-#{_.kebabCase(key)}", value
    
    return res.sendStatus jobResponse.metadata.code unless jobResponse.rawData?

    res.status(jobResponse.metadata.code).send JSON.parse(jobResponse.rawData)

  module.exports = JobToHttp
