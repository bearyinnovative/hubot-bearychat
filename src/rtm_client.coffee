EventEmitter = require 'events'
WebSocket = require 'ws'
{ User, TextMessage } = require 'hubot'
{ rtm } = require 'bearychat'

{
  EventConnected,
  EventMessage,
  EventError,
  EventClosed,
  EventUserChanged,
  EventSignedIn,
  EventTimedout,
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

class RTMClient extends EventEmitter
  constructor: (opts) ->
    opts = opts || {}
    @retryMax = opts.retryMax or 10
    @rtmPingInterval = opts.rtmPingInterval or 2000
    @on EventClosed, @rerun.bind(@)
    @resetRetryTimes()

  resetRetryTimes: () ->
    @retryTimes = 0

  run: (tokens, @robot) ->
    @token = tokens[0]
    unless @token
      @robot.logger.error 'No BearyChat RTM token provided'
      return

    rtm.start({token: @token})
      .then (resp) => resp.json()
      .then ({ user, ws_host }) =>
        @robot.logger.info "Connected as @#{user.name}"
        @user = user
        @emit EventUserChanged, @user
        @emit EventSignedIn

        @connectToRTM ws_host
        @resetRetryTimes()
      .catch (e) =>
        @emit EventError, e

  rerun: () ->
    @retryTimes++
    if (@retryTimes <= @retryMax)
      retryBackoff = 1000 * @retryTimes
      @robot.logger.info "Retry to connect server #{@retryTimes} times, wait for #{retryBackoff / 1000} second"
      if @pingInterval
        clearInterval(@pingInterval)
      setTimeout () =>
        @run([@token], @robot)
      , retryBackoff
    else
      @robot.logger.info "Retry #{@retryTimes} times, reach to max, stop retry."
      @emit EventTimedout

  packMessage: (isReply, envelope, strings) ->
    text = strings.join '\n'
    if isReply
      rtm.message.refer envelope.user.message, text
    else
      rtm.message.reply envelope.user.message, text

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
    @pingInterval = setInterval @rtmPing.bind(@), @rtmPingInterval

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
      room:
        vchannelId: message.vchannel_id

    @emit EventMessage, new TextMessage messageUser, messageText, message.key

module.exports = RTMClient
