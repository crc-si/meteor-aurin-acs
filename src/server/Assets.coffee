Assets =

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
    c3mls = AssetConversionService.convert(buffer, args)
    {c3mls: c3mls}

Meteor.methods

  'assets/from/file': Assets.fromFile.bind(Assets)

# HTTP SERVER

# Limit buffering size to 100 MB.
HTTP.methodsMaxDataLength = 1024 * 1024 * 100

HTTP.methods

  '/assets/upload':
    post: (requestData) ->
      headers = @requestHeaders
      @addHeader('Content-Type', 'application/json')
      data = Promises.runSync (done) ->
        stream = Meteor.npmRequire('stream')
        formidable = Meteor.npmRequire('formidable')
        IncomingForm = formidable.IncomingForm
        IncomingForm.prototype.handlePart = (part) ->
          filename = part.filename
          # Ignore fields and only handle files.
          unless filename
            return
          bufs = []
          # TODO(aramk) Use utility method for this.
          part.on 'data', (chunk) ->
            bufs.push(chunk)
          part.on 'end', ->
            buffer = Buffer.concat(bufs)
            done(null, {
              buffer: buffer,
              mime: part.mime
              filename: filename
            })
        form = new IncomingForm()
        reader = new stream.Readable()
        # Prevent "not implemented" errors.
        reader._read = ->
        reader.headers = headers
        form.parse reader, (err, fields, files) -> done(err, null) if err
        reader.push(requestData)
        reader.push(null)
      buffer = data.buffer
      asset = Assets.fromBuffer(buffer, {
        filename: data.filename
        contentType: data.mime,
        knownLength: buffer.length
      })
      JSON.stringify(asset)

  # '/assets/download/:id':
  #   get: (requestData) ->
  #     id = this.params.id
  #     Catalyst.auth.login()
  #     asset = Catalyst.assets.get(id)
  #     unless asset
  #       throw new Meteor.Error(404, 'Asset with ID ' + id + ' not found')
  #     @addHeader('Content-Type', asset.mimeType)
  #     @addHeader('Content-Disposition', 'attachment; filename="' + asset.fileName + '.' +
  #         asset.format + '"; size="' + asset.fileSize + '"')
  #     buffer = Catalyst.assets.downloadBuffer(id)
  #     stream = Meteor.npmRequire('stream')
  #     reader = new stream.Readable()
  #     reader._read = ->
  #     res = @createWriteStream()
  #     reader.pipe(res)
  #     reader.push(buffer)
  #     reader.push(null)
