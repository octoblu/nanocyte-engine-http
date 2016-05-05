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

    body  = req.body ? {}
    body.fromUuid ?= @_getFromUuidFromRoute route

    message =
      metadata:
        flowId: flowId
        instanceId: instanceId
        toNodeId: 'engine-input'
        fromUuid: body.fromUuid # fromUuid must be both in message.metadata.fromUuid and  message.message.fromUuid
        route: route
        forwardedRoutes: forwardedRoutes
      message: body

    messageStr = JSON.stringify message

    @client.get "request-queue-name:#{flowId}", (error, requestQueueName) =>
      requestQueueName ?= 'request:queue'

      debug '@client.lpush', requestQueueName, messageStr
      @client.lpush requestQueueName, messageStr, (error) =>
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
