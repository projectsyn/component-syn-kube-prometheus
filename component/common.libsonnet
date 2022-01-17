local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local com = import 'lib/commodore.libjsonnet';
// The hiera parameters for the component
local params = inv.parameters.kube_prometheus;

// map from component parameters key to kube-prometheus key
local componentMap = {
  alertmanager: 'alertmanager',
  blackbox_exporter: 'blackboxExporter',
  grafana: 'grafana',
  kubernetes_control_plane: 'kubernetesControlPlane',
  kube_state_metrics: 'kubeStateMetrics',
  node_exporter: 'nodeExporter',
  prometheus: 'prometheus',
  prometheus_adapter: 'prometheusAdapter',
  prometheus_operator: 'prometheusOperator',
};

local render_component(component, prefix) =
  local kpkey = componentMap[component];
  local kp =
    (import 'kube-prometheus/main.libsonnet') {
      values+:: {
        common+: {
          namespace: params.namespace,
        },
      },

      [kpkey]+: com.makeMergeable(params[component].params),
    };

  {
    ['%d_%s_%s' % (prefix, component, name)]: kp[kpkey][name]
    for name in std.objectFields(kp[kpkey])
  };

{
  render_component: render_component,
}
