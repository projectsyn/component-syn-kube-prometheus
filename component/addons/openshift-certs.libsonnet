local kube = import 'lib/kube.libjsonnet';
local rl = import 'lib/resource-locker.libjsonnet';

local name = 'copy-metric-certs';

local sourceNamespace = 'openshift-monitoring';
local sourceName = 'metrics-client-certs';

local toAdd = kube.Secret(name);


{
  local config = self,
  local rlPatch = [
    if o.kind == 'ResourceLocker' then o {
      spec+: {
        patches: [
          {
            id: 'patch-1',
            targetObjectRef: {
              apiVersion: toAdd.apiVersion,
              kind: toAdd.kind,
              name: toAdd.metadata.name,
              namespace: config.values.common.namespace,
            },
            patchTemplate: |||
              data:
                tls.crt: {{ index (index . 0).data "tls.crt" }}
                tls.key: {{ index (index . 0).data "tls.key" }}
            |||,
            patchType: 'application/strategic-merge-patch+json',
            sourceObjectRefs: [
              {
                apiVersion: toAdd.apiVersion,
                kind: toAdd.kind,
                name: sourceName,
                namespace: sourceNamespace,
              },
            ],
          },
        ],
      },
    } else o
    for o in rl.Patch(toAdd, {})
  ],


  prometheus+: std.foldl(function(p, x) p { [x.metadata.name + '_' + x.kind]: x }, rlPatch, {}),
}
