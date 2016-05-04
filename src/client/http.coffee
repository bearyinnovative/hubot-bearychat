{User, TextMessage} = require 'hubot'

{BaseClient} = require './base'

class HTTPClient extends BaseClient

  constructor: (@adapter, @robot, @tokens) ->

  # Public: Start HTTP client
  #
  # Returns client itself
  run: () ->
    @robot.router.post '/bearychat', @receiveMsgCallback

    return this

  # Public: Send a message
  sendMsg: (envelope, msg) ->
    {team, token} = envelop.user
    url = "https://#{team}.bearychat.com/api/hubot_hook/#{token}"

    @robot
      .http(url)
      .header('Content-Type', 'application/json')
      .post(msg) (err, res, body) => @robot.logger.debug body

  # Private: Callback for incoming message
  receiveMsgCallback: (req, res) =>
    body = req.body
    return @robot.loger.error 'No body provided for this request' unless body

    {subdomain, token, sender, vchannel, username, text, key} = body

    # Response at once.
    valid = @isValidToken token
    status = if valid then 200 else 404
    res.status(status).end()

    return @robot.logger.error 'Invalid token for this request' unless valid

    text = "#{@robot.name} #{text}"
    user = new User sender,
      team: subdomain
      token: token
      sender: sender
      vchannel: vchannel
      name: username

    @adapter.receive new TextMessage user, text, key


exports.HTTPClient = HTTPClient
