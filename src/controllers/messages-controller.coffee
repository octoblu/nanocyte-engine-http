debug = require('debug')('nanocyte-engine-http:messages-controller')

class MessagesController
  constructor: ({@client}={}) ->

  create: (req, res) =>
    unless req.header('X-MESHBLU-UUID') == req.params.flowId
      return res.status(403).end()

    message =
      metadata:
        flowId: req.params.flowId
        instanceId: req.params.instanceId
      message: req.body

    messageStr = JSON.stringify message

    debug '@client.lpush', 'request:queue', messageStr

    @client.lpush 'request:queue', messageStr, (error) =>
      return res.status(500).send(error) if error?

      res.status(201).end()

module.exports = MessagesController
