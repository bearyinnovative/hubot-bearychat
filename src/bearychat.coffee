{Adapter}  = require 'hubot'

{
  HTTPClient, RTMClient,
  EventConnected, EventMessage, EventClosed, EventError,
} = require '../lib/client'

class Bearychat extends Adapter

  send: (envelope, strings...) ->
    msg = @client.packMsg(false, envelope, strings)
    @client.sendMsg(envelope, msg)

  reply: (envelope, strings...) ->
    msg = @client.packMsg(true, envelope, strings)
    @client.sendMsg(envelope, msg)

  run: ->
    tokens = process.env.HUBOT_BEARYCHAT_TOKENS
    return @robot.logger.error 'No BearyChat tokens provided to Hubot' unless tokens
    tokens = tokens.split ','
    
    if process.env.HUBOT_BEARYCHAT_MODE?.toLowerCase() is 'http'
      @client = new HTTPClient
    else
      @client = new RTMClient

    @client.run tokens, @robot

    @client.on EventConnected, () => @emit 'connected'
    @client.on EventMessage, @receive
    @client.on EventClosed, @handleClosed
    @client.on EventError, @handleError

  handleClosed: () ->
    @robot.logger.error 'client closed'

  handleError: (e) ->
    @robot.logger.error "client error #{e}"

exports.use = (robot) -> new Bearychat robot
