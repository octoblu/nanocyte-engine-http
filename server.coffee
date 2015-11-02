fs                 = require 'fs'
morgan             = require 'morgan'
express            = require 'express'
bodyParser         = require 'body-parser'
errorHandler       = require 'errorhandler'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
debug              = require('debug')('nanocyte-engine-simple:server')
httpSignature      = require '@octoblu/connect-http-signature'
MessagesController = require './src/controllers/messages-controller'
redis              = require 'redis'
RedisNS            = require 'redis-ns'
publicKey          = require './public-key.json'

redisClient = redis.createClient process.env.REDIS_URI
client = new RedisNS 'nanocyte-engine', redisClient

messagesController = new MessagesController client: client

PORT  = process.env.PORT ? 80

app = express()
app.use morgan('dev', immediate: false)
app.use errorHandler()
app.use meshbluHealthcheck()
app.use httpSignature.verify pub: publicKey.publicKey
app.use httpSignature.gateway()
app.use bodyParser.urlencoded limit: '50mb', extended : true
app.use bodyParser.json limit : '50mb'

app.post '/flows/:flowId/instances/:instanceId/messages', messagesController.create

server = app.listen PORT, ->
  host = server.address().address
  port = server.address().port

  console.log "Server running on #{host}:#{port}"
