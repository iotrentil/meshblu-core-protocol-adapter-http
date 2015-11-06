Authenticator = require '../../src/models/authenticator'
JobManager = require 'meshblu-core-job-manager'
async      = require 'async'
redis      = require 'fakeredis'
RedisNS    = require '@octoblu/redis-ns'
_          = require 'lodash'
uuid       = require 'uuid'

describe 'Authenticator', ->
  beforeEach ->
    @redis = new RedisNS 'some-ns', redis.createClient()
    @redis = _.bindAll @redis

  beforeEach ->
    @uuid = v1: sinon.stub()
    @sut = new Authenticator {timeoutSeconds: 1, client: @redis}, uuid: @uuid
    @jobManager = new JobManager client: @redis, timeoutSeconds: 1

  describe '->authenticate', ->
    describe 'when redis replies with a 204', ->
      beforeEach (done) ->
        @uuid.v1.returns 'some-uuid'

        metadata =
          responseId: 'some-uuid'
          code: 204
          status: 'No Content'

        @jobManager.createResponse 'response', metadata: metadata, done

      beforeEach (done) ->
        @sut.authenticate 'uuid', 'token', (@error, @response) => done()

      it 'should no error', ->
        expect(@error).not.to.exist

      it 'should yield the response', ->
        expect(@response).to.deep.equal
          metadata:
            code: 204
            status: 'No Content'

      it 'should have added a request reference to the request queue', (done) ->
        @redis.lindex 'request:queue', 0, (error, result) =>
          return done error if error?

          expect(result).to.deep.equal 'some-uuid'
          done()

      it 'should have added a request metadata to the request hash set', (done) ->
        @redis.hget 'some-uuid', 'request:metadata', (error, metadataStr) =>
          return done error if error?

          metadata = JSON.parse metadataStr

          expect(metadata).to.deep.equal
            auth:
              uuid: "uuid"
              token: "token"
            responseId: "some-uuid"
            jobType: "Authenticate"

          done()

    describe 'when the auth worker replies with a 403', ->
      beforeEach (done) ->
        @uuid.v1.returns 'some-other-uuid'

        metadata =
          responseId: 'some-other-uuid'
          code: 403
          status: 'Forbidden'

        @jobManager.createResponse 'response', metadata: metadata, done

      beforeEach (done) ->
        @sut.authenticate 'uuid', 'token', (@error, @response) => done()

      it 'should no error', ->
        expect(@error).not.to.exist

      it 'should yield the response', ->
        expect(@response).to.deep.equal
          metadata:
            code: 403
            status: 'Forbidden'

      it 'should have added a job to the request queue', (done) ->
        @redis.lindex 'request:queue', 0, (error, requestKey) =>
          return done error if error?
          expect(requestKey).to.deep.equal 'some-other-uuid'
          done()

      it 'should have added a request metadata to the request hash set', (done) ->
        @redis.hget 'some-other-uuid', 'request:metadata', (error, metadataStr) =>
          return done error if error?

          metadata = JSON.parse metadataStr

          expect(metadata).to.deep.equal
            auth:
              uuid: "uuid"
              token: "token"
            responseId: "some-other-uuid"
            jobType: "Authenticate"

          done()

    describe 'when the auth worker never replies', ->
      beforeEach (done) ->
        @timeout 3000
        @sut.authenticate 'uuid', 'token', (@error, @isAuthenticated) => done()

      it 'should error', ->
        expect(@isAuthenticated).not.to.exist
        expect(=> throw @error).to.throw 'No response from authenticate worker'
