Subscriber = require '../../src/models/subscriber'
redis      = require 'fakeredis'
uuid       = require 'uuid'
async      = require 'async'
_          = require 'lodash'
JobManager = require 'meshblu-core-job-manager'

describe 'Subscriber', ->
  beforeEach ->
    @redisId = uuid.v4()
    @client = redis.createClient @redisId
    @uuid = v4: sinon.stub()
    @dependencies = uuid: @uuid

    @sut = new Subscriber client: redis.createClient(@redisId), timeoutSeconds: 1, @dependencies
    @jobManager = new JobManager client: @client, timeoutSeconds: 1

  describe '->getSubscriptions', ->
    describe 'when called', ->
      beforeEach ->
        @uuid.v4.returns 'overly-affectionate-octopus'
        request =
          auth: {uuid: 'sucked-out-of', token: 'skyscraper-window'}
          fromUuid: 'winter'
          toUuid: 'rust'

        @onResponse = sinon.spy()

        @sut.getSubscriptions request, @onResponse

      describe 'when the request is popped from the request queue', ->
        beforeEach (done) ->
          @jobManager.getRequest ['request'], (error, @request) => done error

        it 'should create a record in the redis queue', ->
          expect(@request.metadata).to.deep.equal
            auth: {uuid: 'sucked-out-of', token: 'skyscraper-window'}
            fromUuid: 'winter'
            toUuid: 'rust'
            responseId: 'overly-affectionate-octopus'

      describe 'when the response is a 200 with an owl of data', ->
        beforeEach (done) ->
          response =
            responseId: 'overly-affectionate-octopus'
            metadata:
              code: 200
              status: 'OK'
            rawData: '[{},{}]'
          @jobManager.createResponse 'response', response, done

        it 'should yield the response', (done) ->
          responseCalled = => @onResponse.called
          wait = (callback) => _.delay callback, 10

          async.until responseCalled, wait, =>
            expect(@onResponse).to.have.been.calledWith null,
              code: 200
              status: 'OK'
              data: [{},{}]
            done()

      describe 'when the response is a 403 with no data', ->
        beforeEach (done) ->
          response =
            responseId: 'overly-affectionate-octopus'
            metadata:
              code: 403
              status: 'Forbidden'
            rawData: 'null'
          @jobManager.createResponse 'response', response, done

        it 'should yield the response', (done) ->
          responseCalled = => @onResponse.called
          wait = (callback) => _.delay callback, 10

          async.until responseCalled, wait, =>
            expect(@onResponse).to.have.been.calledWith null,
              code: 403
              status: 'Forbidden'
              data: null
            done()

      describe 'when the response never happened', ->
        it 'should yield an error', (done) ->
          responseCalled = => @onResponse.called
          wait = (callback) => _.delay callback, 10

          async.until responseCalled, wait, =>
            [error] = @onResponse.firstCall.args
            expect(=> throw error).to.throw 'Response timeout exceeded'
            done()

    describe 'when called without a fromUuid', ->
      beforeEach ->
        @uuid.v4.returns 'shark'
        request =
          auth: {uuid: 'what-a-week', token: 'shopping-frenzy'}
          fromUuid: undefined
          toUuid: 'rust'

        @sut.getSubscriptions request, =>

      describe 'when the request is popped from the request queue', ->
        beforeEach (done) ->
          @jobManager.getRequest ['request'], (error, @request) => done error

        it 'should create a record in the redis queue', ->
          expect(@request.metadata).to.deep.equal
            auth: {uuid: 'what-a-week', token: 'shopping-frenzy'}
            fromUuid: 'what-a-week'
            toUuid: 'rust'
            responseId: 'shark'
