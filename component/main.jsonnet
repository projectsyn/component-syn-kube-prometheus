// main template for kube_prometheus
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.syn_kube_prometheus;
local instance = inv.parameters._instance;

local common = import 'common.libsonnet';

local namespaces = std.foldl(
  function(namespaces, nsName)
    if params.namespaces[nsName] != null then
      namespaces { ['00_namespace_%s' % nsName]: kube.Namespace(nsName) + com.makeMergeable(params.namespaces[nsName]) }
    else
      namespaces
  , std.objectFields(params.namespaces), {}
);

local renderInstance = function(instanceName, instanceParams)
  local p = params.base + com.makeMergeable(instanceParams);
  local stack = common.stackForInstance(instanceName);
  local prometheus = common.render_component(stack, 'prometheus', 20);
  local alertmanager = common.render_component(stack, 'alertmanager', 30);
  local grafana = common.render_component(stack, 'grafana', 40);
  local node_exporter = common.render_component(stack, 'node_exporter', 50) {
    '50_node_exporter_daemonset'+: {
      spec+: {
        template+: {
          spec+: {
            containers: [
              if c.name == 'nodeexporter-' + instance then
                c {
                  volumeMounts: [
                    vm {
                      mountPropagation: null,
                    }
                    for vm in super.volumeMounts
                  ],
                }
              else
                c
              for c in super.containers
            ],
          },
        },
      },
    },
  };
  local blackbox_exporter = common.render_component(stack, 'blackbox_exporter', 60);
  local kubernetes_control_plane = common.render_component(stack, 'kubernetes_control_plane', 70);
  local prometheus_adapter = common.render_component(stack, 'prometheus_adapter', 80);
  local kube_state_metrics = common.render_component(stack, 'kube_state_metrics', 90);

  {} +
  (if p.prometheus.enabled then prometheus else {}) +
  (if p.alertmanager.enabled then alertmanager else {}) +
  (if p.grafana.enabled then grafana else {}) +
  (if p.node_exporter.enabled then node_exporter else {}) +
  (if p.blackbox_exporter.enabled then blackbox_exporter else {}) +
  (if p.kubernetes_control_plane.enabled then kubernetes_control_plane else {}) +
  (if p.prometheus_adapter.enabled then prometheus_adapter else {}) +
  (if p.kube_state_metrics.enabled then kube_state_metrics else {})
;

local instances = std.mapWithKey(function(name, params) renderInstance(name, params), params.instances);

(import 'operator.libsonnet') + namespaces + std.foldl(function(prev, i) prev + instances[i], std.objectFields(instances), {})
