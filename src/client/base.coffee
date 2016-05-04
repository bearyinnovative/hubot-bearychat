class BaseClient
  
  constructor: (@adapter, @robot, @tokens) ->
  
  # Public: Start HTTP client
  #
  # Returns client itself
  run: () ->
    return this

  # Public: Send a message
  sendMsg: (envelope, msg) ->

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

  # Private: Validate a token
  #
  # Returns boolean
  isValidToken: (token) -> token in @tokens

exports.BaseClient = BaseClient
