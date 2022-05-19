// This addon removes the securityContext keys from the stack. Used on OpenShift.

local removeFromSpec = function(spec)
  spec {
    securityContext:: {},
    containers: [
      c {
        securityContext:: {},
      }
      for c in super.containers
    ],
  };

{
  alertmanager+: {
    alertmanager+: {
      spec+: {
        securityContext:: {},
      },
    },
  },

  prometheus+: {
    prometheus+: {
      spec+: {
        securityContext:: {},
      },
    },
  },

  prometheusOperator+: {
    deployment+: {
      spec+: {
        template+: {
          spec+: removeFromSpec(super.spec),
        },
      },
    },
  },

  nodeExporter+: {
    daemonset+: {
      spec+: {
        template+: {
          spec+: removeFromSpec(super.spec),
        },
      },
    },
  },

  blackboxExporter+: {
    deployment+: {
      spec+: {
        template+: {
          spec+: removeFromSpec(super.spec),
        },
      },
    },
  },

  kubeStateMetrics+: {
    deployment+: {
      spec+: {
        template+: {
          spec+: removeFromSpec(super.spec),
        },
      },
    },
  },

}
