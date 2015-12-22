_ = require 'lodash'
request = require 'request'
Server = require '../../src/server'
async      = require 'async'
redis      = require 'redis'
RedisNS    = require '@octoblu/redis-ns'
JobManager = require 'meshblu-core-job-manager'

describe 'GET /v2/devices/:uuid', ->
  beforeEach (done) ->
    @port = 0xd00d
    @sut = new Server
      port: @port
      disableLogging: true
      jobTimeoutSeconds: 1
      namespace: 'meshblu:server:http:test'

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
              name: 'koshin'
            data:
              uuid: 'secret-island'

          @jobManager.createResponse 'response', response

    beforeEach (done) ->
      options =
        auth:
          username: 'irritable-captian'
          password: 'poop-deck'

        headers:
          'x-as': 'treasure-map'

      request.get "http://localhost:#{@port}/v2/devices/secret-island", options, (error, @response, @body) =>
        done error

    it 'should return a 200', ->
      expect(@response.statusCode).to.equal 200

    it 'should have the device in the body', ->
      expect(JSON.parse(@body)).to.contain uuid: 'secret-island'

    it 'should have the metadata in the headers', ->
      expect(@response.headers).to.containSubset
        'x-meshblu-code': '200'
        'x-meshblu-name': 'koshin'
