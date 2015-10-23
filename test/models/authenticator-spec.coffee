Authenticator = require '../../src/models/authenticator'
async = require 'async'
redis = require 'redis'

describe 'Authenticator', ->
  beforeEach ->
    @redis = redis.createClient
      host: process.env.REDIS_HOST
      port: process.env.REDIS_PORT

  beforeEach ->
    @uuid = v1: sinon.stub()
    @sut = new Authenticator {namespace: 'test', timeoutSeconds: 1}, uuid: @uuid

  describe '->authenticate', ->
    beforeEach (done) ->
      async.parallel [
        (callback) => @redis.del 'test:response:some-uuid', callback
        (callback) => @redis.del 'test:response:some-other-uuid', callback
        (callback) => @redis.del 'test:request:queue', callback
      ], done

    describe 'when redis replies with true', ->
      beforeEach (done) ->
        @uuid.v1.returns 'some-uuid'
        @sut.authenticate 'uuid', 'token', (@error, @isAuthenticated) => done()
        @redis.lpush 'test:response:some-uuid', JSON.stringify([null, authenticated: true])

      it 'should no error', ->
        expect(@error).not.to.exist

      it 'should yield true', ->
        expect(@isAuthenticated).to.be.true

      it 'should have added a job to the authenticate queue', (done) ->
        @redis.lindex 'test:request:queue', 0, (error, result) =>
          return done error if error?
          job = JSON.parse(result)

          expect(job).to.deep.equal
            uuid: 'uuid'
            token: 'token'
            responseUuid: 'some-uuid'
          done()

    describe 'when the auth worker replies with false', ->
      beforeEach (done) ->
        @uuid.v1.returns 'some-other-uuid'
        @sut.authenticate 'uuid', 'token', (@error, @isAuthenticated) => done()
        @redis.lpush 'test:response:some-other-uuid', JSON.stringify([null, authenticated: false])

      it 'should no error', ->
        expect(@error).not.to.exist

      it 'should yield false', ->
        expect(@isAuthenticated).to.be.false

      it 'should have added a job to the authenticate queue', (done) ->
        @redis.lindex 'test:request:queue', 0, (error, result) =>
          return done error if error?
          job = JSON.parse(result)

          expect(job).to.deep.equal
            uuid: 'uuid'
            token: 'token'
            responseUuid: 'some-other-uuid'
          done()

    describe 'when the auth worker replies with an error', ->
      beforeEach (done) ->
        @uuid.v1.returns 'some-uuid'
        @sut.authenticate 'uuid', 'token', (@error, @isAuthenticated) => done()
        @redis.lpush 'test:response:some-uuid', JSON.stringify([message: 'uh oh'])

      it 'should error', ->
        expect(=> throw @error).to.throw 'uh oh'

    describe 'when the auth worker never replies', ->
      beforeEach (done) ->
        @sut.authenticate 'uuid', 'token', (@error, @isAuthenticated) => done()

      it 'should error', ->
        expect(=> throw @error).to.throw 'No response from authenticate worker'
