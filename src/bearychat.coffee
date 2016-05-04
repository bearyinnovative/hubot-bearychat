{Robot, Adapter, User, TextMessage} = require 'hubot'

{HTTPClient} = require './client/http'

class Bearychat extends Adapter

  constructor: (robot) ->
    @robot = robot

  send: (envelope, strings...) ->
    msg = @client.packMsg(false, envelope, strings)
    @client.sendMsg(envelope, msg)

  reply: (envelope, strings...) ->
    msg = @client.packMsg(false, envelope, strings)
    @client.sendMsg(envelope, msg)

  run: ->
    tokens = process.env.HUBOT_BEARYCHAT_TOKENS
    return @robot.logger.error 'No BearyChat tokens provided to Hubot' unless tokens
    
    @client = new HTTPClient @, @robot, tokens.split(',')
    @client.run()

    @emit 'connected'
    
exports.use = (robot) -> new Bearychat robot
