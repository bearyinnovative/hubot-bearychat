'use strict';

const {User, TextMessage} = require('hubot');

const {BaseClient} = require('./base');
const {EventMessage, EventConnected, EventError} = require('./events');

class HTTPClient extends BaseClient {

  run(tokens, robot) {
    super.run(tokens, robot);

    this.robot.router.post('/bearychat', this.receiveMsgCallback.bind(this));

    this.emit(EventConnected);
  }

  sendMsg(envelope, message) {
    const {team, token} = envelope.user.team;
    const url = `https://${team}.bearychat.com/api/hubot_hook/${token}`;

    return this.robot
      .http(url)
      .header('Content-Type', 'application/json')
      .post(message)((err, res, body) => {
        this.robot.logger.debug(body);

        if (err) this.emit(EventError, err);
      });
  }

  packMsg(isReply, envelope, ...strings) {
    let text = strings.join('\n');
    if (isReply) text = `@${envelope.user.name}: ${text}`;
    return JSON.stringify({
      sender: envelope.sender,
      vchannel: envelope.vchannel,
      text,
    });
  }

  receiveMsgCallback(req, res) {
    const body = req.body;
    if (!body) {
      this.robot.logger.error('No body provided for this request');
      return;
    }

    if (!this.isValidToken(body.token)) {
      res.status(404).end();
      this.robot.logger.error('Invalid token for this request');
      return;
    }

    res.status(200).end();

    const text = `${this.robot.name} ${body.text}`;
    const user = new User(body.sender, {
      team: body.subdomain,
      token: body.token,
      sender: body.sender,
      vchannel: body.vchannel,
      name: body.username,
    });

    this.emit(EventMessage, new TextMessage(user, text, body.key));
  }

  isValidToken(token) {
    return this.tokens.indexOf(token) !== -1;
  }

}

exports.HTTPClient = HTTPClient;
