debug = require('debug')('nanocyte-engine-http:messages-controller')

class MessagesController
  constructor: ({@client}={}) ->

  create: (req, res) =>
    unless req.header('X-MESHBLU-UUID') == req.params.flowId
      return res.status(403).end()

    {flowId} = req.params

    message =
      metadata:
        flowId: flowId
        instanceId: req.params.instanceId
        toNodeId: 'engine-input'
      message: req.body

    messageStr = JSON.stringify message

    @client.get "request-queue-name:#{flowId}", (error, requestQueueName) =>
      requestQueueName ?= 'request:queue'

      debug '@client.lpush', requestQueueName, messageStr
      @client.lpush requestQueueName, messageStr, (error) =>
        return res.status(500).send(error) if error?

        res.status(201).end()

module.exports = MessagesController
