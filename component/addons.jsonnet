local kap = import 'lib/kapitan.libjsonnet';

local template = importstr 'main.jsonnet';
local imports = kap.dir_files_list('kube-prometheus/addons/');

local trimSuffix = function(pat, str)
  if std.endsWith(str, pat) then
    std.substr(str, 0, std.length(str) - std.length(pat))
  else
    str;

local renderedImports =
  'local imports = {' +
  std.join(',\n', std.map(
    function(name) '%s: import %s' % [
      std.escapeStringJson(trimSuffix('.libsonnet', name)),
      std.escapeStringJson('kube-prometheus/addons/' + name),
    ],
    imports
  ))
  + '};'
;

local find = '// %% ADDONS';
local x = std.findSubstr(find, template);

assert std.length(x) == 2 : 'template must contain // %% ADDONS';

local addonsInserted =
  std.substr(template, 0, x[0])
  + renderedImports
  + std.substr(template, x[1] + std.length(find), std.length(template))
;

{ 'with-addons.jsonnet': addonsInserted }
