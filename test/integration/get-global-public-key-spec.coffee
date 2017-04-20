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
