MESSAGE_QUEUE='meshblu-messages'

class MeshbluQueue
  constructor: ({@client}) ->

  queueMessage: (message) =>
    @client.lpush MESSAGE_QUEUE, JSON.stringify(message)

module.exports = MeshbluQueue
