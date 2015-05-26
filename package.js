Package.describe({
  name: 'urbanetic:aurin-acs',
  summary: 'Adapter for Asset Conversion Service (ACS).',
  git: 'https://github.com/urbanetic/meteor-aurin-acs.git',
  version: '0.1.3'
});

Package.on_use(function(api) {
  api.versionsFrom('METEOR@0.9.0');
  api.use([
    'coffeescript',
    'underscore',
    'aramk:utility@0.6.0',
    'aramk:file-upload@0.4.0'
  ], ['client', 'server']);
  api.use([
    'meteorhacks:npm@1.2.2',
    'cfs:http-methods@0.0.27'
  ], 'server');
  api.addFiles([
    'src/common/AssetUtils.coffee'
  ], ['client', 'server']);
  api.addFiles([
    'src/client/AssetUtils.coffee',
    'src/client/GeometryImportFields.coffee'
  ], 'client');
  api.addFiles([
    'src/server/AssetConversionService.coffee',
    'src/server/AssetUtils.coffee',
    'src/server/Request.coffee'
  ], 'server');
  api.export([
    'AssetUtils',
  ], ['client', 'server']);
  api.export([
    'AssetUtils',
    'GeometryImportFields'
  ], 'client');
  api.export([
    'AssetConversionService',
    'AssetUtils',
    'Request'
  ], 'server');
});
