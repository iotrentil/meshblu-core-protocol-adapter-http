{EventEmitter} = require 'events'
httpMocks      = require 'node-mocks-http'
AuthenticateController = require '../../src/controllers/authenticate-controller'

describe 'AuthenticateController', ->
  describe 'authenticate', ->
    beforeEach ->
      @authenticator = authenticate: sinon.stub()
      @sut = new AuthenticateController {}, authenticator: @authenticator

    describe 'when authenticator.authenticate yields 403 for a specific device', ->
      beforeEach ->
        authResponse = metadata: {code: 403, status: 'Forbidden'}
        @authenticator.authenticate.withArgs('wrong', 'person').yields null, authResponse

      describe 'when called with a request containing auth information', ->
        beforeEach (done) ->
          basicAuth = new Buffer("wrong:person").toString 'base64'
          @request  = httpMocks.createRequest headers: authorization: "Basic #{basicAuth}"
          @response = httpMocks.createResponse eventEmitter: EventEmitter
          @response.on 'end', done

          @sut.authenticate @request, @response

        it 'should respond with a 403', ->
          expect(@response.statusCode).to.equal 403

    describe 'when authenticator.authenticate yields code 204 for a request', ->
      beforeEach ->
        authResponse = metadata: {code: 204, status: 'No Content'}
        @authenticator.authenticate.withArgs('uuid', 'token').yields null, authResponse

      describe 'when called with a request containing incorrect auth information', ->
        beforeEach (done) ->
          basicAuth = new Buffer("uuid:token").toString 'base64'
          @request  = httpMocks.createRequest headers: authorization: "Basic #{basicAuth}"
          @response = httpMocks.createResponse eventEmitter: EventEmitter
          @response.on 'end', done

          @sut.authenticate @request, @response

        it 'should respond with a 204', ->
          expect(@response.statusCode).to.equal 204

    describe 'when authenticator.authenticate yields an error', ->
      beforeEach ->
        @authenticator.authenticate.withArgs('fatal', 'error').yields new Error("oh no!")

      describe 'when called with a request containing auth information', ->
        beforeEach (done) ->
          basicAuth = new Buffer("fatal:error").toString 'base64'
          @request  = httpMocks.createRequest headers: authorization: "Basic #{basicAuth}"
          @response = httpMocks.createResponse eventEmitter: EventEmitter
          @response.on 'end', done

          @sut.authenticate @request, @response

        it 'should respond with a 502', ->
          expect(@response.statusCode).to.equal 502
