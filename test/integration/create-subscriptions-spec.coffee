_ = require 'lodash'
request = require 'request'
Server = require '../../src/server'
async      = require 'async'
redis      = require 'ioredis'
RedisNS    = require '@octoblu/redis-ns'
JobManager = require 'meshblu-core-job-manager'

describe 'POST /v2/devices/:subscriberUuid/subscriptions/:emitterUuid/:type', ->
  beforeEach (done) ->
    @port = 0xd00d
    @sut = new Server
      port: @port
      disableLogging: true
      jobTimeoutSeconds: 1
      namespace: 'meshblu:server:http:test'
      jobLogQueue: 'meshblu:job-log'
      jobLogRedisUri: 'redis://localhost:6379'
      maxConnections: 10
      jobLogSampleRate: 10
      redisUri: 'redis://localhost'

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
              code: 201
              responseId: request.metadata.responseId
            data: {}

          @jobManager.createResponse 'response', response, (error) =>
            throw error if error?

    beforeEach (done) ->
      options =
        auth:
          username: 'irritable-captian'
          password: 'poop-deck'

      request.post "http://localhost:#{@port}/v2/devices/irritable-captian/subscriptions/another-uuid/broadcast", options, (error, @response, @body) =>
        done error

    it 'should have the correct jobType', ->
      expect(@request.metadata.jobType).to.equal 'CreateSubscription'

    it 'should have the right toUuid', ->
      expect(@request.metadata.toUuid).to.equal 'irritable-captian'

    it 'should have the correct data', ->
      expect(JSON.parse @request.rawData).to.deep.equal {subscriberUuid:'irritable-captian', emitterUuid: 'another-uuid', type: 'broadcast'}

    it 'should return a 204', ->
      expect(@response.statusCode).to.equal 204

  context 'when the subscription already exists', ->
    beforeEach ->
      async.forever (next) =>
        @jobManager.getRequest ['request'], (error, request) =>
          next request
          return unless request?

          @request = request

          response =
            metadata:
              code: 304
              responseId: request.metadata.responseId
            data: {}

          @jobManager.createResponse 'response', response, (error) =>
            throw error if error?

    beforeEach (done) ->
      options =
        auth:
          username: 'irritable-captian'
          password: 'poop-deck'

      request.post "http://localhost:#{@port}/v2/devices/irritable-captian/subscriptions/another-uuid/broadcast", options, (error, @response, @body) =>
        done error

    it 'should have the correct jobType', ->
      expect(@request.metadata.jobType).to.equal 'CreateSubscription'

    it 'should have the right toUuid', ->
      expect(@request.metadata.toUuid).to.equal 'irritable-captian'

    it 'should have the correct data', ->
      expect(JSON.parse @request.rawData).to.deep.equal {subscriberUuid:'irritable-captian', emitterUuid: 'another-uuid', type: 'broadcast'}

    it 'should return a 204', ->
      expect(@response.statusCode).to.equal 204
