AssetUtils =

  fromFile: (fileId, args) ->
    df = Q.defer()
    Meteor.call 'assets/from/file', fileId, args, (err, result) =>
      @_fromUploadResult(err, result, args).then(df.resolve, df.reject)
    df.promise

  fromBlob: (blob, args) ->
    args = _.extend({
      merge: false
    }, args)
    df = Q.defer()
    formData = new FormData()
    formArgs = Setter.clone(args)
    formData.append('file', blob, formArgs.filename)
    delete formArgs.filename
    _.each formArgs, (value, key) ->
      formData.append(key, value)
    xhr = new XMLHttpRequest()
    # Need to bind since we need to retain original context in XHR callbacks to obtain response.
    fromUploadResult = @_fromUploadResult.bind(@)
    xhr.onload = (e) ->
      console.log('onload', @, arguments)
      if @status >= 400
        df.reject(@response)
      else
        fromUploadResult(null, @response, args).then(df.resolve, df.reject)
    xhr.onerror = (e) ->
      console.log('onerror', @, arguments)
      df.reject(e.error)
    xhr.responseType = 'json'
    xhr.open('POST', '/assets/upload')
    xhr.send(formData)
    df.promise

  _fromUploadResult: (err, result, args) ->
    df = Q.defer()
    if err then df.reject(err) else df.resolve(result)
    df.promise

  hasExtension: (filename, extension) ->
    extension = extension.replace(/^\./, '')
    matches = filename.match(/\.([^./]*)$/)
    return false unless matches
    matches[1].toLowerCase() == extension.toLowerCase()

  getFileFormat: (file) ->
    _.find _.keys(@formats), (formatId) => @formats[formatId].isOfType?(file)

  formats:
    shp:
      isOfType: (file) ->
        AssetUtils.hasExtension(file.name, 'zip') || file.type.indexOf('zip') >= 0
    kmz:
      isOfType: (file) ->
        AssetUtils.hasExtension(file.name, 'kmz') || file.type == 'application/vnd.google-earth.kmz'
