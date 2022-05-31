// This addon changes openshift specific paths/namespaces/services.
// The `remove-securitycontext` addon is also needed for running on openshift.

local patchPortName = function(spec)
  spec {
    endpoints: [
      ep {
        port: 'https',
      }
      for ep in super.endpoints
    ],
  };

{
  kubernetesControlPlane+: {
    serviceMonitorKubeScheduler+: {
      spec+: patchPortName(super.spec) {
        jobLabel: 'prometheus',
        namespaceSelector: {
          matchNames: [ 'openshift-kube-scheduler' ],
        },
        selector: {
          matchLabels: { prometheus: 'kube-scheduler' },
        },
      },
    },

    serviceMonitorKubeControllerManager+: {
      spec+: patchPortName(super.spec) {
        jobLabel: 'prometheus',
        namespaceSelector: {
          matchNames: [ 'openshift-kube-controller-manager' ],
        },
        selector: {
          matchLabels: { prometheus: 'kube-controller-manager' },
        },
      },
    },

    serviceMonitorCoreDNS+: {
      spec+: {
        jobLabel:: null,
        namespaceSelector: {
          matchNames: [ 'openshift-dns' ],
        },
      },
    },
  },
}
