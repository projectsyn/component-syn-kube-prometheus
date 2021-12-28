// main template for kube_prometheus
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.kube_prometheus;

local prometheus_operator = import 'prometheus-operator.jsonnet';
local prometheus = import 'prometheus.jsonnet';
local alertmanager = import 'alertmanager.jsonnet';
local grafana = import 'grafana.jsonnet';
local node_exporter = import 'node-exporter.jsonnet';
local blackbox_exporter = import 'blackbox-exporter.jsonnet';
local kubernetes_control_plane = import 'kubernetes-control-plane.jsonnet';
local prometheus_adapter = import 'prometheus-adapter.jsonnet';
local kube_state_metrics = import 'kube-state-metrics.jsonnet';

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
