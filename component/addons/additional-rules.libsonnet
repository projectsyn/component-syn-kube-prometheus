local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local prom = import 'lib/prom.libsonnet';
local inv = kap.inventory();
local params = inv.parameters.prometheus;
{
  prometheus+: {
    prometheusRule+: {
      spec+: {
        groups+: [
          {
            name: group_name,
            rules: [
              local rnamekey =
                local k = std.splitLimit(rname, ':', 1);
                assert std.member([ 'alert', 'record' ], k[0]) : 'Invalid custom rule key "%s", the component expects that custom rule keys are prefixed with either "alert:" or "record:"' % [ rname ];
                k;
              params.addon_configs.additional_rules[group_name][rname] {
                [rnamekey[0]]: rnamekey[1],
              }
              for rname in std.objectFields(params.addon_configs.additional_rules[group_name])
              if params.addon_configs.additional_rules[group_name][rname] != null
            ],
          }
          for group_name in std.objectFields(params.addon_configs.additional_rules)
          if params.addon_configs.additional_rules[group_name] != null
        ],
      },
    },
  },
}
