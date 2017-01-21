EventEmitter = require 'events'
util = require 'util'
WebSocket = require 'ws'
{ User, TextMessage } = require 'hubot'
{ rtm } = require 'bearychat'

{
  EventConnected,
  EventMessage,
  EventError,
  EventUserChanged,
  EventSignedIn,
} = require './client_event'

shouldHandleThisMessage = (message) ->
  rtm.message.isChatMessage(message)

decodeMention = (text, userId, replaceName) ->
  text.replace(
    /(@)<=(.*)=\>/g,
    (_, mentionMark, mentionedUserId) ->
      return replaceName if mentionedUserId is userId
      mentionedUserId
  )

class RTMClient
  constructor: (opts) ->
    EventEmitter.call(@)

    opts = opts || {}

    @rtmPingInterval = opts.rtmPingInterval or 2000

  run: (tokens, @robot) ->
    @token = tokens[0]
    unless @token
      @robot.logger.error 'No BearyChat RTM token provided'
      return

    @rtmClient = new rtm.Client(@token)
    @rtmClient.start()
      .then ({ user, ws_host }) =>
        @robot.logger.info "Connected as @#{user.name}"
        @user = user
        @emit EventUserChanged, @user
        @emit EventSignedIn

        @connectToRTM ws_host
      .catch (e) =>
        @emit EventEmitter, e

  packMessage: (isReply, envelope, strings) ->
    text = strings.join '\n'
    if isReply
      text = "@<=#{envelope.user.id}=> #{text}"

    rtm.message.refer envelope.user.message, text

  sendMessage: (envelope, message) ->
    @writeWebSocket message

  connectToRTM: (wsHost) ->
    @rtmCallId = 0
    @rtmConn = new WebSocket wsHost

    @rtmConn.on 'open', @onWebSocketOpen.bind(@)
    @rtmConn.on 'close', @onWebSocketClose.bind(@)
    @rtmConn.on 'error', @onWebSocketError.bind(@)
    @rtmConn.on 'message', @onWebSocketMessage.bind(@)

    @emit EventConnected

  nextRTMCallId: () -> @rtmCallId++

  rtmPing: () ->
    @writeWebSocket
      type: rtm.message.type.PING

  writeWebSocket: (message) ->
    unless message.call_id
      message.call_id = @nextRTMCallId()

    @rtmConn.send JSON.stringify message

  onWebSocketOpen: () ->
    setInterval @rtmPing.bind(@), @rtmPingInterval

  onWebSocketClose: () ->
    @emit EventClosed

  onWebSocketError: (err) ->
    @emit EventError, err

  onWebSocketMessage: (data) ->
    message = JSON.parse data

    return unless shouldHandleThisMessage message

    fromUserId = message.uid or message.robot_id

    # ignore message from robot himself
    return if fromUserId is @user.id

    messageText = decodeMention message.text, @user.id, @robot.name
    if rtm.message.isP2P(message) and not messageText.startsWith @robot.name
      messageText = "#{@robot.name} #{messageText}"

    messageUser = new User fromUserId,
      message: message

    @emit EventMessage, new TextMessage messageUser, messageText, message.key

util.inherits RTMClient, EventEmitter

module.exports = RTMClient
