'use strict';

const {HTTPClient} = require('../../src/client/http');

describe('HTTPClient.packMsg', () => {
  const client = new HTTPClient();

  it('should concate user mention for reply', () => {
    const stubEnvelope = {
      user: {name: 'foobar'},
      sender: 'sender',
      vchannel: 'vchannel',
    };
    const stubText = 'hello';
    const rv = JSON.parse(client.packMsg(true, stubEnvelope, stubText));

    rv.sender.should.be.eql(stubEnvelope.sender);
    rv.vchannel.should.be.eql(stubEnvelope.vchannel);
    rv.text.should.match(`@${stubEnvelope.user.name}: ${stubText}`);
  });

  it('should be ok', () => {
    const stubEnvelope = {
      user: {name: 'foobar'},
      sender: 'sender',
      vchannel: 'vchannel',
    };
    const stubText = 'hello';
    const rv = JSON.parse(client.packMsg(false, stubEnvelope, stubText));

    rv.sender.should.be.eql(stubEnvelope.sender);
    rv.vchannel.should.be.eql(stubEnvelope.vchannel);
    rv.text.should.match(stubText);
  });
});

describe('HTTPClient.isValidToken', () => {
  const client = new HTTPClient();

  it('should be ok', () => {
    const stubToken = ['foo', 'bar'];

    client.tokens = stubToken;

    for (let token of stubToken) {
      client.isValidToken(token).should.be.ok();
    }

    client.isValidToken('foobar').should.not.be.ok();
  });
});
