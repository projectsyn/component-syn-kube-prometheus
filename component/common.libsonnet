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

local addonImports = import 'compiled/syn-kube-prometheus/addons.libsonnet';

local withAddons = function(main, addons)
  std.foldl(
    function(main, addonName)
      assert std.objectHas(addonImports, addonName) : 'Addon `%s` not found' % addonName;
      main + addonImports[addonName]
    , com.renderArray(addons), main
  );

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
local instanceComponents = [
  'alertmanager',
  'blackboxExporter',
  'grafana',
  'kubernetesControlPlane',
  'kubeStateMetrics',
  'nodeExporter',
  'prometheus',
  'prometheusAdapter',
];

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
  local confWithBase = com.makeMergeable(params.base) + com.makeMergeable(params.instances[instanceName]);
  local cm = std.foldl(function(prev, k) prev {
    [k]: { name: formatComponentName(k, instanceName) } + confWithBase[k].config,
  }, instanceComponents, {});
  local overrides = std.foldl(function(prev, k) prev {
    [k]: confWithBase[k].overrides,
  }, instanceComponents, {});

  withAddons(import 'kube-prometheus/main.libsonnet', params.addons) {
    values+:: {
      common+: {
        images: std.mapWithKey(patch_image, super.images),
      } + confWithBase.common,
    } + com.makeMergeable(cm),
  } + com.makeMergeable(overrides);

local render_component(configuredStack, component, prefix) =
  local kp = configuredStack[component];

  {
    ['%d_%s_%s' % [ prefix, component, name ]]: kp[name] {
      metadata+: commonMetadata,
    }
    for name in std.objectFields(kp)
  };

{
  withAddons: withAddons,
  render_component: render_component,
  patch_image: patch_image,
  stackForInstance: stackForInstance,
  metadata: commonMetadata,
}
