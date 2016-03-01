# hubot-bearychat

This is a [Hubot](http://hubot.github.com/) adapter to use with [BearyChat](https://bearychat.com).

#### Creating a new bot

- `npm install -g hubot coffee-script yo generator-hubot`
- `mkdir -p /path/to/hubot`
- `cd /path/to/hubot`
- `yo hubot`
- `npm install hubot-bearychat --save`
- Check out the [hubot docs](https://github.com/github/hubot/tree/master/docs) for further guidance on how to build your bot

#### Testing your bot locally

- `HUBOT_BEARYCHAT_TOKENS=TOKEN1,TOKEN2 ./bin/hubot -a bearychat`

## Configuration

This adapter uses the following environment variables:

 - `HUBOT_BEARYCHAT_TOKENS` - these are hubot tokens in BearyChat, multi tokens are separated by comma

## Copyright

Copyright &copy; Beary Innovative Technologies, Inc.
