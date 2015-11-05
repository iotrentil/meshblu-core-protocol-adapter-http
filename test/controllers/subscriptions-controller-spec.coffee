{EventEmitter} = require 'events'
httpMocks      = require 'node-mocks-http'
SubscriptionsController = require '../../src/controllers/subscriptions-controller'

describe 'SubscriptionsController', ->
  describe 'authenticate', ->
    beforeEach ->
      @subscriber = getSubscriptions: sinon.mock()
      @sut = new SubscriptionsController {}, subscriber:@subscriber

    describe 'when subscriptions.getSubscriptions yields 403 for a request', ->
      beforeEach ->
        response =
          code: 403
          status: 'Forbidden'
        request =
          auth: {uuid: 'wrong', token: 'person'}
          toUuid: 'hang-glider'
          fromUuid: undefined

        @subscriber.getSubscriptions.withArgs(request).yields null, response

      describe 'when called with a request containing incorrect auth information', ->
        beforeEach (done) ->
          basicAuth = new Buffer("wrong:person").toString 'base64'
          @request  = httpMocks.createRequest
            headers: authorization: "Basic #{basicAuth}"
            params:
              uuid: 'hang-glider'
          @response = httpMocks.createResponse eventEmitter: EventEmitter
          @response.on 'end', done

          @sut.getAll @request, @response

        it 'should respond with a 403', ->
          expect(@response.statusCode).to.equal 403

        it 'should respond with an empty body', ->
          expect(@response._getData()).to.be.empty

    describe 'when subscriber.getSubscriptions yields subscriptions', ->
      beforeEach ->
        request =
          auth: {uuid: 'right', token: 'person'}
          toUuid: 'serial-killer'
          fromUuid: 'dodgy-pub'

        response =
          code: 200
          status: 'OK'
          data: []

        @subscriber.getSubscriptions.withArgs(request).yields null, response

      describe 'when called with a request containing correct auth information', ->
        beforeEach (done) ->
          basicAuth = new Buffer("right:person").toString 'base64'

          @request  = httpMocks.createRequest
            headers:
              authorization: "Basic #{basicAuth}"
              'X-as': 'dodgy-pub'
            params:
              uuid: 'serial-killer'

          @response = httpMocks.createResponse eventEmitter: EventEmitter
          @response.on 'end', done

          @sut.getAll @request, @response

        it 'should respond with a 200', ->
          expect(@response.statusCode).to.equal 200

        it 'should respond with the empty subsriptions', ->
          data = JSON.parse @response._getData()
          expect(data).to.deep.equal []

    describe 'when subscriber.getSubscriptions yields an error', ->
      beforeEach ->
        request =
          auth: {uuid: 'fatal', token: 'error'}
          toUuid: 'goose'
          fromUuid: undefined
        @subscriber.getSubscriptions.withArgs(request).yields new Error("oh no!")

      describe 'when called with a request containing auth information', ->
        beforeEach (done) ->
          basicAuth = new Buffer("fatal:error").toString 'base64'
          @request  = httpMocks.createRequest
            headers: authorization: "Basic #{basicAuth}"
            params:
              uuid: 'goose'

          @response = httpMocks.createResponse eventEmitter: EventEmitter
          @response.on 'end', done

          @sut.getAll @request, @response

        it 'should respond with a 502', ->
          expect(@response.statusCode).to.equal 502
