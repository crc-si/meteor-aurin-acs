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

# HTTP SERVER

# Limit buffering size to 100 MB.
HTTP.methodsMaxDataLength = 1024 * 1024 * 100

HTTP.methods

  '/assets/upload':
    post: (requestData) ->
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
      buffer = result.buffer
      asset = AssetUtils.fromBuffer(buffer, {
        filename: result.filename
        contentType: result.mime,
        knownLength: buffer.length
        merge: result.merge
      })
      JSON.stringify(asset)
