MessagesController = require '../src/controllers/messages-controller'
redis = require 'fakeredis'

describe 'MessagesController', ->
  beforeEach ->
    @client = redis.createClient()
    @res =
      status: sinon.spy => @res
      end: sinon.spy => @res
    @sut = new MessagesController client: @client

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
