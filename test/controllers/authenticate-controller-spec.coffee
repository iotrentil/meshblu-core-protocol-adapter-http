{EventEmitter} = require 'events'
httpMocks      = require 'node-mocks-http'
uuid           = require 'uuid'
redis          = require 'fakeredis'
RedisNS        = require '@octoblu/redis-ns'
JobManager     = require 'meshblu-core-job-manager'

AuthenticateController = require '../../src/controllers/authenticate-controller'

describe 'AuthenticateController', ->
  describe 'authenticate', ->
    beforeEach ->
      @redisId = uuid.v4()

      @jobManager = new JobManager
        client: new RedisNS('ns', redis.createClient(@redisId))
        timeoutSeconds: 1

      @sut = new AuthenticateController timeoutSeconds: 1, namespace: 'nvm'

    describe 'when called with a request containing auth information', ->
      beforeEach ->
        basicAuth = new Buffer("wrong:person").toString 'base64'

        @request  = httpMocks.createRequest headers: authorization: "Basic #{basicAuth}"
        @request.connection = new RedisNS 'ns', redis.createClient(@redisId)
        @response = httpMocks.createResponse eventEmitter: EventEmitter

        @sut.authenticate @request, @response

      describe 'when the request gets popped off the queue', ->
        beforeEach (done) ->
          @jobManager.getRequest ['request'], (error, @jobRequest) =>
            done error

        describe 'when meshblu yields 403 for a specific device', ->
          beforeEach (done) ->
            @response.on 'end', done

            options =
              metadata:
                responseId: @jobRequest.metadata.responseId
                code: 403

            @jobManager.createResponse 'response', options, =>

          it 'should respond with a 403', ->
            expect(@response.statusCode).to.equal 403

        describe 'when meshblu yields 204 for a specific device', ->
          beforeEach (done) ->
            @response.on 'end', done

            options =
              metadata:
                responseId: @jobRequest.metadata.responseId
                code: 204

            @jobManager.createResponse 'response', options, =>

          it 'should respond with a 204', ->
            expect(@response.statusCode).to.equal 204

        describe 'when meshblu never yields', ->
          beforeEach (done) ->
            @response.on 'end', done

          it 'should respond with a 502', ->
            expect(@response.statusCode).to.equal 502
