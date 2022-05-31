// This addon allows this component to be deployed on OpenShift clusters.
// It:
// - patches the upstream ServiceMonitors to work with OpenShift.
// - adds the `remove-securitycontext` addon to remove the security context from deployments.

local kubeSchedulerNamespace = 'openshift-kube-scheduler';
local kubeControllerManagerNamespace = 'openshift-kube-controller-manager';
local kubeDNSNamespace = 'openshift-dns';

local patchPortName = function(spec)
  spec {
    endpoints: [
      ep {
        port: 'https',
      }
      for ep in super.endpoints
    ],
  };

(import './remove-securitycontext.libsonnet')
+
{
  values+:: {
    prometheus+: {
      namespaces+: [
        kubeSchedulerNamespace,
        kubeControllerManagerNamespace,
        kubeDNSNamespace,
      ],
    },
  },

  kubernetesControlPlane+: {
    serviceMonitorKubeScheduler+: {
      spec+: {
        endpoints+: [],
      },
    },

    serviceMonitorKubeControllerManager+: {
      spec+: {
        endpoints+: [],
      },
    },

    serviceMonitorCoreDNS+: {
      spec+: {
        endpoints+: [],
      },
    },
  },
}
+
{
  local config = self,

  kubernetesControlPlane+: {
    serviceMonitorKubeScheduler+: {
      spec+: patchPortName(super.spec) {
        jobLabel: 'prometheus',
        namespaceSelector: {
          matchNames: [ kubeSchedulerNamespace ],
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
          matchNames: [ kubeControllerManagerNamespace ],
        },
        selector: {
          matchLabels: { prometheus: 'kube-controller-manager' },
        },
      },
    },

    serviceMonitorCoreDNS+: {
      spec+: {
        endpoints: [
          ep {
            scheme: 'https',
            tlsConfig: {
              insecureSkipVerify: true,
            },
          }
          for ep in super.endpoints
        ],

        jobLabel:: null,
        namespaceSelector: {
          matchNames: [ kubeDNSNamespace ],
        },
        selector: {},
      },
    },
  },
}
