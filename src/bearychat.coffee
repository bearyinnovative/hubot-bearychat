{Adapter} = require 'hubot'

HTTPClient = require './http_client'
RTMClient = require './rtm_client'
{
  EventConnected,
  EventMessage,
  EventClosed,
  EventError,
} = require './client_event'

class BearyChatAdapter extends Adapter

  send: (envelope, strings...) ->
    message = @client.packMessage false, envelope, strings
    @client.sendMessage envelope, message

  reply: (envelope, strings...) ->
    message = @client.packMessage true, envelope, strings
    @client.sendMessage envelope, message

  run: ->
    tokens = process.env.HUBOT_BEARYCHAT_TOKENS
    if not tokens
      @robot.logger.error 'No BearyChat tokens provided'
      return

    tokens = tokens.split(',')
    mode = process.env.HUBOT_BEARYCHAT_MODE

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

    @client.run tokens, @robot

  handleConnected: ->
    @emit 'connected'

  handleClosed: ->
    @robot.logger.error 'client closed'

  handleError: (e) ->
    @robot.logger.error "client error #{e}"

exports.use = (robot) ->
  new BearyChatAdapter(robot)
