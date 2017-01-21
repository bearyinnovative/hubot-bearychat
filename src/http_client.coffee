EventEmitter = require 'events'
util = require 'util'
{
  User,
  TextMessage,
} = require 'hubot'

{
  EventConnected,
  EventMessage,
  EventError,
} = require './client_event'

class HTTPClient
  constructor: () ->
    EventEmitter.call(@)

  run: (@tokens, @robot) ->
    @robot.router.post '/bearychat', @receiveMessageCallback.bind(@)

    @emit EventConnected

  sendMessage: (envelope, message) ->
    {team, token} = envelope.user
    url = "https://#{team}.bearychat.com/api/hubot_hook/#{token}"

    @robot.http(url)
      .header('Content-Type', 'application/json')
      .post(message) (err, res, body) =>
        @robot.logger.debug(body)
        @emit(EventError, err) if err

  packMessage: (isReply, envelope, strings) ->
    text = strings.join '\n'
    text = "#{envelope.user.name}: #{text}" if isReply
    JSON.stringify
      sender: envelope.user.sender
      vchannel: envelope.user.vchannel
      text: text

  receiveMessageCallback: (req, res) ->
    body = req.body
    unless body
      @robot.logger.error('No body provided for this request')
      return

    unless @isValidToken(body.token)
      res.status(404).end()
      @robot.logger.error('Invalid token sent for this request')
      return

    res.status(200).end()

    text = "#{@robot.name} #{body.text}"
    user = new User(body.sender, {
      team: body.subdomain,
      token: body.token,
      sender: body.sender,
      vchannel: body.vchannel,
      name: body.username,
    })

    @emit(EventMessage, new TextMessage(user, text, body.key))

  isValidToken: (token) ->
    @tokens.indexOf(token) != -1

util.inherits HTTPClient, EventEmitter

module.exports = HTTPClient
