_ = require 'lodash'
request = require 'request'
Server = require '../../src/server'
async      = require 'async'
redis      = require 'redis'
RedisNS    = require '@octoblu/redis-ns'
JobManager = require 'meshblu-core-job-manager'

describe 'PUT /v2/devices/:uuid', ->
  beforeEach (done) ->
    @port = 0xd00d
    @sut = new Server
      port: @port
      disableLogging: true
      jobTimeoutSeconds: 1
      namespace: 'meshblu:server:http:test'
      jobLogQueue: 'meshblu:job-log'
      jobLogRedisUri: 'redis://localhost:6379'
      meshbluHost: 'localhost'
      meshbluPort: 3000

    @sut.run done

  afterEach (done) ->
    @sut.stop => done()

  beforeEach ->
    @redis = _.bindAll new RedisNS 'meshblu:server:http:test', redis.createClient()
    @jobManager = new JobManager client: @redis, timeoutSeconds: 1

  context 'when the request is successful', ->
    beforeEach ->
      async.forever (next) =>
        @jobManager.getRequest ['request'], (error, request) =>
          next request
          return unless request?
          @request = request

          response =
            metadata:
              code: 204
              responseId: request.metadata.responseId
              name: 'koshin'
            data:
              uuid: 'secret-island'

          @jobManager.createResponse 'response', response, (error) =>
            throw error if error?

    beforeEach (done) ->
      options =
        auth:
          username: 'irritable-captian'
          password: 'poop-deck'
        json:
          $set:
            props: 'yes, please'

        headers:
          'x-meshblu-as': 'treasure-map'

      request.put "http://localhost:#{@port}/v2/devices/secret-island", options, (error, @response, @body) =>
        done error

    it 'should return a 204', ->
      expect(@response.statusCode).to.equal 204

    it 'should not have the uuid and token in the request', ->
      expect(@request.rawData).to.equal '{"$set":{"props":"yes, please"}}'

    it 'should have the metadata in the headers', ->
      expect(@response.headers).to.containSubset
        'x-meshblu-code': '204'
        'x-meshblu-name': 'koshin'
