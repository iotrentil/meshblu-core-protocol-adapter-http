{EventEmitter} = require 'events'
redis          = require 'fakeredis'
RedisNS        = require '@octoblu/redis-ns'
uuid           = require 'uuid'
httpMocks      = require 'node-mocks-http'
JobManager     = require 'meshblu-core-job-manager'
WhoamiController = require '../../src/controllers/whoami-controller'

describe 'WhoamiController', ->
  beforeEach ->
    @redisId = uuid.v4()
    @client = new RedisNS 'nsNamespaceWithNamespace', redis.createClient(@redisId)
    @dependencies = uuid: @uuid

    @sut = new WhoamiController timeoutSeconds: 1
    @jobManager = new JobManager client: @client, timeoutSeconds: 1

  describe '->whoami', ->
    describe 'when called with a request', ->
      beforeEach ->
        basicAuth = new Buffer("wrong:person").toString 'base64'
        @request  = httpMocks.createRequest
          headers:
            authorization: "Basic #{basicAuth}"
            'x-as': 'wrong'
          params: {uuid: 'destination'}
        @request.connection = new RedisNS 'nsNamespaceWithNamespace', redis.createClient(@redisId)

        @response = httpMocks.createResponse eventEmitter: EventEmitter

        @sut.whoami @request, @response

      describe 'when the response is a success', ->
        beforeEach (done) ->
          @response.on 'end', done

          @jobManager.getRequest ['request'], (error, @internalRequest) =>
            return done error if error?
            return done new Error('no request') unless @internalRequest?
            options =
              metadata:
                responseId: @internalRequest.metadata.responseId
                code: 200

            @jobManager.createResponse 'response', options, =>

        it 'should create a formatted internal request', ->
          expect(@internalRequest).to.containSubset
            metadata:
              auth: {uuid: 'wrong', token: 'person'}
              fromUuid: 'wrong'
              toUuid: 'wrong'
              jobType: 'GetDevice'
            rawData: 'null'

        it 'should respond with a 200', ->
          expect(@response.statusCode).to.equal 200
