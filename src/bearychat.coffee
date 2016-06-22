{Robot, Adapter, User, TextMessage} = require 'hubot'

class Bearychat extends Adapter

  constructor: (robot) ->
    @robot = robot

  send: (envelope, strings...) ->
    msg = @packMsg(false, envelope, strings...)
    @sendMsg(envelope, msg)

  reply: (envelope, strings...) ->
    msg = @packMsg(true, envelope, strings...)
    @sendMsg(envelope, msg)

  run: ->
    tokens = process.env.HUBOT_BEARYCHAT_TOKENS
    return @robot.logger.error "No BearyChat tokens provided to Hubot" unless tokens
    @options = {tokens: tokens.split(",")}

    @receiveMsg()
    @emit 'connected'
    

  receiveMsg: =>
    @robot.router.post '/bearychat', @callback

  callback: (req, res) =>
    body = req.body
    return @robot.logger.error "No body provided for this request" unless body

    {subdomain, token, sender, vchannel, username, text, key} = body
    text = "#{@robot.name} #{text}"

    valid = @isValidToken(token)
    status = if valid then 200 else 401
    res.status(status).end() # at once

    return @robot.logger.error "Invalid token for this request" unless valid

    user = new User sender, {team: subdomain, token: token, sender: sender, vchannel: vchannel, name: username}

    @receive new TextMessage user, text, key

  packMsg: (isReply, envelope, strings...) ->
    text = strings[0]
    text = if isReply then "@#{envelope.user.name}: #{text}" else text
    attachments = strings[1] or null
    {token, vchannel} = envelope.user
    JSON.stringify {token: token, vchannel: vchannel, text: text, attachments: attachments}

  sendMsg: (envelope, msg) ->
    @robot.http("https://rtm.bearychat.com/message")
          .header('Content-Type', 'application/json')
          .post(msg) (err, res, body) =>
            @robot.logger.debug body

  isValidToken: (token) ->
    token in @options.tokens

exports.use = (robot) ->
  new Bearychat robot
