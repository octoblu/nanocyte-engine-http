morgan             = require 'morgan'
express            = require 'express'
bodyParser         = require 'body-parser'
errorHandler       = require 'errorhandler'
compression        = require 'compression'
OctobluRaven       = require 'octoblu-raven'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
httpSignature      = require '@octoblu/connect-http-signature'
MessagesController = require './src/controllers/messages-controller'
redis              = require 'ioredis'
RedisNS            = require '@octoblu/redis-ns'
publicKey          = require './public-key.json'
expressVersion     = require 'express-package-version'

redisClient = redis.createClient process.env.REDIS_URI, dropBufferSupport: true
client = new RedisNS 'nanocyte-engine', redisClient

messagesController = new MessagesController {client}

PORT  = process.env.PORT ? 80
octobluRaven = new OctobluRaven()
octobluRaven.patchGlobal()

app = express()
app.use compression()
app.use octobluRaven.express().handleErrors()
app.use meshbluHealthcheck()
app.use expressVersion({format: '{"version": "%s"}'})
skip = (request, response) =>
  return response.statusCode < 400
app.use morgan 'dev', { immediate: false, skip } unless process.env.DISABLE_LOGGING == "true"
app.use errorHandler()
app.use httpSignature.verify pub: publicKey.publicKey
app.use httpSignature.gateway()
app.use bodyParser.urlencoded limit: '50mb', extended : true
app.use bodyParser.json limit : '50mb'

app.post '/flows/:flowId/instances/:instanceId/messages', messagesController.create

server = app.listen PORT, ->
  host = server.address().address
  port = server.address().port

  console.log "Nanocyte Engine HTTP running on port #{port}"

process.on 'SIGTERM', =>
  console.log 'SIGTERM caught, exiting'
  server.close =>
    process.exit 0
