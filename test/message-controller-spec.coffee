MessagesController = require '../src/controllers/messages-controller'
redis = require 'fakeredis'
{beforeEach,context,describe,it} = global
sinon = require 'sinon'
{expect} = require 'chai'

describe 'MessagesController', ->
  beforeEach ->
    @client = redis.createClient()
    @res =
      status: sinon.spy => @res
      end: sinon.spy => @res
    @sut = new MessagesController client: @client, maxQueueLength: 1

  context 'when given a non-matching flowid', ->
    beforeEach (done) ->
      req =
        header: sinon.stub()
        params:
          flowId: 'marshmallow'

      @res.end = => done()

      req.header.withArgs('X-MESHBLU-UUID').returns 'pickles'

      @sut.create req, @res

    it 'should send a 403', ->
      expect(@res.status).to.have.been.calledWith 403

  context 'when given a matching flowid', ->
    beforeEach (done) ->
      req =
        header: sinon.stub()
        params:
          flowId: 'sour'

      req.header.withArgs('X-MESHBLU-UUID').returns 'sour'
      @res.end = => done()

      @sut.create req, @res

    it 'should send a 201', ->
      expect(@res.status).to.have.been.calledWith 201

  context 'when given a blackholed flowid', ->
    beforeEach (done) ->
      @client.set 'request-queue-name:blocked', 'request:blackhole', done

    beforeEach (done) ->
      req =
        header: sinon.stub()
        params:
          flowId: 'blocked'

      req.header.withArgs('X-MESHBLU-UUID').returns 'blocked'
      @res.end = => done()

      @sut.create req, @res

    it 'should send a 423', ->
      expect(@res.status).to.have.been.calledWith 423

  context 'when max-queue-length is exceeded', ->
    beforeEach (done) ->
      @client.lpush 'request:queue', 'foo', done

    beforeEach (done) ->
      @client.lpush 'request:queue', 'foo', done

    beforeEach (done) ->
      req =
        header: sinon.stub()
        params:
          flowId: 'exceeded'

      req.header.withArgs('X-MESHBLU-UUID').returns 'exceeded'
      @res.send = => done()
      @sut.create req, @res

    it 'should send a 503', ->
      expect(@res.status).to.have.been.calledWith 503

  context 'when given a x-meshblu-route header', ->
    beforeEach (done) ->
      req =
        header: sinon.stub()
        params:
          flowId: 'sour'
        body: {devices: ['*']}

      req.header.withArgs('X-MESHBLU-UUID').returns 'sour'
      req.header.withArgs('X-MESHBLU-ROUTE').returns JSON.stringify [from: 'abcd']
      @res.end = => done()

      @sut.create req, @res

    it 'should send a 201', ->
      expect(@res.status).to.have.been.calledWith 201

    it 'should use the first hop "from" as the fromUuid', (done) ->
      expectedJob =
        metadata:
          flowId:'sour'
          toNodeId:'engine-input'
          fromUuid: 'abcd'
          metadata:
            route: [{from: 'abcd'}]
        message:
          devices: ['*']
          fromUuid: 'abcd'

      @client.rpop 'request:queue', (error, job) =>
        return done error if error?
        expect(JSON.parse job).to.deep.equal expectedJob
        done()

  context 'when given a x-meshblu-forwarded-routes header', ->
    beforeEach (done) ->
      req =
        header: sinon.stub()
        params:
          flowId: 'sour'
        body: {
          devices: ['*']
          fromUuid: 'from-uuid'
        }

      req.header.withArgs('X-MESHBLU-UUID').returns 'sour'
      req.header.withArgs('X-MESHBLU-FORWARDED-ROUTES').returns JSON.stringify [[{from: 'abcd'}]]
      req.header.withArgs('X-MESHBLU-ROUTE').returns JSON.stringify [{from: 'abcd', type: 'configure.received'}]
      @res.end = => done()

      @sut.create req, @res

    it 'should send a 201', ->
      expect(@res.status).to.have.been.calledWith 201

    it 'should add the message to redis', (done) ->
      expectedJob =
        metadata:
          flowId:'sour'
          toNodeId:'engine-input'
          fromUuid: 'from-uuid'
          metadata:
            route: [{from: 'abcd', type: 'configure.received'}]
            forwardedRoutes: [[{from: 'abcd'}]]
        message:
          devices: ['*']
          fromUuid: 'from-uuid'

      @client.rpop 'request:queue', (error, job) =>
        return done error if error?
        expect(JSON.parse job).to.deep.equal expectedJob
        done()
