{User, TextMessage} = require 'hubot'

class HTTPClient

  # Public: Start HTTP client
  #
  # Returns client itself
  run: (adapter, robot, tokens) ->
    @adapter = adapter
    @robot = robot
    @tokens = tokens

    @receiveMsg()

    return this

  # Public: Send a message
  sendMsg: (envelope, msg) ->
    {team, token} = envelop.user
    url = "https://#{team}.bearychat.com/api/hubot_hook/#{token}"

    @robot
      .http(url)
      .header('Content-Type', 'application/json')
      .post(msg) (err, res, body) => @robot.logger.debug body

  # Public: Build a message
  #
  # Returns built message string
  packMsg: (isReply, envelope, strings...) ->
    text =  strings.join('\n')
    text = "@#{envelope.user.name}: #{text}" if isReply
    JSON.stringify
      sender: envelope.sender
      vchannel: envelope.vchannel
      text: text

  # Private: Mount message receive endpoint
  receiveMsg: () =>
    @robot.router.post '/bearychat', @receiveMsgCallback

  # Private: Callback for incoming message
  receiveMsgCallback: (req, res) =>
    body = req.body
    return @robot.loger.error 'No body provided for this request' unless body

    {subdomain, token, sender, vchannel, username, text, key} = body

    # Response at once.
    valid = @isValidToken token
    status = if valid then 200 else 404
    res.status(status).end()

    return @robot.logger.error 'Invalid token for this request' unless valid

    text = "#{@robot.name} #{text}"
    user = new User sender,
      team: subdomain
      token: token
      sender: sender
      vchannel: vchannel
      name: username

    @adapter.receive new TextMessage user, text, key

  # Private: Validate a token
  #
  # Returns boolean
  isValidToken: (token) -> token in @tokens


exports.HTTPClient = HTTPClient
