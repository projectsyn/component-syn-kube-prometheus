// This addon adds a security context constain to give the nodeExporter the necessary permissions
local kube = import 'lib/kube.libjsonnet';

{
  local config = self,

  values+:: {
    nodeExporter+: {
      port: 9101,  // Change default port as OCP's monitoring stack already uses 9100
    },
  },


  local sccName = '%s-%s' % [ config.values.common.namespace, config.values.nodeExporter.name ],
  nodeExporter+: {
    securityContextConstraints: {
      allowHostDirVolumePlugin: true,
      allowHostIPC: false,
      allowHostNetwork: true,
      allowHostPID: true,
      allowHostPorts: true,
      allowPrivilegeEscalation: true,
      allowPrivilegedContainer: true,
      allowedCapabilities: null,
      defaultAddCapabilities: null,
      apiVersion: 'security.openshift.io/v1',
      kind: 'SecurityContextConstraints',
      metadata: {
        annotations: {
          'kubernetes.io/description': 'node-exporter scc is used for the Prometheus node exporter',
        },
        name: sccName,
      },
      readOnlyRootFilesystem: false,
      requiredDropCapabilities: null,
      runAsUser: {
        type: 'RunAsAny',
      },
      seLinuxContext: {
        type: 'RunAsAny',
      },
      supplementalGroups: {
        type: 'RunAsAny',
      },
      users: [],
      volumes: [ '*' ],
    },

    local sccRole = kube.Role(config.values.nodeExporter.name) {
      metadata+: {
        namespace: config.values.common.namespace,
      },
      rules: [
        {
          apiGroups: [ 'security.openshift.io' ],
          resourceNames: [ sccName ],
          resources: [ 'securitycontextconstraints' ],
          verbs: [ 'use' ],
        },
      ],
    },
    securityContextRole: sccRole,
    securityContextRolebinding: kube.RoleBinding(config.values.nodeExporter.name) {
      metadata+: {
        namespace: config.values.common.namespace,
      },
      roleRef_: sccRole,
      subjects_: [
        config.nodeExporter.serviceAccount,
      ],
    },
  },

}
