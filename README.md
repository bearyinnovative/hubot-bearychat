# hubot-bearychat

This is a [Hubot](http://hubot.github.com/) adapter to use with [BearyChat](https://bearychat.com).

[![@BearyChat](http://openapi.beary.chat/badge.svg)](http://openapi.beary.chat/join)
[![Build Status](https://travis-ci.org/bearyinnovative/hubot-bearychat.svg)](https://travis-ci.org/bearyinnovative/hubot-bearychat)
[![npm version](https://badge.fury.io/js/hubot-bearychat.svg)](https://npmjs.com/package/hubot-bearychat)

[中文文档](./README_CN.md)

<!-- toc -->

- [5 Minutes Setup](#5-minutes-setup)
  * [Step 1. get ya a "hubot token"](#step-1-get-ya-a-hubot-token)
  * [Step 2. bootstrap your secret hubot project with yeoman](#step-2-bootstrap-your-secret-hubot-project-with-yeoman)
  * [Step 3. copy your hubot token and start it](#step-3-copy-your-hubot-token-and-start-it)
  * [Step 4. start chatting with your bot!](#step-4-start-chatting-with-your-bot)
- [Mode](#mode)
  * [RTM mode](#rtm-mode)
  * [HTTP mode](#http-mode)
- [Configuration](#configuration)
- [Hubot Interactions](#hubot-interactions)
  * [Send](#send)
  * [Reply](#reply)
  * [`bearychat.attachment`](#bearychatattachment)
- [LICENSE](#license)

<!-- tocstop -->

## 5 Minutes Setup

### Step 1. get ya a "hubot token"

Go to your team robots page in bearychat.com (your-cool-team.bearychat.com/robots)
and create a hubot. You will get your hubot token inside the bot settings form:

![art/create_hubot.png](art/create_hubot.png)

### Step 2. bootstrap your secret hubot project with yeoman

- `npm install -g hubot coffee-script yo generator-hubot`
- `mkdir -p /path/to/hubot`
- `cd /path/to/hubot`
- `yo hubot`
- `npm install hubot-bearychat --save`

Also check out the [hubot docs](https://github.com/github/hubot/tree/master/docs)
for further guidance on how to build your bot.

### Step 3. copy your hubot token and start it

```shell
$ export HUBOT_BEARYCHAT_TOKENS=token-token-token-here
$ export HUBOT_BEARYCHAT_MODE=rtm
$ ./bin/hubot -a bearychat
```

### Step 4. start chatting with your bot!

![art/bot_chat.png](art/bot_chat.png)

You can also refer [example/](example) for sample setup.

## Mode

### RTM mode

RTM mode uses BearyChat's RTM api and WebSocket as message transport protocol.
In this mode, hubot can receive all messages in real time and hear any messages
from channels it had joined.

To enable RTM mode, you should specify environment variable
`HUBOT_BEARYCHAT_MODE=rtm` before running the hubot.

`hubot-bearychat` uses rtm mode by default.

### HTTP mode

HTTP mode is the legacy message transport protocol. In this mode, hubot can
only receive messages that himself was mentioned (e.g. `@hubot how do you do`),
and you need to set the hubot hosted http service url in the hubot settings form.

To enable HTTP mode, you should specify environment variable
`HUBOT_BEARYCHAT_MODE=http` before running the hubot.

## Configuration

Available configurations are injected via environment variables:

| envvar | description |
|:------:|:------------|
| `HUBOT_BEARYCHAT_MODE` | running mode for the hubot, by default is `rtm` |
| `HUBOT_BEARYCHAT_TOKENS` | hubot token, required for running hubot |

## Hubot Interactions

### Send

Hubot can response a message with `res.send`:

```
robot.hear /hello/, (res) ->
  res.send 'hello, world!'
```

![art/res_send.png](art/res_send.png)

### Reply

If hubot want to response a message and refer the caller`s message, use `res.reply`:

```
robot.hear /how old are you?/, (res) ->
  res.reply 'I am Five!'
```

![art/res_reply.png](art/res_reply.png)

### Send message to other room

If you want to send a message to other channel use `robot.messageRoom` with vchannel_id， and Channel Name support is coming soon:

```
robot.hear /voldemort/i, (res) ->
  robot.messageRoom(vchannel_id, "Somebody is talking about you, Voldemort!")
```

### `bearychat.attachment`

If hubot want to response more than text, emit `bearychat.attachment`:

```
robot.respond /念两句诗/, (res) ->
  robot.emit 'bearychat.attachment',
    # required
    message: res.message
    # requried
    text: '当时我就念了...'
    attachments: [
      {
        color: '#cb3f20',
        text: '苟利国家生死以',
      },
      {
        text: '岂因祸福避趋之',
      },
      {
        images: [
          {url: 'http://example.com/excited.jpg'},
        ]
      }
    ]
```

![art/res_reply.png](art/res_attachment.png)

## LICENSE

MIT
