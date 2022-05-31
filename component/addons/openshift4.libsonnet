// This addon changes openshift specific paths/namespaces/services.
// The `remove-securitycontext` addon is also needed for running on openshift.

{
  kubernetesControlPlane+: {
    serviceMonitorKubeScheduler+: {
      spec+: {
        namespaceSelector: {
          matchNames: [ 'openshift-kube-scheduler' ],
        },
        selector: {
          matchLabels: { prometheus: 'kube-scheduler' },
        },
      },
    },

    serviceMonitorKubeControllerManager+: {
      spec+: {
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
        namespaceSelector: {
          matchNames: [ 'openshift-dns' ],
        },
      },
    },
  },
}
