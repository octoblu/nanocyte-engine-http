_ = require 'lodash'
debug = require('debug')('nanocyte-engine-http:messages-controller')

class MessagesController
  constructor: ({ @client, @maxQueueLength }={}) ->
    @maxQueueLength ?= 1000
    debug 'using maxQueueLength', 1000

  _checkMaxQueueLength: ({requestQueue}, callback) =>
    @client.llen requestQueue, (error, queueLength) =>
      return callback error if error?
      return callback() if queueLength <= @maxQueueLength

      error = new Error 'Maximum Capacity Exceeded'
      error.code = 503
      callback error

  create: (req, res) =>
    unless req.header('X-MESHBLU-UUID') == req.params.flowId
      return res.status(403).end()

    {flowId, instanceId} = req.params
    message           = req.body ? {}

    forwardedRoutes   = @_parseIfPossible req.header 'X-MESHBLU-FORWARDED-ROUTES'
    route             = @_parseIfPossible(req.header 'X-MESHBLU-ROUTE') || [type: 'broadcast.sent', from: message.fromUuid]

    message.fromUuid ?= @_getFromUuidFromRoute route

    @client.get "request-queue-name:#{flowId}", (error, requestQueue) =>
      console.error error.stack if error?
      return res.status(500).send() if error?

      requestQueue ?= 'request:queue'

      return res.status(423).end() if requestQueue == 'request:blackhole'

      @_checkMaxQueueLength {requestQueue}, (error) =>
        return res.status(error.code).send(error) if error?

        envelope =
          message: message
          metadata:
            flowId: flowId
            instanceId: instanceId
            toNodeId: 'engine-input'
            fromUuid: message.fromUuid # fromUuid must be both in envelope.metadata.fromUuid and  envelope.message.fromUuid
            metadata:
              route: route
              forwardedRoutes: forwardedRoutes

        envelopeStr = JSON.stringify envelope
        debug '@client.lpush', requestQueue, envelopeStr
        @client.lpush requestQueue, envelopeStr, (error) =>
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
