local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local com = import 'lib/commodore.libjsonnet';
// The hiera parameters for the component
local params = inv.parameters.prometheus;

local addonImports = import 'compiled/prometheus/addons.libsonnet';

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
  source: 'https://github.com/projectsyn/component-prometheus',
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
  'kubePrometheus',
];

local imageIsDockerIOShort = function(image)
  local parts = std.split(image, '/');
  if std.length(parts) < 3 && std.length(std.findSubstr('.', parts[0])) == 0 then
    true
  else
    false;

local patch_image = function(key, image)
  if imageIsDockerIOShort(image) then
    params.registries['docker.io'] + '/' + image
  else
    std.foldl(
      function(image, registryReplacement)
        local parts = std.split(image, '/');
        if parts[0] == registryReplacement then
          params.registries[registryReplacement] + '/' + std.join('/', parts[1:])
        else
          image
      , std.objectFields(params.registries), image
    );

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
      prometheus+: {
        // We need to explicitly handle enabling thanos, as upstream has a "null" in the field, making standard merge impossible
        [if std.objectHas(confWithBase.prometheus.config, 'thanos') then 'thanos']: confWithBase.prometheus.config.thanos,
      },
    } + com.makeMergeable(cm),
  } + com.makeMergeable(overrides);

local render_component(configuredStack, component, prefix, instance) =
  local kp = configuredStack[component];

  {
    ['%d_%s_%s_%s' % [ prefix, instance, component, name ]]: kp[name] {
      metadata:
        commonMetadata
        +
        com.makeMergeable(
          com.getValueOrDefault(kp[name], 'metadata', {})
        ),
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
