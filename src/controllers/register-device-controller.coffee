debug = require('debug')('meshblu-server-http:register-device-controller')
_     = require 'lodash'

class RegisterDeviceController
  constructor: ({@jobManager}) ->

  register: (req, res) =>
    properties = _.cloneDeep req.body
    properties.discoverWhitelist = [properties.owner] if properties.owner?
    properties.configureWhitelist = [properties.owner] if properties.owner?
    properties.discoverWhitelist = ['*'] unless properties.discoverWhitelist?
    properties.configureWhitelist = ['*'] unless properties.configureWhitelist?
    properties.sendWhitelist = ['*'] unless properties.sendWhitelist?
    properties.receiveWhitelist = ['*'] unless properties.receiveWhitelist?

    options =
      metadata:
        jobType: 'RegisterDevice'
      data: properties

    @jobManager.do 'request', 'response', options, (error, jobResponse) =>
      return res.sendError error if error?
      _.each jobResponse.metadata, (value, key) => res.set "x-meshblu-#{key}", value
      res.status(jobResponse.metadata.code).send(JSON.parse jobResponse.rawData)

module.exports = RegisterDeviceController
