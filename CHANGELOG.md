----
- Name: hubot-bearychat
----
# 0.7.2 / 2017-06-09

- 修复 attachment 不能发送的问题

# 0.7.1 / 2017-06-07

- 修复普通类型消息不能发送的问题

# 0.7.0 / 2017-06-07

## Added

- 支持 `robot.messageRoom` 方法


# 0.6.0 / 2017-05-16

## Added

- 增加断线重连功能

# 0.5.2 / 2017-05-12

## Added

- 增加断线重连功能

## Fixed

- 修复转换用户 ID 编码的逻辑错误

# 0.5.1 / 2017-04-20

## Added

- 修改 `robot.send` 行为，由带引用变为不带引用。
- 修改 `robot.reply` 行为，由带 @ 变为不带 @。

# 0.5.0 / 2017-03-30

## Added

- 更新 bearychat.js 到 1.0.0
- #20 #12 支持发送 attachment 类型消息

# 0.4.2 / 2017-03-23

## Fixed

- #19 fix(http_client): missing mention sign

# 0.4.1 / 2017-03-16

## Fixed

- #17 添加缺少的 `EventClosed` 常量

# 0.4.0 / 2017-02-23

## Added

- 支持发送 attachemnt #14

# 0.3.1 / 2017-01-24

## Fixed

- #10

# 0.3.0 / 2017-01-21

## Added

- 添加 rtm 模式实现

# 0.2.2 / 2016-08-26

## Added

- 初始版本
