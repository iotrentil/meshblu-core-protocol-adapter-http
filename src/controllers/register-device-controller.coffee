debug = require('debug')('meshblu-core-protocol-adapter-http:register-device-controller')
_     = require 'lodash'

class RegisterDeviceController
  constructor: ({@jobManager,@jobToHttp}) ->

  register: (req, res) =>
    properties = _.cloneDeep req.body

    unless properties?.meshblu?.version == '2.0.0'
      if properties.owner?
        properties.discoverWhitelist ?= []
        properties.configureWhitelist ?= []
        if _.isString properties.owner
          properties.discoverWhitelist.push(properties.owner) unless _.includes(properties.discoverWhitelist, '*')
          properties.configureWhitelist.push(properties.owner) unless _.includes(properties.configureWhitelist, '*')

      properties.discoverWhitelist ?= ['*']
      properties.configureWhitelist ?= ['*']
      properties.sendWhitelist ?= ['*']
      properties.receiveWhitelist ?= ['*']

    req.body = properties

    job = @jobToHttp.httpToJob jobType: 'RegisterDevice', request: req, toUuid: req.params.uuid

    @jobManager.do 'request', 'response', job, (error, jobResponse) =>
      return res.sendError error if error?
      @jobToHttp.sendJobResponse {res, jobResponse}

module.exports = RegisterDeviceController
