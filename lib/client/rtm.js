'use strict';

const hubot = require('hubot');
const User = hubot.User;
const TextMessage = hubot.TextMessage;

const WebSocket = require('ws');

const BaseClient = require('./base').BaseClient;

const events = require('./events');
const EventMessage = events.EventMessage;
const EventConnected = events.EventConnected;
const EventError = events.EventError;
const EventClosed = events.EventClosed;
const EventSignedIn = events.EventSignedIn;
const EventUserChanged = events.EventUserChanged;

const MessageType = {
  Ping: 'ping',
  Pong: 'pong',
  Reploy: 'reply',
  Ok: 'ok',

  P2PMessage: 'message',
  P2PTyping: 'typing',

  ChannelMessage: 'channel_message',
  ChannelTyping: 'channel_typing',
};

const MessageTypeInv = ((m) => {
  const rv = {};
  for (let k in m) rv[m[k]] = k;
  return rv;
})(MessageType);

const HandlableMessageTypes = [
  MessageType.P2PMessage,
  MessageType.ChannelMessage,
];

class RTMClient extends BaseClient {

  constructor(opts) {
    opts = opts || {};
    super(opts);

    this.rtmPingInterval = opts.rtmPingInterval || 2000;
    this.rtmStartUrl = (opts.rtmStartUrl ||
                        process.env.HUBOT_BEARYCHAT_RTM_START_URL ||
                        'https://rtm.bearychat.com/start');
  }

  run(tokens, robot) {
    super.run(tokens, robot);

    // RTM client use first token only.
    this.token = tokens[0];
    if (!this.token) {
      this.robot.logger.error('No token provided');
      return;
    }

    this.rtmStart(this.token)
      .then((rv) => {
        const wsHost = rv.result.ws_host;
        const user = rv.result.user;
        if (!wsHost || !user) {
          this.emit(EventError, rv);
          return;
        }

        this.user = user;
        this.emit(EventUserChanged, this.user);
        this.emit(EventSignedIn);

        this.wsConnect(wsHost);
      })
      .catch((e) => {
        this.emit(EventError, e);
      });
  }

  sendMsg(envelope, message) {
    this.wsSend(message);
  }

  packMsg(isReply, envelope, ...strings) {
    let text = strings.join('\n');
    if (isReply) text = `@<=${envelope.user.name}=>: ${text}`;

    const message = {
      type: envelope.user.type,
      channel_id: envelope.user.channel,
      vchannel_id: envelope.user.vchannel,
      refer_key: null,
      text,
    };

    if (message.type === MessageType.P2PMessage) {
      message.to_uid = envelope.user.sender;
    }

    return message;
  }

  receiveMsgCallback(message) {
    // Ignore robot himself.
    if (message.uid === this.user.id) return;

    const text = this.decodeText(message.text);

    const user = new User(message.uid, {
      sender: message.uid,
      vchannel: message.vchannel_id,
      channel: message.channel_id,
      type: message.type,
      name: message.uid,
    });

    this.emit(EventMessage, new TextMessage(user, text, message.key));
  }

  decodeText(text) {
    // Decode mention.
    text = text.replace(/(@)<=(.*)=\>/g, (_, mention, name) => {
      if (name === this.user.id) return this.robot.name;
      return name;
    });

    return text;
  }

  rtmStart(token) {
    const payload = {token};
    return new Promise((resolve, reject) => {
      this.robot.http(this.rtmStartUrl)
        .header('Content-Type', 'application/json')
        .post(JSON.stringify(payload))((err, res, body) => {
          if (err) return reject(err);

          const resp = JSON.parse(body);
          if (resp.code !== 0) return reject(resp);

          return resolve(resp);
        });
    });
  }

  wsConnect(wsHost) {
    this.wsCallId = 0;
    this.wsConn = new WebSocket(wsHost);

    this.wsConn.on('open', this.onWsOpen.bind(this));
    this.wsConn.on('close', this.onWsClose.bind(this));
    this.wsConn.on('error', this.onWsError.bind(this));
    this.wsConn.on('message', this.onWsMessage.bind(this));

    this.emit(EventConnected);
  }

  nextWsCallId() { return this.wsCallId++; }

  wsPing() { this.wsSend({type: MessageType.Ping}); }

  wsSend(message) {
    if (!message.call_id) message.call_id = this.nextWsCallId();
    this.wsConn.send(JSON.stringify(message));
  }

  onWsOpen() { setInterval(this.wsPing.bind(this), this.rtmPingInterval); }

  onWsClose() { this.emit(EventClosed); }

  onWsError(e) { this.emit(EventError, e); }

  onWsMessage(data) {
    const message = JSON.parse(data);

    if (HandlableMessageTypes.indexOf(message.type) !== -1) {
      return this.receiveMsgCallback(message);
    }

    if (!MessageTypeInv[message.type]) {
      this.robot.logger.error(`unknown message type ${message.type}`);
    }
  }

}

exports.RTMClient = RTMClient;
