GeometryImportFields =

  importFieldHandler: (fileNode, template, args) ->
    args = _.extend({
      acceptedFormats: Object.keys(AssetUtils.formats)
      merge: false
    }, args)
    acceptedFormats = args.acceptedFormats
    file = fileNode.files[0]
    unless file
      throw new Error('No file selected for uploading')
    mimeType = file.type
    format = _.find AssetUtils.formats, (format) -> format.mimeType == mimeType
    unless format
      throw new Error('Format not recognised for mime-type: ' + file.type)
    formatId = format.id
    if _.indexOf(acceptedFormats, formatId) >= 0
      $submitButton = template.$('.submit.button')
      $loader = $(fileNode).siblings('.ui.dimmer')
      setSubmitButtonDisabled = (disabled) ->
        $submitButton.toggleClass('disabled', disabled)
        $submitButton.prop('disabled', disabled)
      onUploadStart = ->
        $loader.addClass('active')
        setSubmitButtonDisabled(true)
      onUploadComplete = ->
        $loader.removeClass('active')
        setSubmitButtonDisabled(false)
      onUploadStart()
      _.extend(args, {format: formatId})
      Files.upload(file).then(
        (fileObj) => @onUpload(fileObj, template, args).fin(onUploadComplete)
        onUploadComplete
      )
    else
      console.error('File did not match expected format', file, format, acceptedFormats)

  onUpload: (fileObj, template, args) ->
    console.debug 'uploaded', fileObj
    df = Q.defer()
    fileId = fileObj._id
    AssetUtils.fromFile(fileId, args).then(
      (result) =>
        c3mls = result.c3mls
        isPolygon = (c3ml) -> AtlasConverter.sanitizeType(c3ml.type) == 'polygon'
        isCollection = (c3ml) -> AtlasConverter.sanitizeType(c3ml.type) == 'collection'
        uploadIsPolygon = _.every c3mls, (c3ml) -> isPolygon(c3ml) || isCollection(c3ml)
        paramId = if uploadIsPolygon then 'geom_2d' else 'geom_3d'
        uploadNotEmpty = _.some c3mls, (c3ml) -> !isCollection(c3ml)
        unless uploadNotEmpty
          throw new Error('File must contain at least one c3ml entity other than a collection.')
        filename = fileObj.name()
        $geomInput = $(template.find('[name="parameters.space.' + paramId + '"]'))
        $geomFilenameInput = $(template.find('[name="parameters.space.' + paramId + '_filename"]'))
        # Upload the c3ml as a file.
        doc = {c3mls: c3mls}
        docString = JSON.stringify(doc)
        blob = new Blob([docString])
        Files.upload(blob).then (fileObj) ->
          id = fileObj._id
          $geomInput.val(id)
          $geomFilenameInput.val(filename).trigger('change')
          df.resolve(id)
      (err) -> df.reject(err)
    )
    df.promise