env = process.env
useLocalServer = env.ACS_ENV == 'local'

if useLocalServer
  console.log('Using local ACS server')

SERVER_LOCAL_URL = 'http://localhost:8090/'
SERVER_REMOTE_URL = 'http://acs.urbanetic.net/'
SERVER_URL = if useLocalServer then SERVER_LOCAL_URL else SERVER_REMOTE_URL

request = Meteor.npmRequire('request')

AssetConversionService =

  convert: (buffer, args) ->
    args ?= {}
    Promises.runSync (done) ->
      r = request.post Request.mergeOptions({
        url: SERVER_URL + 'convert'
        # Adding headers causes issues with Jersey.
        headers: null
        jar: true
      }), (err, httpResponse, body) ->
        if err
          done(err, null)
          return
        try
          json = JSON.parse(body)
          done(null, json)
        catch e
          console.log('Error when parsing asset upload. Content was not JSON:', body)
          done(e, null)
      form = r.form()
      # Accepts "filename" in args.
      form.append('file', buffer, {filename: args.filename})
      merge = args.merge
      if merge
        form.append('merge', 'true')
