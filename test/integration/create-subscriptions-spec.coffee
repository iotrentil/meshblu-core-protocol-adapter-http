_                       = require 'lodash'
UUID                    = require 'uuid'
request                 = require 'request'
Server                  = require '../../src/server'
Redis                   = require 'ioredis'
RedisNS                 = require '@octoblu/redis-ns'
{ JobManagerResponder } = require 'meshblu-core-job-manager'

describe 'POST /v2/devices/:subscriberUuid/subscriptions/:emitterUuid/:type', ->
  beforeEach (done) ->
    @responseQueueId = UUID.v4()
    @requestQueueName = "request:queue:#{@responseQueueId}"
    @responseQueueName = "response:queue:#{@responseQueueId}"
    @namespace = 'test:meshblu-http'
    @jobLogQueue = 'test:meshblu:job-log'
    @redisUri = 'redis://localhost'
    @port = 0xd00d
    @sut = new Server {
      @port
      disableLogging: true
      jobTimeoutSeconds: 1
      @namespace
      @jobLogQueue
      jobLogRedisUri: @redisUri
      jobLogSampleRate: 1
      redisUri: @redisUri
      cacheRedisUri: @redisUri
      @requestQueueName
      @responseQueueName
    }

    @sut.run done

  afterEach (done) ->
    @sut.stop => done()

  beforeEach (done) ->
    @redis = new RedisNS @namespace, new Redis @redisUri, dropBufferSupport: true
    @redis.on 'ready', done

  afterEach (done) ->
    @redis.del @requestQueueName, @responseQueueName, done
    return # avoid returning redis

  beforeEach (done) ->
    @jobManager = new JobManagerResponder {
      @redisUri
      @namespace
      maxConnections: 1
      queueTimeoutSeconds: 1
      jobTimeoutSeconds: 1
      jobLogSampleRate: 1
      requestQueueName: @requestQueueName
      responseQueueName: @responseQueueName
    }
    @jobManager.start done

  afterEach (done) ->
    @jobManager.stop done

  context 'when the request is successful', ->
    beforeEach ->
      @jobManager.do (@request, callback) =>
        response =
          metadata:
            code: 201
            responseId: @request.metadata.responseId
          data: {}

        callback null, response

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
      @jobManager.do (@request, callback) =>
        response =
          metadata:
            code: 304
            responseId: @request.metadata.responseId
          data: {}

        callback null, response

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
