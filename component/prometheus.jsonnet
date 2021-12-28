local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local com = import 'lib/commodore.libjsonnet';
// The hiera parameters for the component
local params = inv.parameters.kube_prometheus;

local kp =
  (import 'kube-prometheus/main.libsonnet') {
    values+:: {
      common+: {
        namespace: params.namespace,
      },
    },

    prometheus+: com.makeMergeable(params.prometheus.params),
  };

{
  ['20_prometheus-' + name]: kp.prometheus[name]
  for name in std.objectFields(kp.prometheus)
}
