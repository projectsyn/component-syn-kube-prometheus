// This addons removes the securityContext keys from the stack. Used on openshift.
{
  prometheus+: {
    prometheus+: {
      spec+: {
        securityContext:: {},
      },
    },
  },
}
