_                       = require 'lodash'
UUID                    = require 'uuid'
request                 = require 'request'
Server                  = require '../../src/server'
Redis                   = require 'ioredis'
RedisNS                 = require '@octoblu/redis-ns'
{ JobManagerResponder } = require 'meshblu-core-job-manager'

describe 'GET /publickey', ->
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

  context 'when the request is successful', ->
    beforeEach ->
      @jobManager.do (@request, callback) =>
        response =
          metadata:
            code: 200
            responseId: @request.metadata.responseId
          data:
            publicKey: 'abc123'

        callback null, response

    beforeEach (done) ->
      request.get "http://localhost:#{@port}/publickey", (error, @response, @body) =>
        done error

    it 'should return a 200', ->
      expect(@response.statusCode).to.equal 200

    it 'should have the publicKey in the body', ->
      expect(JSON.parse(@body)).to.deep.equal publicKey: 'abc123'

    it 'should have the metadata in the headers', ->
      expect(@response.headers).to.containSubset
        'x-meshblu-code': '200'
