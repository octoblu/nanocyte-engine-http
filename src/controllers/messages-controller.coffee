_ = require 'lodash'
debug = require('debug')('nanocyte-engine-http:messages-controller')

class MessagesController
  constructor: ({@client}={}) ->

  create: (req, res) =>
    unless req.header('X-MESHBLU-UUID') == req.params.flowId
      return res.status(403).end()

    {flowId, instanceId} = req.params

    req.body ?= {}
    # get from headers in case it does not exist in the message
    req.body.fromUuid ?= @_getFromUuidFromHeader req.header('X-MESHBLU-ROUTE')

    message =
      metadata:
        flowId: flowId
        instanceId: instanceId
        toNodeId: 'engine-input'
        fromUuid: req.body.fromUuid
      message: req.body

    messageStr = JSON.stringify message

    @client.get "request-queue-name:#{flowId}", (error, requestQueueName) =>
      requestQueueName ?= 'request:queue'

      debug '@client.lpush', requestQueueName, messageStr
      @client.lpush requestQueueName, messageStr, (error) =>
        return res.status(500).send(error) if error?

        res.status(201).end()


  _getFromUuidFromHeader: (route) =>
    return unless route?
    try
      route = JSON.parse route
    catch
      route = null

    hop = _.first route
    return hop.from if hop?

module.exports = MessagesController
