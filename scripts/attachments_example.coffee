# Description:
#   Example scripts for you to examine attachments and try out.
#
# Commands:
#   hubot attachments - show you one attachments format message

module.exports = (robot) ->

  robot.respond /attachments/i, (res) ->
    text = "text, this field accept `markdown`"
    attachments = [{
      title: "attachment title",
      text: "attachment text",
      color: "#ffa500",
      images: [{url: "http://img7.doubanio.com/icon/ul15067564-30.jpg"}]
    }]
    # res.reply text, attachments
    res.send text, attachments
