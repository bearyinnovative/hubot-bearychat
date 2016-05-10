'use strict';

const should = require('should');

const {RTMClient, MessageType} = require('../../src/client/rtm');

describe('RTMClient.opts', () => {
  it('should be able to set rtm ping interval', () => {
    let client;

    client = new RTMClient();
    client.rtmPingInterval.should.be.eql(2000);

    client = new RTMClient({rtmPingInterval: 1000});
    client.rtmPingInterval.should.be.eql(1000);
  });

  it('should be able to set rtm start url', () => {
    let client;

    client = new RTMClient();
    client.rtmStartUrl.should.be.eql('https://rtm.bearychat.com/start');

    client = new RTMClient({rtmStartUrl: 'http://foo.bearychat.com/bar'});
    client.rtmStartUrl.should.be.eql('http://foo.bearychat.com/bar');
  });
});

describe('RTMClient.packMsg', () => {
  const client = new RTMClient();

  it('should encode mention for reply', () => {
    const stubEnvelope = {
      user: {
        name: 'foobar',
        type: MessageType.ChannelMessage,
        channel: 'channel',
        vchannel: 'vchannel',
      },
    };
    const stubText = 'hello';

    const rv = client.packMsg(true, stubEnvelope, stubText);
    rv.type.should.be.eql(stubEnvelope.user.type);
    rv.channel_id.should.be.eql(stubEnvelope.user.channel);
    rv.vchannel_id.should.be.eql(stubEnvelope.user.vchannel);
    should(rv.refer_key).be.eql(null);
    rv.text.should.be.match(`@<=${stubEnvelope.user.name}=>: ${stubText}`);
  });

  it('should attach to_uid for P2PMessage', () => {
    const stubEnvelope = {
      user: {
        name: 'foobar',
        type: MessageType.P2PMessage,
        channel: 'channel',
        vchannel: 'vchannel',
        sender: 'sender',
      },
    };
    const stubText = 'hello';

    const rv = client.packMsg(false, stubEnvelope, stubText);
    rv.type.should.be.eql(stubEnvelope.user.type);
    rv.to_uid.should.be.eql(stubEnvelope.user.sender);
    rv.channel_id.should.be.eql(stubEnvelope.user.channel);
    rv.vchannel_id.should.be.eql(stubEnvelope.user.vchannel);
    should(rv.refer_key).be.eql(null);
    rv.text.should.be.match(`${stubText}`);
  });

  it('should be ok', () => {
    const stubEnvelope = {
      user: {
        name: 'foobar',
        type: MessageType.ChannelMessage,
        channel: 'channel',
        vchannel: 'vchannel',
      },
    };
    const stubText = 'hello';

    const rv = client.packMsg(false, stubEnvelope, stubText);
    rv.type.should.be.eql(stubEnvelope.user.type);
    rv.channel_id.should.be.eql(stubEnvelope.user.channel);
    rv.vchannel_id.should.be.eql(stubEnvelope.user.vchannel);
    should(rv.refer_key).be.eql(null);
    rv.text.should.be.match(`${stubText}`);
  });
});
