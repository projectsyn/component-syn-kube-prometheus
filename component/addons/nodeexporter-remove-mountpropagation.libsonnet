// This addons removes the mountPropagation field from the node-exporter host mounts.

{
  local config = self,

  nodeExporter+: {
    daemonset+: {
      spec+: {
        template+: {
          spec+: {
            containers: [
              if c.name == config.values.nodeExporter.name then
                c {
                  volumeMounts: [
                    vm {
                      mountPropagation:: null,
                    }
                    for vm in super.volumeMounts
                  ],
                }
              else
                c
              for c in super.containers
            ],
          },
        },
      },
    },
  },
}
