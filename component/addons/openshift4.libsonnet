// This addon changes openshift specific paths/namespaces/services.
// The `remove-securitycontext` addon is also needed for running on openshift.

{
  kubernetesControlPlane+: {
    serviceMonitorKubeScheduler+: {
      spec+: {
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
      spec+: {
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
