local kap = import 'lib/kapitan.libjsonnet';

local upstreamAddonsDir = 'kube-prometheus/addons/';
local localAddonsDir = 'prometheus/component/addons/';

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
      function(file) formatAddon(upstreamAddonsDir, file),
      kap.dir_files_list(upstreamAddonsDir)
    ) + std.map(
      function(file) formatAddon(localAddonsDir, file),
      kap.dir_files_list(localAddonsDir)
    ),
  )
  + '}'
;

{ 'addons.libsonnet': renderedImports }
