{Adapter} = require 'hubot'
bearychat = require 'bearychat'

HTTPClient = require './http_client'
RTMClient = require './rtm_client'
{
  EventConnected,
  EventMessage,
  EventClosed,
  EventError,
} = require './client_event'

class BearyChatAdapter extends Adapter

  _setupClient: (mode) ->
    if mode && mode.toLowerCase() is 'http'
      @robot.logger.info 'Connect using HTTP mode'
      @client = new HTTPClient
    else
      @robot.logger.info 'Connect using RTM mode'
      @client = new RTMClient

    @client.on EventConnected, @handleConnected.bind(@)
    @client.on EventMessage, @receive.bind(@)
    @client.on EventClosed, @handleClosed.bind(@)
    @client.on EventError, @handleError.bind(@)

  _setupEvents: (tokens) ->
    @robot.on 'bearychat.attachment', (data) =>
      room = data.message.room
      text = data.text
      unless room and room.vchannelId and text
        @robot.logger.error 'invalid attachment message payload', data
        return

      bearychat.message.create({
        token: tokens[0],
        vchannel_id: room.vchannelId,
        text: text,
        attachments: (data.attachments || []),
      })
        .catch((err) => @robot.logger.error 'send message failed', err)

  send: (envelope, strings...) ->
    if envelope.room and envelope.room.vchannelId
      message = @client.packMessage false, envelope, strings
      @client.sendMessage envelope, message
    else # robot.messageRoom
      message = {text: strings[0]}
      @client.sendMessageToRoom envelope, message

  reply: (envelope, strings...) ->
    message = @client.packMessage true, envelope, strings
    @client.sendMessage envelope, message

  run: ->
    tokens = (process.env.HUBOT_BEARYCHAT_TOKENS || '').split(',')
    unless tokens and tokens.length > 0
      @robot.logger.error 'No BearyChat tokens provided'
      return

    mode = (process.env.HUBOT_BEARYCHAT_MODE || '').toLowerCase()

    @_setupClient mode
    @_setupEvents tokens

    @client.run tokens, @robot

  handleConnected: ->
    @emit 'connected'

  handleClosed: ->
    @robot.logger.error 'client closed'

  handleError: (e) ->
    @robot.logger.error "client error #{e}"

exports.use = (robot) ->
  new BearyChatAdapter(robot)
