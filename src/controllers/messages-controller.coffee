_ = require 'lodash'
debug = require('debug')('nanocyte-engine-http:messages-controller')

class MessagesController
  constructor: ({@client}={}) ->

  create: (req, res) =>
    unless req.header('X-MESHBLU-UUID') == req.params.flowId
      return res.status(403).end()

    {flowId, instanceId} = req.params

    route           = @_parseIfPossible req.header 'X-MESHBLU-ROUTE'
    forwardedRoutes = @_parseIfPossible req.header 'X-MESHBLU-FORWARDED-ROUTES'

    message  = req.body ? {}
    message.fromUuid ?= @_getFromUuidFromRoute route

    envelope =
      metadata:
        flowId: flowId
        instanceId: instanceId
        toNodeId: 'engine-input'
        fromUuid: message.fromUuid # fromUuid must be both in envelope.metadata.fromUuid and  envelope.message.fromUuid
        metadata:
          route: route
          forwardedRoutes: forwardedRoutes
      message: message

    envelopeStr = JSON.stringify envelope

    @client.get "request-queue-name:#{flowId}", (error, requestQueueName) =>
      requestQueueName ?= 'request:queue'

      return res.status(423).end() if requestQueueName == 'request:blackhole'

      debug '@client.lpush', requestQueueName, envelopeStr
      @client.lpush requestQueueName, envelopeStr, (error) =>
        console.error error.message if error?
        return res.status(500).send(error) if error?

        res.status(201).end()

  _getFromUuidFromRoute: (route) =>
    hop = _.first route
    return hop.from if hop?

  _parseIfPossible: (str) =>
    return unless str
    try
      JSON.parse str

module.exports = MessagesController
