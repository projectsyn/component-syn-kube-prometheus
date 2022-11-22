local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.prometheus;

{
  local config = self,
  local resourcequota = {
    apiVersion: 'v1',
    kind: 'ResourceQuota',
    metadata: {
      name: config.values.nodeExporter.name,
      namespace: config.values.common.namespace,
    },
    spec: {
      scopeSelector: {
        matchExpressions: [
          {
            operator: 'In',
            scopeName: 'PriorityClass',
            values: [ 'system-cluster-critical' ],
          },
        ],
      },
    },
  },
  nodeExporter+: {
    resourceQuota: resourcequota,
  },
}
