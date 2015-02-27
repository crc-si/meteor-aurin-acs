Assets =

  fromFile: (fileId, args) ->
    df = Q.defer()
    Meteor.call 'assets/from/file', fileId, (err, result) =>
      @_fromUploadResult(err, result, args).then(df.resolve, df.reject)
    df.promise

  fromBlob: (blob, args) ->
    df = Q.defer()
    formData = new FormData()
    formData.append('fieldName', blob, args.filename)
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

  formats:
    shp:
      id: 'shp'
      mimeType: 'application/zip'
    kmz:
      id: 'kmz'
      mimeType: 'application/vnd.google-earth.kmz'
