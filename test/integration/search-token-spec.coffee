_                       = require 'lodash'
UUID                    = require 'uuid'
request                 = require 'request'
Server                  = require '../../src/server'
Redis                   = require 'ioredis'
RedisNS                 = require '@octoblu/redis-ns'
{ JobManagerResponder } = require 'meshblu-core-job-manager'

describe 'POST /search/tokens', ->
  beforeEach (done) ->
    @responseQueueId = UUID.v4()
    @requestQueueName = "request:queue:#{@responseQueueId}"
    @responseQueueName = "response:queue:#{@responseQueueId}"
    @namespace = 'test:meshblu-http'
    @jobLogQueue = 'test:meshblu:job-log'
    @port = 0xd00d
    @sut = new Server {
      @port
      disableLogging: true
      jobTimeoutSeconds: 1
      @namespace
      @jobLogQueue
      jobLogRedisUri: 'redis://localhost:6379'
      jobLogSampleRate: 10
      redisUri: 'redis://localhost'
      cacheRedisUri: 'redis://localhost'
      @requestQueueName
      @responseQueueName
    }

    @sut.run done

  afterEach (done) ->
    @sut.stop => done()

  beforeEach (done) ->
    @redis = new RedisNS @namespace, new Redis 'localhost', dropBufferSupport: true
    @redis.on 'ready', done

  afterEach (done) ->
    @redis.del @requestQueueName, @responseQueueName, done
    return # avoid returning redis

  beforeEach (done) ->
    @queueRedis = new RedisNS @namespace, new Redis 'localhost', dropBufferSupport: true
    @queueRedis.on 'ready', done

  beforeEach ->
    @jobManager = new JobManagerResponder {
      client: @redis
      queueClient: @queueRedis
      queueTimeoutSeconds: 1
      jobTimeoutSeconds: 1
      jobLogSampleRate: 1
      requestQueueName: @requestQueueName
      responseQueueName: @responseQueueName
    }

  describe '->search', ->
    context 'when the request is successful', ->
      beforeEach ->
        @jobManager.do (@request, callback) =>
          response =
            metadata:
              code: 200
              responseId: @request.metadata.responseId
              name: 'dinosaur-getter'
            data: [
                {uuid: 't-rex'}
                {uuid: 'megalodon'}
                {uuid: 'killasaurus'}
            ]

          callback null, response

      beforeEach (done) ->
        options =
          auth:
            username: 'irritable-captian'
            password: 'poop-deck'
          json: type: 'dinosaur'

          headers:
            'x-meshblu-as': 'treasure-map'
            'x-meshblu-erik-feature': 'custom-headers'

        request.post "http://localhost:#{@port}/search/tokens", options, (error, @response, @body) =>
          done error

      it 'should return a 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should dispatch the correct metadata', ->
        expect(@request).to.containSubset
          metadata:
            fromUuid: 'treasure-map'
            erikFeature: 'custom-headers'
            auth:
              uuid: 'irritable-captian'
              token: 'poop-deck'

      it 'should send the search body as the data of the job', ->
        data = JSON.parse @request.rawData
        expect(data).to.containSubset type: 'dinosaur'

      it 'should have a tokens array in the response', ->
        expect(@body).to.be.an.array
        expect(@body.length).to.equal 3
