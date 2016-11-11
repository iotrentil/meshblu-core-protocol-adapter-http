_ = require 'lodash'
request = require 'request'
Server = require '../../src/server'
async      = require 'async'
moment     = require 'moment'
redis      = require 'ioredis'
RedisNS    = require '@octoblu/redis-ns'
JobManager = require 'meshblu-core-job-manager'

describe 'POST /broadcasts', ->
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
      jobLogSampleRate: 1
      redisUri: 'redis://localhost'

    @sut.run done

  afterEach (done) ->
    @sut.stop => done()

  beforeEach ->
    @redis = _.bindAll new RedisNS 'meshblu:server:http:test', redis.createClient(dropBufferSupport: true)
    @jobManager = new JobManager client: @redis, timeoutSeconds: 1, jobLogSampleRate: 1

  beforeEach (done) ->
    @jobLogClient = redis.createClient(dropBufferSupport: true)
    @jobLogClient.del 'meshblu:job-log', done
    return # redis fix

  context 'when the request is successful', ->
    beforeEach ->
      async.forever (next) =>
        @jobManager.getRequest ['request'], (error, @jobRequest) =>
          next @jobRequest
          return unless @jobRequest?

          response =
            metadata:
              code: 201
              metrics: @jobRequest.metadata.metrics
              jobLogs: @jobRequest.metadata.jobLogs
              responseId: @jobRequest.metadata.responseId

          @jobManager.createResponse 'response', response, (error) =>
            throw error if error?

    beforeEach (done) ->
      options =
        auth:
          username: 'irritable-captian'
          password: 'poop-deck'
        json:
          motion: true

      request.post "http://localhost:#{@port}/broadcasts", options, (error, @response) =>
        done error

    it 'should return a 201', ->
      expect(@response.statusCode).to.equal 201

    it 'should submit the correct job type', ->
      expect(@jobRequest.metadata.jobType).to.equal 'SendMessage'

    it 'should set the correct auth data', ->
      expect(@jobRequest.metadata.auth).to.deep.equal uuid: 'irritable-captian', token: 'poop-deck'

    it 'should send the correct broadcast', ->
      broadcast = JSON.parse @jobRequest.rawData
      expect(broadcast).to.containSubset devices: ['*'], motion: true

    it 'should log the broadcast', (done) ->
      @jobLogClient.llen 'meshblu:job-log', (error, count) =>
        return done error if error?
        expect(count).to.equal 1
        done()
      return # redis fix

    it 'should log the attempt and success of the broadcast', (done) ->
      @jobLogClient.lindex 'meshblu:job-log', 0, (error, jobStr) =>
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


  context 'when the user posts a broadcast that is not json', ->
    beforeEach (done) ->
      options =
        auth:
          username: 'irritable-captian'
          password: 'poop-deck'
        json: ['some-random-nonsense']
      request.post "http://localhost:#{@port}/broadcasts", options, (error, @response) =>
        done error

    it 'should return a 422', ->
      expect(@response.statusCode).to.equal 422

  context 'when the request is unsuccessful', ->
    beforeEach ->
      async.forever (next) =>
        @jobManager.getRequest ['request'], (error, @jobRequest) =>
          next @jobRequest
          return unless @jobRequest?

          response =
            metadata:
              code: 506
              responseId: @jobRequest.metadata.responseId

          @jobManager.createResponse 'response', response, (error) =>
            throw error if error?

    beforeEach (done) ->
      options =
        auth:
          username: 'irritable-captian'
          password: 'poop-deck'
        json:
          devices: ['*']

      request.post "http://localhost:#{@port}/broadcasts", options, (error, @response) =>
        done error

    it 'should return a 506', ->
      expect(@response.statusCode).to.equal 506

    it 'should submit the correct job type', ->
      expect(@jobRequest.metadata.jobType).to.equal 'SendMessage'

    it 'should set the correct auth data', ->
      expect(@jobRequest.metadata.auth).to.deep.equal uuid: 'irritable-captian', token: 'poop-deck'

    it 'should send the correct broadcast', ->
      broadcast = JSON.parse @jobRequest.rawData
      expect(broadcast).to.deep.equal devices: ['*']

    it 'should log the broadcast', (done) ->
      @jobLogClient.llen 'meshblu:job-log', (error, count) =>
        return done error if error?
        expect(count).to.equal 2
        done()
      return # redis fix

    it 'should log the attempt and success of the broadcast', (done) ->
      @jobLogClient.lindex 'meshblu:job-log', 0, (error, jobStr) =>
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
