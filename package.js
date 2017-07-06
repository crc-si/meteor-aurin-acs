Package.describe({
  name: 'crc4si:aurin-acs',
  summary: 'Adapter for Asset Conversion Service (ACS).',
  git: 'https://github.com/crc-si/meteor-aurin-acs.git',
  version: '0.1.5'
});

Npm.depends({
  'request': '2.37.0',
  'formidable': '1.0.15'
});

Package.on_use(function(api) {
  api.versionsFrom('METEOR@0.9.0');
  api.use([
    'coffeescript',
    'underscore',
    'urbanetic:utility@1.2.3',
    'crc4si:file-upload@0.4.0',
    'crc4si:bismuth-utility@0.1.0'
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
    'src/server/AssetUtils.coffee'
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
    'AssetUtils'
  ], 'server');
});
