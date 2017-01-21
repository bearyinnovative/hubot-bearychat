# hubot-bearychat

This is a [Hubot](http://hubot.github.com/) adapter to use with [BearyChat](https://bearychat.com).

![Development Status](https://img.shields.io/badge/status-0.3.0-green.svg?style=flat-square)

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

## LICENSE

MIT
