AssetUtils =

  fromFile: (fileId, args) ->
    buffer = FileUtils.getBuffer(fileId)
    fileObj = Files.findOne(fileId)
    file = fileObj.original
    args = _.extend({
      filename: file.name
      contentType: file.type
      knownLength: file.size
    }, args)
    @fromBuffer(buffer, args)

  fromBuffer: (buffer, args) ->
    result = AssetConversionService.convert(buffer, args)
    {c3mls: result.c3mls}

Meteor.methods

  'assets/from/file': AssetUtils.fromFile.bind(AssetUtils)

bindMeteor = Meteor.bindEnvironment.bind(Meteor)

# HTTP SERVER

# Limit buffering size to 100 MB.
HTTP.methodsMaxDataLength = 1024 * 1024 * 100

HTTP.methods

  '/assets/upload':
    post: (requestData) ->
      Logger.info('Uploading asset for conversion...')
      headers = @requestHeaders
      @addHeader('Content-Type', 'application/json')
      result = Promises.runSync (done) ->
        stream = Meteor.npmRequire('stream')
        formResult = null
        formidable = Meteor.npmRequire('formidable')
        IncomingForm = formidable.IncomingForm
        # Override to prevent storing any files and read the buffer data directly.
        origHandlePart = IncomingForm.prototype.handlePart
        IncomingForm.prototype.handlePart = (part) ->
          filename = part.filename
          unless filename
            # Ensure non-file fields are also included.
            origHandlePart.apply(@, arguments)
            return
          bufs = []
          part.on 'data', (chunk) ->
            bufs.push(chunk)
          part.on 'end', ->
            buffer = Buffer.concat(bufs)
            formResult =
              buffer: buffer
              mime: part.mime
              filename: filename
        form = new IncomingForm()
        reader = new stream.Readable()
        # Prevent "not implemented" errors.
        reader._read = ->
        reader.headers = headers
        form.parse reader, (err, fields, files) ->
          _.extend(formResult, fields)
          if err then done(err, null) else done(null, formResult)
        reader.push(requestData)
        reader.push(null)
      Logger.info('Uploaded asset for conversion', result)
      buffer = result.buffer
      args =
        filename: result.filename
        contentType: result.mime,
        knownLength: buffer.length
        merge: Booleans.parse(result.merge)

      fileUploadPromise = Q.when()
      if result.storeFile
        Logger.info('Storing uploaded asset...')
        file = new FS.File()
        file.attachData(buffer, type: result.mime)
        file.name(result.filename)
        fileUploadPromise = Files.upload(file)
      
      result = Promises.runSync (done) ->
        fileUploadPromise.then(
          bindMeteor (fileObj) ->
            fileId = fileObj && fileObj._id
            if fileId
              Logger.info('Uploaded file for conversion', fileId)
            if Booleans.parse(result.convert) == false
              asset = {fileId: fileId}
              done(null, asset)
            else
              try
                asset = AssetUtils.fromBuffer(buffer, args)
                if fileId
                  asset.fileId = fileId
                Logger.info('Asset creation succeeded')
                done(null, asset)
              catch e
                asset = {error: e.toString()}
                Logger.error('Asset creation failed', e)
                done(e, null)
          (err) -> done(err, null)
        )
        # TODO(aramk) Prevent Promises from handling outcome since return isn't working
        return undefined
      JSON.stringify(result)
