local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.prometheus;

local ruleFilter(group) =
  // merge user-provided and hard-coded rule names to filter out
  local ignoreSet = std.set(com.renderArray(params.addon_configs.disable_alerts.ignoreNames));

  // return group object, with filtered rules list
  group {
    rules: std.filter(
      function(rule)
        // never filter rules which don't have the `alert` field, those are
        // probably recording rules.
        !std.objectHas(rule, 'alert') ||
        // filter out rules which are in our set of rules to ignore
        !std.member(ignoreSet, rule.alert),
      group.rules
    ),
  };

local components = [
  'alertmanager',
  'blackboxExporter',
  'grafana',
  'kubernetesControlPlane',
  'kubePrometheus',
  'kubeStateMetrics',
  'nodeExporter',
  'prometheusAdapter',
  'prometheusOperator',
  'prometheus',
];

std.foldl(function(obj, name) obj {
  [name]+: {
    prometheusRule+: {
      spec+: {
        local g = super.groups,
        groups: std.map(
          ruleFilter,
          g
        ),
      },
    },
  },
}, components, {})
