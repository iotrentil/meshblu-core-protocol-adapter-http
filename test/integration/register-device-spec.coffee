_          = require 'lodash'
request    = require 'request'
Server     = require '../../src/server'
async      = require 'async'
redis      = require 'redis'
RedisNS    = require '@octoblu/redis-ns'
JobManager = require 'meshblu-core-job-manager'

describe 'POST /devices', ->
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

  context 'when the request is successful', ->
    beforeEach ->
      async.forever (next) =>
        @jobManager.getRequest ['request'], (error, request) =>
          next request
          return unless request?
          @request = request

          response =
            metadata:
              code: 201
              responseId: request.metadata.responseId
            rawData: '{"uuid":"boxes-of-stuff","token":"secret-boxes-of-stuff"}'

          @jobManager.createResponse 'response', response, (error) =>
            throw error if error?

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
      async.forever (next) =>
        @jobManager.getRequest ['request'], (error, request) =>
          next request
          return unless request?
          @request = request

          response =
            metadata:
              code: 201
              responseId: request.metadata.responseId
            rawData: '{"uuid":"boxes-of-stuff","token":"secret-boxes-of-stuff","discoverWhitelist":["owner-uuid"],"configureWhitelist":["owner-uuid"]}'

          @jobManager.createResponse 'response', response, (error) =>
            throw error if error?

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
