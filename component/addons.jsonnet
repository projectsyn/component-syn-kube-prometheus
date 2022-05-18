local kap = import 'lib/kapitan.libjsonnet';

local upstreamAddons = kap.dir_files_list('kube-prometheus/addons/');
local localAddons = kap.dir_files_list('syn-kube-prometheus/component/addons/');

local trimSuffix = function(pat, str)
  if std.endsWith(str, pat) then
    std.substr(str, 0, std.length(str) - std.length(pat))
  else
    str;

local formatAddon = function(dir, file)
  '%s: import %s' % [
    std.escapeStringJson(trimSuffix('.libsonnet', file)),
    std.escapeStringJson(dir + file),
  ];

local renderedImports =
  '{' +
  std.join(
    ',\n',
    std.map(
      function(file) formatAddon('kube-prometheus/addons/', file),
      upstreamAddons
    ) + std.map(
      function(file) formatAddon('syn-kube-prometheus/component/addons/', file),
      localAddons
    ),
  )
  + '}'
;

{ 'addons.libsonnet': renderedImports }
