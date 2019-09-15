debug = require('debug')('meshblu-core-protocol-adapter-http:register-device-controller')
_     = require 'lodash'

class RegisterDeviceController
  constructor: ({@jobManager,@jobToHttp}) ->

  register: (req, res) =>
    properties = req.body

    unless _.isPlainObject properties
      properties = {}

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

    @jobManager.do job, (error, jobResponse) =>
      return res.sendError error if error?
      @jobToHttp.sendJobResponse {res, jobResponse}

  registerExport: (req, res) =>
    properties = req.body

    unless _.isPlainObject properties
      properties = {}

    unless properties?.meshblu?
      properties.meshblu = {
        version: '2.0.0'
        whitelists:
          broadcast:
            as:       []
            received: []
            sent:     []
          configure:
            as:       []
            received: []
            sent:     []
            update:   []
          discover:
            view:     []
            as:       []
          message:
            as:       []
            received: []
            sent:     []
            from:     []
      }
      if properties.owner?
        properties.meshblu.whitelists.broadcast.as.push { uuid: properties.owner }
        properties.meshblu.whitelists.broadcast.received.push { uuid: properties.owner }
        properties.meshblu.whitelists.broadcast.sent.push { uuid: properties.owner }
        properties.meshblu.whitelists.configure.as.push { uuid: properties.owner }
        properties.meshblu.whitelists.configure.received.push { uuid: properties.owner }
        properties.meshblu.whitelists.configure.sent.push { uuid: properties.owner }
        properties.meshblu.whitelists.configure.update.push { uuid: properties.owner }
        properties.meshblu.whitelists.discover.as.push { uuid: properties.owner }
        properties.meshblu.whitelists.discover.view.push { uuid: properties.owner }
        properties.meshblu.whitelists.message.as.push { uuid: properties.owner }
        properties.meshblu.whitelists.message.received.push { uuid: properties.owner }
        properties.meshblu.whitelists.message.sent.push { uuid: properties.owner }
        properties.meshblu.whitelists.message.from.push { uuid: properties.owner }

    req.body = properties

    job = @jobToHttp.httpToJob jobType: 'RegisterDevice', request: req, toUuid: req.params.uuid

    @jobManager.do job, (error, jobResponse) =>
      return res.sendError error if error?
      device = JSON.parse jobResponse.rawData
      result = _.omit device, ['meshblu', 'schemas']
      jobResponse.rawData = JSON.stringify result
      @jobToHttp.sendJobResponse {res, jobResponse}

module.exports = RegisterDeviceController
