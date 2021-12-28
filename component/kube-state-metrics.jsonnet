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

    kubeStateMetrics+: com.makeMergeable(params.kube_state_metrics.params),
  };

{
  ['82_kube-state-metrics-' + name]: kp.kubeStateMetrics[name]
  for name in std.objectFields(kp.kubeStateMetrics)
}
