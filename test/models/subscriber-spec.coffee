Subscriber = require '../../src/models/subscriber'
redis      = require 'fakeredis'
uuid       = require 'uuid'
async      = require 'async'

describe 'Subscriber', ->
  beforeEach ->
    @redisId = uuid.v4()
    @client = redis.createClient @redisId
    @sut = new Subscriber client: redis.createClient(@redisId)

  describe '->getSubscriptions', ->
    describe 'when called', ->
      beforeEach ->
        request =
          metadata:
            auth: {uuid: 'sucked-out-of', token: 'skyscraper-window'}
            asUuid: 'rust'
            targetUuid: 'winter'

        @sut.getSubscriptions request, (error) => throw error if error?

      it 'should create a record in the redis queue', (done) ->
        amDone = false
        async.until (=> amDone), (next) =>
          @client.llen 'request:queue', (error, llen) =>
            return next error if error?
            amDone = (llen == 1)
            next()
        , done

      xdescribe 'has no subscriptions', ->
        beforeEach (done) ->

        it 'should yield subscriptions', ->
          expect(@response).to.containSubset
            data: []

        it 'should yield a 200, OK', ->
          expect(@response).to.containSubset
            metadata:
              code: 200
              status: 'OK'

    xdescribe 'when called and has subscriptions', ->
      beforeEach (done) ->
        request =
          metadata:
            auth:
              uuid: 'mistaken'
              token: 'identity'
            asUuid: 'had-a'
            targetUuid: 'twin'

        @sut.getSubscriptions request, (error, @response) => done error

      it 'should not yeild an subscriptions', ->
        expect(@response).to.containSubset
          data: [
            {type: 'rockslide'}
          ]

      it 'should yield a 200, OK', ->
        expect(@response).to.containSubset
          metadata:
            code: 200
            status: 'OK'
