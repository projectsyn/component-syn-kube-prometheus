// main template for kube_prometheus
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.syn_kube_prometheus;
local instance = inv.parameters._instance;

local common = import 'common.libsonnet';
local prometheus_operator = common.render_component('prometheus_operator', 10);
local prometheus = common.render_component('prometheus', 20);
local alertmanager = common.render_component('alertmanager', 30);
local grafana = common.render_component('grafana', 40);
local node_exporter = common.render_component('node_exporter', 50) {
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
local blackbox_exporter = common.render_component('blackbox_exporter', 60);
local kubernetes_control_plane = common.render_component('kubernetes_control_plane', 70);
local prometheus_adapter = common.render_component('prometheus_adapter', 80);
local kube_state_metrics = common.render_component('kube_state_metrics', 90);

local namespace = kube.Namespace(params.namespace) {
  metadata+: {
    labels+: {
      SYNMonitoring: 'main',
    },
  },
};

// Define outputs below
{
  '00_namespace': namespace,
} +
(if params.prometheus_operator.enabled then prometheus_operator else {}) +
(if params.prometheus.enabled then prometheus else {}) +
(if params.alertmanager.enabled then alertmanager else {}) +
(if params.grafana.enabled then grafana else {}) +
(if params.node_exporter.enabled then node_exporter else {}) +
(if params.blackbox_exporter.enabled then blackbox_exporter else {}) +
(if params.kubernetes_control_plane.enabled then kubernetes_control_plane else {}) +
(if params.prometheus_adapter.enabled then prometheus_adapter else {}) +
(if params.kube_state_metrics.enabled then kube_state_metrics else {})
