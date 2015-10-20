redis = require 'redis'
client = redis.createClient process.env.REDIS_PORT, process.env.REDIS_HOST, auth_pass: process.env.REDIS_PASSWORD

MESSAGE_QUEUE='meshblu-messages'
class MeshbluQueue
  queueMessage: (message) =>
    client.lpush MESSAGE_QUEUE, JSON.stringify(message)

module.exports = MeshbluQueue
