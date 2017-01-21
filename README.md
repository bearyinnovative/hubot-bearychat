# hubot-bearychat

This is a [Hubot](http://hubot.github.com/) adapter to use with [BearyChat](https://bearychat.com).

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

## Mode

### RTM mode

### HTTP mode

## Configuration

## LICENSE

MIT
