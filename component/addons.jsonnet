local kap = import 'lib/kapitan.libjsonnet';

local imports = kap.dir_files_list('kube-prometheus/addons/');

local trimSuffix = function(pat, str)
  if std.endsWith(str, pat) then
    std.substr(str, 0, std.length(str) - std.length(pat))
  else
    str;

local renderedImports =
  '{' +
  std.join(',\n', std.map(
    function(name) '%s: import %s' % [
      std.escapeStringJson(trimSuffix('.libsonnet', name)),
      std.escapeStringJson('kube-prometheus/addons/' + name),
    ],
    imports
  ))
  + '}'
;


{ 'addons.libsonnet': renderedImports }
