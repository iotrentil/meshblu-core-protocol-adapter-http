_ = require 'lodash'
request = require 'request'
Server = require '../../src/server'
async      = require 'async'
redis      = require 'redis'
RedisNS    = require '@octoblu/redis-ns'
JobManager = require 'meshblu-core-job-manager'

describe 'GET /status', ->
  beforeEach (done) ->
    @port = 0xd00d
    @sut = new Server
      port: @port
      disableLogging: true
      jobTimeoutSeconds: 1
      namespace:   'meshblu:server:http:test'
      jobLogQueue: 'meshblu:job-log'
      jobLogRedisUri: 'redis://localhost:6379'
      maxConnections: 10
      jobLogSampleRate: 10
      redisUri: 'redis://localhost'

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

          response =
            metadata:
              code: 200
              responseId: request.metadata.responseId
            rawData: '{"meshblu":"online"}'

          @jobManager.createResponse 'response', response, (error) =>
            throw error if error?

    beforeEach (done) ->
      options =
        json: true
      request.get "http://localhost:#{@port}/status", options, (error, @response, @body) =>
        done error

    it 'should return a 200', ->
      expect(@response.statusCode).to.equal 200

    it 'should return meshblu:online', ->
      expect(@body).to.deep.equal meshblu: 'online'
