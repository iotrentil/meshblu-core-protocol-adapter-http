_                       = require 'lodash'
moment                  = require 'moment'
UUID                    = require 'uuid'
request                 = require 'request'
Server                  = require '../../src/server'
Redis                   = require 'ioredis'
RedisNS                 = require '@octoblu/redis-ns'
{ JobManagerResponder } = require 'meshblu-core-job-manager'

describe 'POST /messages', ->
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

  beforeEach (done) ->
    @jobLogClient = new Redis 'localhost', dropBufferSupport: true
    @jobLogClient.on 'ready', =>
      @jobLogClient.del @jobLogQueue, done
    return # redis fix

  context 'when the request is successful', ->
    beforeEach ->
      @jobManager.do (@jobRequest, callback) =>
        response =
          metadata:
            code: 201
            metrics: @jobRequest.metadata.metrics
            jobLogs: @jobRequest.metadata.jobLogs
            responseId: @jobRequest.metadata.responseId

        callback null, response

    beforeEach (done) ->
      options =
        auth:
          username: 'irritable-captian'
          password: 'poop-deck'
        json:
          devices: ['*']

      request.post "http://localhost:#{@port}/messages", options, (error, @response) =>
        done error

    it 'should return a 201', ->
      expect(@response.statusCode).to.equal 201

    it 'should submit the correct job type', ->
      expect(@jobRequest.metadata.jobType).to.equal 'SendMessage'

    it 'should set the correct auth data', ->
      expect(@jobRequest.metadata.auth).to.deep.equal uuid: 'irritable-captian', token: 'poop-deck'

    it 'should send the correct message', ->
      message = JSON.parse @jobRequest.rawData
      expect(message).to.deep.equal devices: ['*']

    it 'should log the message', (done) ->
      @jobLogClient.llen @jobLogQueue, (error, count) =>
        return done error if error?
        expect(count).to.equal 1
        done()
      return # redis fix

    it 'should log the attempt and success of the message', (done) ->
      @jobLogClient.lindex @jobLogQueue, 0, (error, jobStr) =>
        return done error if error?
        todaySuffix = moment.utc().format('YYYY-MM-DD')
        index = "metric:meshblu-core-protocol-adapter-http:sampled-#{todaySuffix}"
        expect(JSON.parse jobStr).to.containSubset {
          "index": index
          "type": "meshblu-core-protocol-adapter-http:request"
          "body": {
            "request": {
              "metadata": {
                "auth": {
                  "uuid": "irritable-captian"
                }
                "fromUuid": "irritable-captian"
                "jobType": "SendMessage"
                "toUuid": "irritable-captian"
              }
            }
            "response": {
              "metadata": {
                "code": 201
                "success": true
              }
            }
          }
        }
        done()
      return # redis fix

  context 'when the request is unsuccessful', ->
    beforeEach ->
      @jobManager.do (@jobRequest, callback) =>
        response =
          metadata:
            code: 506
            responseId: @jobRequest.metadata.responseId

        callback null, response

    beforeEach (done) ->
      options =
        auth:
          username: 'irritable-captian'
          password: 'poop-deck'
        json:
          devices: ['*']

      request.post "http://localhost:#{@port}/messages", options, (error, @response) =>
        done error

    it 'should return a 506', ->
      expect(@response.statusCode).to.equal 506

    it 'should submit the correct job type', ->
      expect(@jobRequest.metadata.jobType).to.equal 'SendMessage'

    it 'should set the correct auth data', ->
      expect(@jobRequest.metadata.auth).to.deep.equal uuid: 'irritable-captian', token: 'poop-deck'

    it 'should send the correct message', ->
      message = JSON.parse @jobRequest.rawData
      expect(message).to.deep.equal devices: ['*']

    it 'should log the message', (done) ->
      @jobLogClient.llen @jobLogQueue, (error, count) =>
        return done error if error?
        expect(count).to.equal 2
        done()
      return # redis fix

    it 'should log the attempt and success of the message', (done) ->
      @jobLogClient.lindex @jobLogQueue, 0, (error, jobStr) =>
        return done error if error?
        todaySuffix = moment.utc().format('YYYY-MM-DD')
        index = "metric:meshblu-core-protocol-adapter-http:failed-#{todaySuffix}"
        expect(JSON.parse jobStr).to.containSubset {
          "index": index
          "type": "meshblu-core-protocol-adapter-http:request"
          "body": {
            "request": {
              "metadata": {
                "auth": {
                  "uuid": "irritable-captian"
                }
                "fromUuid": "irritable-captian"
                "jobType": "SendMessage"
                "toUuid": "irritable-captian"
              }
            }
            "response": {
              "metadata": {
                "code": 506
                "success": false
              }
            }
          }
        }
        done()
      return # redis fix
