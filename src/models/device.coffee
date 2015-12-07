JobManager = require 'meshblu-core-job-manager'

class Device
  constructor: (options={}, dependencies={}) ->
    {client,timeoutSeconds} = options
    {@uuid} = dependencies

    timeoutSeconds ?= 30
    @jobManager = new JobManager {client, timeoutSeconds}

  getDevice: (options, callback) =>
    options =
      metadata:
        auth: options.auth
        fromUuid: options.fromUuid
        toUuid: options.toUuid
        jobType: 'GetDevice'

    @jobManager.do 'request', 'response', options, (error, response) =>
      return callback error if error?
      return callback new Error('Response timeout exceeded') unless response?
      callback null,
        code: response.metadata.code
        status: response.metadata.status
        data: JSON.parse response.rawData

module.exports = Device
