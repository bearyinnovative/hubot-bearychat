'use strict';

const EventEmitter = require('events');
const util = require('util');

class BaseClient {
  constructor() {
    EventEmitter.call(this);
  }

  run(tokens, robot) {
    this.tokens = tokens;
    this.robot = robot;
  }

  sendMsg() {}

  packMsg() {}
}

util.inherits(BaseClient, EventEmitter);

exports.BaseClient = BaseClient;
