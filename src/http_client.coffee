EventEmitter = require 'events'
bearychat = require 'bearychat'

{
  User,
  TextMessage,
} = require 'hubot'

{
  EventConnected,
  EventMessage,
  EventError,
} = require './client_event'

class HTTPClient extends EventEmitter
  run: (@tokens, @robot) ->
    @robot.router.post '/bearychat', @receiveMessageCallback.bind(@)

    @emit EventConnected

  sendMessage: (envelope, message) ->
    {token} = envelope.user
    message = Object.assign {token: token, attachments: []}, message
    bearychat.message.create(message).catch (err) =>
      @emit(EventError, err)
      @robot.logger.error 'send message failed', err

  sendMessageToRoom: (envelope, message) ->
    vchannelId = envelope.room
    bearychat.message.create({
      token: @tokens[0],
      vchannel_id: vchannelId,
      text: message.text,
      attachments: message.attachments or []
    })

  packMessage: (isReply, envelope, [text, opts]) ->
    text = "@#{envelope.user.name}: #{text}" if isReply
    Object.assign opts || {}, {
      sender: envelope.user.sender,
      vchannel_id: envelope.user.vchannel,
      text: text
    }

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
      room: {
        vchannelId: body.vchannel,
      }
    })

    @emit(EventMessage, new TextMessage(user, text, body.key))

  isValidToken: (token) ->
    @tokens.indexOf(token) != -1

module.exports = HTTPClient
