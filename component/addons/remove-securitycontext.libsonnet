// This addons removes the securityContext keys from the stack. Used on openshift.
{
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
          spec+: {
            securityContext:: {},
            containers: [
              c {
                securityContext:: {},
              } for c in super.containers
            ],
          },
        },
      },
    },
  },
}
