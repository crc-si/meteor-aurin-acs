env = process.env
useLocalServer = env.ACS_ENV == 'local'

if useLocalServer
  console.log('Using local ACS server')

SERVER_LOCAL_URL = 'http://localhost:8090/'
SERVER_REMOTE_URL = 'http://acs.urbanetic.net/'
SERVER_URL = if useLocalServer then SERVER_LOCAL_URL else SERVER_REMOTE_URL

request = Meteor.npmRequire('request')
# NOTE: Enable this to log all requests and responses.
# Meteor.npmRequire('request-debug')(request)

AssetConversionService =

  # @param {Buffer} buffer - A buffer containing the file data to convert in the supported formats.
  #     E.g. (SHP, KMZ).
  # @param {Object} args
  # @param {String} args.filename - The name of the file to convert.
  # @param {Boolean} args.merge - Whether to convert the file into a single GLTF mesh.
  # @returns {Object} The JSON result of the conversion.
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
      form.append('file', buffer, {filename: args.filename})
      merge = args.merge
      if merge == true
        form.append('merge', 'true')

  # @param {Object} c3mlData - A JSON object containing the C3ML data to convert to the supported
  #     formats. E.g. (KMZ). Expects a "c3mls" property to exist containing an array of C3ML
  #     entities.
  # @returns {Buffer} A buffer containing the exported data.
  export: (c3mlData) ->
    Request.call
      url: SERVER_URL + 'convert/export'
      method: 'POST'
      body: JSON.stringify(c3mlData)
      # Adding headers causes issues with Jersey.
      headers:
        'Content-Type': 'application/json'
        # This is necessary to prevent sending JSON as the accept header.
        'Accept': '*/*'
      encoding: null
      jar: false
