EventEmitter = require 'events'
WebSocket = require 'ws'
{ User, TextMessage } = require 'hubot'
bearychat = require 'bearychat'
rtm = bearychat.rtm

decodeMention = require('./helpers').decodeMention

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

class RTMClient extends EventEmitter
  # a retry flow contains 3 parts: backoff waiting, ws url fetching and ws conecting.
  # if RTMClient in a retryflow, then @isRetrying must be true else false.
  # @retryMax is how many times RTMClient can go into retry flow after it disconnected.
  constructor: (opts) ->
    opts = opts || {}
    @retryMax = opts.retryMax or 10
    @rtmPingInterval = opts.rtmPingInterval or 2000
    @resetRetryTimes()
    @isRetrying = false

  resetRetryTimes: () ->
    @retryTimes = 0

  run: (tokens, @robot) ->
    @token = tokens[0]
    unless @token
      @robot.logger.error 'No BearyChat RTM token provided'
      return

    rtm.start({token: @token})
      .then (resp) =>
        resp.json()
      .then ({ user, ws_host }) =>
        unless user and ws_host
          throw new Error("Fetching WebSocket URL and user data failed")
        @robot.logger.info "Connected as @#{user.name}"
        @user = user
        @emit EventUserChanged, @user
        @emit EventSignedIn
        @connectToRTM ws_host
      .catch (e) =>
        @emit EventError, e
        @isRetrying = false
        @rerun()

  clearPingInterval: () ->
    if @pingInterval
      clearInterval(@pingInterval)

  rerun: () ->
    if @isRetrying
      return
    @isRetrying = true
    @retryTimes++
    if (@retryTimes <= @retryMax)
      retryBackoff = 1000 * Math.pow(2, @retryTimes - 1)
      @robot.logger.info "Retry to connect server #{@retryTimes} times, wait for #{retryBackoff / 1000} second"
      @clearPingInterval()
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

  sendMessageToRoom: (envelope, message) ->
    vchannelId = envelope.room
    bearychat.message.create({
      token: @token,
      vchannel_id: vchannelId,
      text: message.text,
      attachments: []
    })

  connectToRTM: (wsHost) ->
    @rtmCallId = 0
    @rtmConn = new WebSocket wsHost

    @rtmConn.on 'open', @onWebSocketOpen.bind(@)
    @rtmConn.on 'close', @onWebSocketClose.bind(@)
    @rtmConn.on 'error', @onWebSocketError.bind(@)
    @rtmConn.on 'message', @onWebSocketMessage.bind(@)

  nextRTMCallId: () -> @rtmCallId++

  rtmPing: () ->
    @writeWebSocket
      type: rtm.message.type.PING

  writeWebSocket: (message) ->
    unless message.call_id
      message.call_id = @nextRTMCallId()

    @rtmConn.send JSON.stringify message

  onWebSocketOpen: () ->
    @emit EventConnected
    @isRetrying = false
    @resetRetryTimes()
    @clearPingInterval()
    @pingInterval = setInterval @rtmPing.bind(@), @rtmPingInterval

  onWebSocketClose: () ->
    @emit EventClosed
    @isRetrying = false # make sure unsuccessful connection should stop current retryflow
    @rerun()

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
