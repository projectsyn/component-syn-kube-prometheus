local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.prometheus;

local restrict_selectors = function(instanceName)
  if std.objectHas(params.addon_configs.cluster_monitoring, instanceName) && std.objectHas(params.addon_configs.cluster_monitoring[instanceName], 'restrict_selectors') then
    params.addon_configs.cluster_monitoring[instanceName].restrict_selectors
  else
    params.addon_configs.cluster_monitoring.restrict_selectors
;

{
  local config = self,

  prometheus+: {
    local roleName = 'syn-cluster-monitoring-%s' % config.values.prometheus.name,
    local clusterMonitoringRole = kube.ClusterRole(roleName) {
      metadata+: {
        namespace: config.values.common.namespace,
      },
      rules: [
        {
          apiGroups: [ '' ],
          resources: [ 'namespaces', 'namespace/metrics' ],
          verbs: [ 'get' ],
        },
        {
          apiGroups: [ '' ],
          resources: [ 'services', 'endpoints', 'pods' ],
          verbs: [ 'get', 'list', 'watch' ],
        },
        {
          apiGroups: [ 'extensions' ],
          resources: [ 'ingresses' ],
          verbs: [ 'get', 'list', 'watch' ],
        },
        {
          apiGroups: [ 'networking.k8s.io' ],
          resources: [ 'ingresses' ],
          verbs: [ 'get', 'list', 'watch' ],
        },
      ],
    },
    ClusterMonitoringRole: clusterMonitoringRole,
    ClusterMonitoringRolebinding: kube.ClusterRoleBinding(clusterMonitoringRole.metadata.name) {
      metadata+: {
        namespace: config.values.common.namespace,
      },
      roleRef_: clusterMonitoringRole,
      subjects_: [
        config.prometheus.serviceAccount,
      ],
    },


    [if restrict_selectors(config.values.prometheus.name) then 'prometheus']+: {
      spec+: {
        local nsSelector = {
          matchLabels: {
            ['monitoring.syn.tools/%s' % config.values.prometheus.name]: 'true',
          },
        },
        local optOutSelector = {
          matchExpressions: [ {
            key: 'monitoring.syn.tools/enabled',
            operator: 'NotIn',
            values: [ 'false', 'False' ],
          } ],
        },
        local optInSelector = {
          matchExpressions: [ {
            key: 'monitoring.syn.tools/enabled',
            operator: 'In',
            values: [ 'true', 'True' ],
          } ],
        },
        serviceMonitorNamespaceSelector+: nsSelector,
        serviceMonitorSelector+: optOutSelector,
        podMonitorNamespaceSelector+: nsSelector,
        podMonitorSelector+: optOutSelector,
        probeNamespaceSelector+: nsSelector,
        probeSelector+: optOutSelector,
        ruleNamespaceSelector+: nsSelector,
        ruleSelector+: optInSelector,
      },
    },
  },


}
