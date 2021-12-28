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

    nodeExporter+: com.makeMergeable(params.node_exporter.params),
  };

{
  ['60_node-exporter-' + name]: kp.nodeExporter[name]
  for name in std.objectFields(kp.nodeExporter)
}
