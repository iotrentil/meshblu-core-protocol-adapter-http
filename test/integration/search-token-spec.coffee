_ = require 'lodash'
request = require 'request'
Server = require '../../src/server'
async      = require 'async'
redis      = require 'ioredis'
RedisNS    = require '@octoblu/redis-ns'
JobManager = require 'meshblu-core-job-manager'

describe 'POST /search/tokens', ->
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
      jobLogSampleRate: 10
      redisUri: 'redis://localhost'

    @sut.run done

  afterEach (done) ->
    @sut.stop => done()

  beforeEach ->
    @redis = _.bindAll new RedisNS 'meshblu:server:http:test', redis.createClient(dropBufferSupport: true)
    @jobManager = new JobManager client: @redis, timeoutSeconds: 1, jobLogSampleRate: 1

  describe '->search', ->
    context 'when the request is successful', ->
      beforeEach ->
        async.forever (next) =>
          @jobManager.getRequest ['request'], (error, @request) =>
            next @request
            return unless @request?

            response =
              metadata:
                code: 200
                responseId: @request.metadata.responseId
                name: 'dinosaur-getter'
              data: [
                  {uuid: 't-rex'}
                  {uuid: 'megalodon'}
                  {uuid: 'killasaurus'}
              ]

            @jobManager.createResponse 'response', response, (error) =>
              throw error if error?

      beforeEach (done) ->
        options =
          auth:
            username: 'irritable-captian'
            password: 'poop-deck'
          json: type: 'dinosaur'

          headers:
            'x-meshblu-as': 'treasure-map'
            'x-meshblu-erik-feature': 'custom-headers'

        request.post "http://localhost:#{@port}/search/tokens", options, (error, @response, @body) =>
          done error

      it 'should return a 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should dispatch the correct metadata', ->
        expect(@request).to.containSubset
          metadata:
            fromUuid: 'treasure-map'
            erikFeature: 'custom-headers'
            auth:
              uuid: 'irritable-captian'
              token: 'poop-deck'

      it 'should send the search body as the data of the job', ->
        data = JSON.parse @request.rawData
        expect(data).to.containSubset type: 'dinosaur'

      it 'should have a tokens array in the response', ->
        expect(@body).to.be.an.array
        expect(@body.length).to.equal 3
