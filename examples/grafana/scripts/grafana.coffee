#http://docs.grafana.org/reference/http_api/

crypto  = require 'crypto'
request = require 'request'
AWS = require 'aws-sdk'

module.exports = (robot) ->
  grafana_host = process.env.HUBOT_GRAFANA_HOST
  grafana_api_key = process.env.HUBOT_GRAFANA_API_KEY
  grafana_query_time_range = '24h'

  s3_bucket = process.env.HUBOT_GRAFANA_S3_BUCKET
  s3_access_key = process.env.HUBOT_GRAFANA_S3_ACCESS_KEY
  s3_secret_key = process.env.HUBOT_GRAFANA_S3_SECRET_KEY
  s3_region = process.env.HUBOT_GRAFANA_S3_REGION

  robot.respond /(?:grafana|graph|graf) ([A-Za-z0-9\-\:_]+)(.*)?/i, (msg) ->
    slug = msg.match[1]
    remainder = msg.match[2]

    {envelope} = msg
    {user, message} = envelope
    {id, vchannel, team, id, token, sender, name} = user

    msg.reply 'wait a sec, señor'
    timespan = {
      from: "now-#{grafana_query_time_range}"
      to: 'now'
    }

    variables = ''
    template_params = []
    visualPanelId = false
    apiPanelId = false
    pname = false

    # Parse out a specific panel
    if /\:/.test slug
      parts = slug.split(':')
      slug = parts[0]
      visualPanelId = parseInt parts[1], 10
      if isNaN visualPanelId
        visualPanelId = false
        pname = parts[1].toLowerCase()
      if /panel-[0-9]+/.test pname
        parts = pname.split('panel-')
        apiPanelId = parseInt parts[1], 10
        pname = false

    # Check if we have any extra fields
    if remainder
      # The order we apply non-variables in
      timeFields = ['from', 'to']

      for part in remainder.trim().split ' '
        # Check if it's a variable or part of the timespan
        if part.indexOf('=') >= 0
          variables = "#{variables}&var-#{part}"
          template_params.push { "name": part.split('=')[0], "value": part.split('=')[1] }

        # Only add to the timespan if we haven't already filled out from and to
        else if timeFields.length > 0
          timespan[timeFields.shift()] = part.trim()

    # Call the API to get information about this dashboard
    callGrafana "dashboards/db/#{slug}", (dashboard) ->

      # Check dashboard information
      if !dashboard
        return sendError 'An error ocurred. Check your logs for more details.', msg
      if dashboard.message
        return sendError dashboard.message, msg

      if dashboard.dashboard
        data = dashboard.dashboard
        apiEndpoint = 'dashboard-solo'

      # Support for templated dashboards
      if data.templating.list
        template_map = []
        for template in data.templating.list
          robot.logger.debug template
          continue unless template.current
          for _param in template_params
            if template.name == _param.name
              template_map['$' + template.name] = _param.value
            else
              template_map['$' + template.name] = template.current.text

      # Return dashboard rows

      panelNumber = 0
      for row in data.rows
        for panel in row.panels
          panelNumber += 1

          # Skip if visual panel ID was specified and didn't match
          if visualPanelId && visualPanelId != panelNumber
            continue

          # Skip if API panel ID was specified and didn't match
          if apiPanelId && apiPanelId != panel.id
            continue

          # Skip if panel name was specified any didn't match
          if pname && panel.title.toLowerCase().indexOf(pname) is -1
            continue

          # Build links for message sending
          title = formatTitleWithTemplate(panel.title, template_map)
          imageUrl = "#{grafana_host}/render/#{apiEndpoint}/db/#{slug}/?panelId=#{panel.id}&width=1000&height=500&from=#{timespan.from}&to=#{timespan.to}#{variables}"
          link = "#{grafana_host}/dashboard/db/#{slug}/?panelId=#{panel.id}&fullscreen&from=#{timespan.from}&to=#{timespan.to}#{variables}"

          # Fork here for S3-based upload and non-S3
          if (s3_bucket && s3_access_key && s3_secret_key)
            fetchAndUpload msg, imageUrl, title, vchannel, link


  sendBack = (response,text,vchannel,imgURL,dashboardURL) ->
    images = [{'url': imgURL}]
    markdownTitle = "[#{dashboardURL}](#{dashboardURL})"
    attachments = [{'title'  : text,'text' :'', 'color'  : 'green','images' : images}]
    opts = {markdown:true, attachments:attachments}
    response.send  markdownTitle, opts

  # Get a list of available dashboards
  robot.hear /(?:grafana|graph|graf) list\s?(.+)?/i, (msg) ->
    if msg.match[1]
      tag = msg.match[1].trim()
      callGrafana "search?tag=#{tag}", (dashboards) ->
        response = "Dashboards tagged `#{tag}`:\n"
        sendDashboardList dashboards, response, msg
    else
      callGrafana 'search', (dashboards) ->
        response = "Available dashboards:\n"
        sendDashboardList dashboards, response, msg

  # Search dashboards
  robot.hear /(?:grafana|graph|graf) search (.+)/i, (msg) ->
    query = msg.match[1].trim()
    callGrafana "search?query=#{query}", (dashboards) ->
      response = "Dashboards matching `#{query}`:\n"
      sendDashboardList dashboards, response, msg

  # Send Dashboard list
  sendDashboardList = (dashboards, response, msg) ->
    # Handle refactor done for version 2.0.2+
    if dashboards.dashboards
      list = dashboards.dashboards
    else
      list = dashboards

    unless list.length > 0
      return

    for dashboard in list
      # Handle refactor done for version 2.0.2+
      if dashboard.uri
        slug = dashboard.uri.replace /^db\//, ''
      else
        slug = dashboard.slug
      response = response + "- #{slug}: #{dashboard.title}\n"

    # Remove trailing newline
    response.trim()

    msg.send response

  # Handle generic errors
  sendError = (message, msg) ->
    robot.logger.error message
    msg.send message

  # Format the title with template vars
  formatTitleWithTemplate = (title, template_map) ->
    title.replace /\$\w+/g, (match) ->
      if template_map[match]
        return template_map[match]
      else
        return match

  # Call off to Grafana
  callGrafana = (url, callback) ->
    if grafana_api_key
      authHeader = {
        'Accept': 'application/json',
        'Authorization': "Bearer #{grafana_api_key}"
      }
    else
      authHeader = {
        'Accept': 'application/json'
      }
    robot.http("#{grafana_host}/api/#{url}").headers(authHeader).get() (err, res, body) ->
      if (err)
        robot.logger.error err
        return callback(false)
      data = JSON.parse(body)
      return callback(data)

  getS3SignedPUTURL = () ->
    AWS.config.update {"accessKeyId" : s3_access_key, "secretAccessKey" : s3_secret_key}
    AWS.config.update {"region": s3_region}
    s3 = new AWS.S3 {params : {Bucket : s3_bucket}}

    # generate random filename
    filename = "#{crypto.randomBytes(20).toString('hex')}.png"
    imageData = {Key: filename, ACL: 'public-read', ContentType: 'image/png'}
    postURL = s3.getSignedUrl 'putObject', imageData;
    postURL

  # Fetch an image from provided URL, upload it to S3, returning the resulting URL
  fetchAndUpload = (response,url, text, vchannel, link) ->
    if grafana_api_key
        requestHeaders =
          encoding: null,
          auth:
            bearer: grafana_api_key
      else
        requestHeaders =
          encoding: null

    postURL = getS3SignedPUTURL()
    imgURL = postURL.substring(0,postURL.indexOf('?'))

    request url, requestHeaders, (err, res, body) ->
      robot.logger.debug "Uploading file: #{body.length} bytes, content-type[#{res.headers['content-type']}]"
      uploadToS3(response,postURL, body, body.length, res.headers['content-type'],text, vchannel,imgURL ,link)


  # Upload image to S3
  uploadToS3 = (response, postURL, content, length, content_type, text, vchannel,imgURL ,link) ->
    request {method: "PUT",url: postURL,body: content, 'Content-Type': content_type},
            (err, res, body) ->
              if err == null
                sendBack response,text,vchannel,imgURL,link
