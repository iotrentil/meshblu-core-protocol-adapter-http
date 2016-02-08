_ = require 'lodash'
request = require 'request'
Server = require '../../src/server'
async      = require 'async'
moment     = require 'moment'
redis      = require 'redis'
RedisNS    = require '@octoblu/redis-ns'
JobManager = require 'meshblu-core-job-manager'

describe 'POST /messages', ->
  beforeEach (done) ->
    @port = 0xd00d
    @sut = new Server
      port: @port
      disableLogging: true
      jobTimeoutSeconds: 1
      namespace: 'meshblu:server:http:test'
      jobLogQueue: 'meshblu:job-log'

    @sut.run done

  afterEach (done) ->
    @sut.stop => done()

  beforeEach ->
    @redis = _.bindAll new RedisNS 'meshblu:server:http:test', redis.createClient()
    @jobManager = new JobManager client: @redis, timeoutSeconds: 1

  beforeEach (done) ->
    @jobLogClient = redis.createClient()
    @jobLogClient.del 'meshblu:job-log', done

  context 'when the request is successful', ->
    beforeEach ->
      async.forever (next) =>
        @jobManager.getRequest ['request'], (error, @jobRequest) =>
          next @jobRequest
          return unless @jobRequest?

          response =
            metadata:
              code: 201
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
      @jobLogClient.llen 'meshblu:job-log', (error, count) =>
        return done error if error?
        expect(count).to.equal 1
        done()

    it 'should log the attempt and success of the message', (done) ->
      @jobLogClient.lindex 'meshblu:job-log', 0, (error, jobStr) =>
        return done error if error?
        todaySuffix = moment.utc().format('YYYY-MM-DD')
        index = "metric:meshblu-server-http-#{todaySuffix}"
        expect(JSON.parse jobStr).to.containSubset {
          "index": index
          "type": "meshblu-server-http:request"
          "body": {
            "request": {
              "metadata": {
                "auth": {
                  "token": "poop-deck"
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
