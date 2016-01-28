_ = require 'lodash'
request = require 'request'
Server = require '../../src/server'
async      = require 'async'
redis      = require 'redis'
RedisNS    = require '@octoblu/redis-ns'
JobManager = require 'meshblu-core-job-manager'

describe 'GET /v3/devices/:uuid', ->
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

  context 'when the request is successful', ->
    beforeEach ->
      async.forever (next) =>
        @jobManager.getRequest ['request'], (error, @jobRequest) =>
          next @jobRequest
          return unless @jobRequest?

          response =
            metadata:
              code: 200
              responseId: @jobRequest.metadata.responseId
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
          'x-meshblu-as': 'treasure-map'

      request.get "http://localhost:#{@port}/v3/devices/secret-island", options, (error, @response, @body) =>
        done error

    it 'should return a 200', ->
      expect(@response.statusCode).to.equal 200

    it 'should have the device in the body', ->
      expect(JSON.parse(@body)).to.contain uuid: 'secret-island'

    it 'should have set the fromUuid correctly', ->
      expect(@jobRequest.metadata.fromUuid).to.equal 'treasure-map'

    it 'should have set the toUuid correctly', ->
      expect(@jobRequest.metadata.toUuid).to.equal 'secret-island'

    it 'should have set the auth correctly', ->
      expect(@jobRequest.metadata.auth).to.deep.equal
        uuid: 'irritable-captian'
        token: 'poop-deck'

    it 'should have the metadata in the headers', ->
      expect(@response.headers).to.containSubset
        'x-meshblu-code': '200'
        'x-meshblu-name': 'koshin'
        'x-meshblu-response-id': @jobRequest.metadata.responseId
