_                       = require 'lodash'
UUID                    = require 'uuid'
request                 = require 'request'
Server                  = require '../../src/server'
Redis                   = require 'ioredis'
RedisNS                 = require '@octoblu/redis-ns'
{ JobManagerResponder } = require 'meshblu-core-job-manager'

describe 'Authenticate', ->
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

  afterEach ->
    @sut.stop()

  beforeEach (done) ->
    @redis = new RedisNS @namespace, new Redis @redisUri, dropBufferSupport: true
    @redis.on 'ready', done

  afterEach (done) ->
    @redis.del @requestQueueName, @responseQueueName, done
    return # avoid returning redis

  beforeEach (done) ->
    @workerFunc = (@request, callback=_.noop) =>
      @jobManagerDo @request, callback

    @jobManager = new JobManagerResponder {
      @redisUri
      @namespace
      @workerFunc
      maxConnections: 1
      queueTimeoutSeconds: 1
      jobTimeoutSeconds: 1
      jobLogSampleRate: 1
      requestQueueName: @requestQueueName
      responseQueueName: @responseQueueName
    }
    @jobManager.start done

  beforeEach ->
    @jobManager.do = (@jobManagerDo) =>

  afterEach ->
    @jobManager.stop()

  describe 'POST /authenticate', ->
    context 'when the request is successful', ->
      beforeEach ->
        @jobManager.do (@request, callback) =>
          response =
            metadata:
              code: 204
              responseId: @request.metadata.responseId

          callback null, response

      beforeEach (done) ->
        options =
          auth:
            username: 'irritable-captian'
            password: 'poop-deck'

        request.post "http://localhost:#{@port}/authenticate", options, (error, @response) =>
          done error

      it 'should have jobType Authenticate', ->
        expect(@request.metadata.jobType).to.equal 'Authenticate'

      it 'should have auth correct', ->
        expect(@request.metadata.auth).to.deep.equal uuid: 'irritable-captian', token: 'poop-deck'

      it 'should return a 204', ->
        expect(@response.statusCode).to.equal 204

  describe 'GET /authenticate/:uuid', ->
    context 'when the request is successful', ->
      beforeEach ->
        @jobManager.do (@request, callback) =>
          response =
            metadata:
              code: 204
              responseId: @request.metadata.responseId

          callback null, response

      beforeEach (done) ->
        options =
          auth:
            username: 'irritable-captian'
            password: 'poop-deck'
          qs:
            token: 'some-token'

        request.get "http://localhost:#{@port}/authenticate/some-uuid", options, (error, @response) =>
          done error

      it 'should have jobType Authenticate', ->
        expect(@request.metadata.jobType).to.equal 'Authenticate'

      it 'should have auth correct', ->
        expect(@request.metadata.auth).to.deep.equal uuid: 'some-uuid', token: 'some-token'

      it 'should return a 200', ->
        expect(@response.statusCode).to.equal 200
