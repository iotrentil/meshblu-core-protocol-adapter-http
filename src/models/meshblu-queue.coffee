redis = require 'redis'
client = redis.createClient process.env.REDIS_PORT, process.env.REDIS_HOST, auth_pass: process.env.REDIS_PASSWORD

class MeshbluQueue
  constructor: ->

  queueAuthentication: (authMessage) =>
    redis.lpush AUTH_QUEUE, JSON.stringify(authMessage)


module.exports = MeshbluQueue
