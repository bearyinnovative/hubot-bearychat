'use strict';

const {BaseClient} = require('../../src/client/base');

describe('BaseClient', () => {
  it('run should store tokens & client', () => {
    const client = new BaseClient();
    const stubTokens = ['foo', 'bar'];
    const stubRobot = {foo: 'bar'};
    client.run(stubTokens, stubRobot);

    client.tokens.should.be.eql(stubTokens);
    client.robot.should.be.eql(stubRobot);
  });

  it('packMsg should be ok', () => {
    const client = new BaseClient();

    client.packMsg();
  });
  
  it('sendMsg should be ok', () => {
    const client = new BaseClient();

    client.sendMsg();
  });
});
