{HTTPClient} = require '../src/client/http'

should = require 'should'

describe 'HTTPClient.packMsg', ->
  client = new HTTPClient(null, null, [])

  it 'should not contain @ when is not reply message', ->
    envelope =
      sender: 'sender'
      vchannel: 'vchannel'
      user:
        name: 'username'
    text = 'foobar'

    msg = JSON.parse client.packMsg false, envelope, text
    msg.sender.should.be.eql envelope.sender
    msg.vchannel.should.be.eql envelope.vchannel
    msg.text.should.be.eql text

  it 'should contain @ when is reply message', ->
    envelope =
      sender: 'sender'
      vchannel: 'vchannel'
      user:
        name: 'username'
    text = 'foobar'

    msg = JSON.parse client.packMsg true, envelope, text
    msg.sender.should.be.eql envelope.sender
    msg.vchannel.should.be.eql envelope.vchannel
    msg.text.should.match /^@/

describe 'HTTPClient.isValidToken', ->
  it 'should be ok', ->
    client = new HTTPClient(null, null, [])
    client.isValidToken('nothing-is-ok').should.not.be.ok()
    
    tokens = ['foo', 'bar']
    client = new HTTPClient(null, null, tokens)
    for token in tokens
      client.isValidToken(token).should.be.ok()
