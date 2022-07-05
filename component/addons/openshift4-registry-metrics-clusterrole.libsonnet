{
  prometheus+: {
    clusterRole+: {
      rules+: [ {
        apiGroups: [
          'image.openshift.io',
        ],
        resources: [
          'registry/metrics',
        ],
        verbs: [
          'get',
        ],
      } ],
    },
  },
}
