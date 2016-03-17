_ = require 'lodash'
request = require 'request'
Server = require '../../src/server'
async      = require 'async'
redis      = require 'redis'
RedisNS    = require '@octoblu/redis-ns'
JobManager = require 'meshblu-core-job-manager'

describe 'Authenticate', ->
  beforeEach (done) ->
    @port = 0xd00d
    @sut = new Server
      port: @port
      disableLogging: true
      jobTimeoutSeconds: 1
      namespace:   'meshblu:server:http:test'
      jobLogQueue: 'meshblu:job-log'
      jobLogRedisUri: 'redis://localhost:6379'
      meshbluHost: 'localhost'
      meshbluPort: 3000

    @sut.run done

  afterEach (done) ->
    @sut.stop => done()

  beforeEach ->
    @redis = _.bindAll new RedisNS 'meshblu:server:http:test', redis.createClient()
    @jobManager = new JobManager client: @redis, timeoutSeconds: 1

  describe 'POST /authenticate', ->
    context 'when the request is successful', ->
      beforeEach ->
        async.forever (next) =>
          @jobManager.getRequest ['request'], (error, request) =>
            next request
            return unless request?
            @request = request

            response =
              metadata:
                code: 204
                responseId: request.metadata.responseId

            @jobManager.createResponse 'response', response, (error) =>
              throw error if error?

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
        async.forever (next) =>
          @jobManager.getRequest ['request'], (error, request) =>
            next request
            return unless request?
            @request = request

            response =
              metadata:
                code: 204
                responseId: @request.metadata.responseId

            @jobManager.createResponse 'response', response, (error) =>
              throw error if error?

      beforeEach (done) ->
        options =
          auth:
            username: 'irritable-captian'
            password: 'poop-deck'

        request.get "http://localhost:#{@port}/authenticate/some-uuid", options, (error, @response) =>
          done error

      it 'should have jobType Authenticate', ->
        expect(@request.metadata.jobType).to.equal 'Authenticate'

      it 'should have auth correct', ->
        expect(@request.metadata.auth).to.deep.equal uuid: 'irritable-captian', token: 'poop-deck'

      it 'should have the toUuid of some-uuid', ->
        expect(@request.metadata.toUuid).to.equal 'some-uuid'

      it 'should return a 204', ->
        expect(@response.statusCode).to.equal 204
