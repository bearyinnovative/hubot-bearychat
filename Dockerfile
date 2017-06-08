#
# hubot-bearychat
#
#   sources.list:
#       http://mirrors.163.com/.help/sources.list.trusty
#

FROM ubuntu:14.04

LABEL maintainer "teachmyself@126.com"

ENV TIMEZONE "Asia/Shanghai"

ENV HUBOT_BEARYCHAT_TOKENS "houbot_bearychat_tokens"
ENV HUBOT_BEARYCHAT_MODE "rtm"

ENV ACCESSKEYID "AccessKeyId"
ENV ACCESSKEYSECRET "AccessKeySecret"

Add sources.list.trusty /etc/apt/sources.list

RUN apt-get -y update && \
    apt-get -y install telnet iputils-ping wget curl vim && \
    apt-get autoremove && \
    apt-get clean all && \
    mkdir -p /home/ubuntu /hubot && useradd -d /home/ubuntu ubuntu && \
    touch /home/ubuntu/.bash_profile && \
    chown -R ubuntu /home/ubuntu /hubot 

USER ubuntu

RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash && \
    export NVM_DIR="$HOME/.nvm" && \
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && \
    nvm install stable && \
    npm install -g hubot coffee-script yo generator-hubot && \
    mkdir -p /hubot && \
    cd /hubot && \
    find $HOME/.nvm/ -type d -name bin -exec chmod +x {} \; && \
    yo hubot && \
    npm install hubot-bearychat --save


WORKDIR /hubot

CMD "./bin/hubot -a bearychat"


