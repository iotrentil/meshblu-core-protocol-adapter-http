{EventEmitter} = require 'events'
redis = require 'fakeredis'
uuid = require 'uuid'
httpMocks      = require 'node-mocks-http'
JobManager = require 'meshblu-core-job-manager'
SubscriptionsController = require '../../src/controllers/subscriptions-controller'

describe 'SubscriptionsController', ->
  beforeEach ->
    @redisId = uuid.v4()
    @client = redis.createClient @redisId
    @dependencies = uuid: @uuid

    @sut = new SubscriptionsController timeoutSeconds: 1
    @jobManager = new JobManager client: @client, timeoutSeconds: 1

  describe '->getAll', ->
    describe 'when called with a request', ->
      beforeEach ->
        basicAuth = new Buffer("wrong:person").toString 'base64'
        @request  = httpMocks.createRequest
          headers:
            authorization: "Basic #{basicAuth}"
            'X-As': 'pothole'
          params: {uuid: 'destination'}
        @request.connection = redis.createClient @redisId

        @response = httpMocks.createResponse eventEmitter: EventEmitter

        @sut.getAll @request, @response

      describe 'when the response is a success', ->
        beforeEach (done) ->
          @response.on 'end', done

          @jobManager.getRequest ['request'], (error, @internalRequest) =>
            return done error if error?
            return done new Error('no request') unless @internalRequest?
            options =
              responseId: @internalRequest.metadata.responseId
              metadata:
                code: 200
              data: [{},{}]

            @jobManager.createResponse 'response', options, =>

        it 'should create a formatted internal request', ->
          expect(@internalRequest).to.containSubset
            metadata:
              auth: {uuid: 'wrong', token: 'person'}
              fromUuid: 'pothole'
              toUuid: 'destination'
              jobType: "SubscriptionList"
            rawData: 'null'

        it 'should respond with a 200', ->
          expect(@response.statusCode).to.equal 200
