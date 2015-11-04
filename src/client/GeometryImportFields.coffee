GeometryImportFields =

  importFieldHandler: (fileNode, template, args) ->
    args = _.extend
      acceptedFormats: Object.keys(AssetUtils.formats)
      merge: false,
      getGeomInput: (template, paramId) ->
        $(template.find('[name="parameters.space.' + paramId + '"]'))
      getFilenameInput: (template, paramId) ->
        $(template.find('[name="parameters.space.' + paramId + '_filename"]'))
    , args
    acceptedFormats = args.acceptedFormats
    file = fileNode.files[0]
    unless file
      alert('No file selected for uploading')
      retrun
    mimeType = file.type
    formatId = AssetUtils.getFileFormat(file)
    unless formatId
      alert('Format not recognised for file.')
      return
    unless _.indexOf(acceptedFormats, formatId) >= 0
      alert('File of type "' + formatId + '" did not match expected formats: ' + acceptedFormats)
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

  onUpload: (fileObj, template, args) ->
    args = _.extend
      getParamId: (args) -> if args.uploadIsPolygon then 'geom_2d' else 'geom_3d'
    , args
    console.debug 'uploaded', fileObj
    df = Q.defer()
    fileId = fileObj._id
    promise = AssetUtils.fromFile(fileId, args)
    promise.fail(df.reject)
    promise.then (result) ->
      c3mls = result.c3mls
      isPolygon = (c3ml) -> AtlasConverter.sanitizeType(c3ml.type) == 'polygon'
      isCollection = (c3ml) -> AtlasConverter.sanitizeType(c3ml.type) == 'collection'
      uploadIsPolygon = _.every c3mls, (c3ml) -> isPolygon(c3ml) || isCollection(c3ml)
      paramId = args.getParamId({c3mls: c3mls, uploadIsPolygon: uploadIsPolygon})
      uploadNotEmpty = _.some c3mls, (c3ml) -> !isCollection(c3ml)
      unless uploadNotEmpty
        alert('File must contain at least one c3ml entity other than a collection.')
        return
      filename = fileObj.name()
      $geomInput = args.getGeomInput(template, paramId)
      $geomFilenameInput = args.getFilenameInput(template, paramId)
      # Upload the c3ml as a file.
      doc = {c3mls: c3mls}
      docString = JSON.stringify(doc)
      blob = new Blob([docString])
      Files.upload(blob).then (fileObj) ->
        id = fileObj._id
        $geomInput.val(id)
        $geomFilenameInput.val(filename).trigger('change')
        df.resolve(id)
    df.promise
