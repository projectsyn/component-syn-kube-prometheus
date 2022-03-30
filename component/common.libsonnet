local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local com = import 'lib/commodore.libjsonnet';
// The hiera parameters for the component
local params = inv.parameters.syn_kube_prometheus;
local global = inv.parameters.global;
local instance = inv.parameters._instance;

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

local patch_image(key, image) =
  local parts = std.split(image, '/');
  if parts[0] == 'docker.io' then
    global.registries.dockerhub + '/' + std.join('/', parts[1:])
  else if parts[0] == 'quay.io' then
    global.registries.quay + '/' + std.join('/', parts[1:])
  else if parts[0] == 'k8s.gcr.io' then
    global.registries.k8s_gcr + '/' + std.join('/', parts[1:])
  else
    global.registries.dockerhub + '/' + std.join('/', parts)
;

local render_component(component, prefix) =
  local kpkey = componentMap[component];
  local kp =
    (import 'kube-prometheus/main.libsonnet') +
    (import 'kube-prometheus/addons/podsecuritypolicies.libsonnet') {   
      values+:: {
        common+: {
          namespace: params.namespace,
          images: std.mapWithKey(patch_image, super.images),
        } + com.makeMergeable(params.common) + com.makeMergeable(params[component].common),
        [kpkey]+: {name: std.asciiLower(kpkey + '-' + instance) } + com.makeMergeable(params[component].config),
      },
      [kpkey]+: com.makeMergeable(params[component].params),
    };

  {
    ['%d_%s_%s' % [ prefix, component, name ]]: kp[kpkey][name]
    for name in std.objectFields(kp[kpkey])
  };

{
  render_component: render_component,
}
