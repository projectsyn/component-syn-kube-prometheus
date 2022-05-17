local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local com = import 'lib/commodore.libjsonnet';
// The hiera parameters for the component
local params = inv.parameters.syn_kube_prometheus;

local global = com.getValueOrDefault(inv.parameters, 'global', {
  registries: {
    dockerhub: 'docker.io',
    quay: 'quay.io',
    k8s_gcr: 'k8s.gcr.io',
  },
});

// local test = std.trace(import 'compiled/syn-kube-prometheus/with-addons.jsonnet');

local commonLabels = {
  'app.kubernetes.io/managed-by': 'commodore',
  'app.kubernetes.io/part-of': 'syn',
};

local commonAnnotations = {
  source: 'https://github.com/projectsyn/component-syn-kube-prometheus',
};

local commonMetadata = {
  labels+: commonLabels,
  annotations+: commonAnnotations,
};

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

local formatComponentName = function(componentName, instanceName)
  local name = if componentName == 'prometheus' then
    instanceName
  else
    componentName + '-' + instanceName;

  std.asciiLower(name);

local stackForInstance = function(instanceName)
  local confWithCommon = com.makeMergeable(params.common) + com.makeMergeable(params.instances[instanceName]);
  local cm = std.foldl(function(prev, k) prev {
    [componentMap[k]]: { name: formatComponentName(componentMap[k], instanceName) } + confWithCommon[k].config,
  }, std.objectFields(componentMap), {});
  local overrides = std.foldl(function(prev, k) prev {
    [componentMap[k]]: confWithCommon[k].overrides,
  }, std.objectFields(componentMap), {});

  (import 'kube-prometheus/main.libsonnet') +
  (import 'kube-prometheus/addons/podsecuritypolicies.libsonnet') {
    values+:: {
      common+: {
        images: std.mapWithKey(patch_image, super.images),
      } + confWithCommon.common,
    } + com.makeMergeable(cm),
  } + com.makeMergeable(overrides);

local render_component(configuredStack, component, prefix) =
  local kp = configuredStack[componentMap[component]];

  {
    ['%d_%s_%s' % [ prefix, component, name ]]: kp[name] {
      metadata+: commonMetadata,
    }
    for name in std.objectFields(kp)
  };

{
  render_component: render_component,
  patch_image: patch_image,
  stackForInstance: stackForInstance,
  metadata: commonMetadata,
}
