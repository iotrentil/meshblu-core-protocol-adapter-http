_                       = require 'lodash'
UUID                    = require 'uuid'
request                 = require 'request'
Server                  = require '../../src/server'
Redis                   = require 'ioredis'
RedisNS                 = require '@octoblu/redis-ns'
{ JobManagerResponder } = require 'meshblu-core-job-manager'

describe 'POST /devices', ->
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
          rawData: '{"uuid":"boxes-of-stuff","token":"secret-boxes-of-stuff"}'

        callback null, response

    beforeEach (done) ->
      options =
        json: true
      request.post "http://localhost:#{@port}/devices", options, (error, @response, @body) =>
        done error

    it 'should create the job with the correct type', ->
      expect(@request.metadata.jobType).to.equal 'RegisterDevice'

    it 'should create the job correct data', ->
      expect(JSON.parse @request.rawData).to.deep.equal {discoverWhitelist: ['*'],configureWhitelist:['*'],sendWhitelist: ['*'],receiveWhitelist:['*']}

    it 'should return a 201', ->
      expect(@response.statusCode).to.equal 201

    it 'should return meshblu:online', ->
      expect(@body).to.deep.equal uuid: 'boxes-of-stuff', token: 'secret-boxes-of-stuff'

  context 'when request is made with an owner', ->
    beforeEach ->
      @jobManager.do (@request, callback) =>
        response =
          metadata:
            code: 201
            responseId: @request.metadata.responseId
          rawData: '{"uuid":"boxes-of-stuff","token":"secret-boxes-of-stuff","discoverWhitelist":["owner-uuid"],"configureWhitelist":["owner-uuid"]}'

        callback null, response

    beforeEach (done) ->
      options =
        json:
          owner: 'owner-uuid'
      request.post "http://localhost:#{@port}/devices", options, (error, @response, @body) =>
        done error

    it 'should create the job with the correct type', ->
      expect(@request.metadata.jobType).to.equal 'RegisterDevice'

    it 'should create the job correct data', ->
      expect(JSON.parse @request.rawData).to.deep.equal {
        discoverWhitelist: ['owner-uuid'],
        configureWhitelist:['owner-uuid'],
        sendWhitelist: ['*'],
        receiveWhitelist: ['*'],
        owner: 'owner-uuid'
      }

    it 'should return a 201', ->
      expect(@response.statusCode).to.equal 201

    it 'should return meshblu:online', ->
      expect(@body).to.deep.equal
        uuid: 'boxes-of-stuff'
        token: 'secret-boxes-of-stuff'
        discoverWhitelist: ['owner-uuid']
        configureWhitelist: ['owner-uuid']

  context 'when request is made with a meshblu 2.0.0 device', ->
    beforeEach ->
      @jobManager.do (@request, callback) =>
        response =
          metadata:
            code: 201
            responseId: @request.metadata.responseId
          rawData: '{"uuid":"boxes-of-stuff","token":"secret-boxes-of-stuff","discoverWhitelist":["owner-uuid"],"configureWhitelist":["owner-uuid"]}'

        callback null, response

    beforeEach (done) ->
      options =
        json:
          meshblu:
            version: '2.0.0'

      request.post "http://localhost:#{@port}/devices", options, (error, @response, @body) =>
        done error

    it 'should create the job with the correct type', ->
      expect(@request.metadata.jobType).to.equal 'RegisterDevice'

    it 'should create the job correct data', ->
      expect(_.keys(JSON.parse @request.rawData)).not.to.containSubset [
        "discoverWhitelist"
        "configureWhitelist"
        "sendWhitelist"
        "receiveWhitelist"
      ]

    it 'should return a 201', ->
      expect(@response.statusCode).to.equal 201
