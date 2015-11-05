class Subscriber
  constructor: (options={}) ->
    {@client} = options

  getSubscriptions: (request, callback) =>
    @client.lpush 'request:queue', JSON.stringify(request), (error) =>
      callback error
    # callback null, data: [], metadata: status: 'OK', code: 200

module.exports = Subscriber
