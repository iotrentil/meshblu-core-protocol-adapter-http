debug = require('debug')('meshblu-server-http:register-device-controller')
_     = require 'lodash'

class RegisterDeviceController
  constructor: ({@jobManager}) ->

  register: (req, res) =>
    properties = _.cloneDeep req.body
    if properties.owner?
      properties.discoverWhitelist ?= []
      properties.configureWhitelist ?= []
      properties.discoverWhitelist.push(properties.owner) unless _.includes(properties.discoverWhitelist, '*')
      properties.configureWhitelist.push(properties.owner) unless _.includes(properties.configureWhitelist, '*')

    properties.discoverWhitelist ?= ['*']
    properties.configureWhitelist ?= ['*']
    properties.sendWhitelist ?= ['*']
    properties.receiveWhitelist ?= ['*']

    options =
      metadata:
        jobType: 'RegisterDevice'
      data: properties

    @jobManager.do 'request', 'response', options, (error, jobResponse) =>
      return res.sendError error if error?
      _.each jobResponse.metadata, (value, key) => res.set "x-meshblu-#{key}", value
      res.status(jobResponse.metadata.code).send(JSON.parse jobResponse.rawData)

module.exports = RegisterDeviceController
