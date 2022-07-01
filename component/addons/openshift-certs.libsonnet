local kube = import 'lib/kube.libjsonnet';
local rl = import 'lib/resource-locker.libjsonnet';

local sourceSecretNamespace = 'openshift-monitoring';
local sourceSecretName = 'metrics-client-certs';

{
  local config = self,

  local targetSecret = kube.Secret('ocp-metric-client-certs-' + config.values.prometheus.name),

  local rlPatch = [
    if o.kind == 'ResourceLocker' then
      o {
        spec+: {
          patches: [
            super.patches[0] {
              targetObjectRef+: {
                namespace: config.values.common.namespace,
              },
              sourceObjectRefs: [
                {
                  apiVersion: targetSecret.apiVersion,
                  kind: targetSecret.kind,
                  name: sourceSecretName,
                  namespace: sourceSecretNamespace,
                },
              ],
            },
          ],
        },
      }
    else o
    for o in rl.Patch(targetSecret, {
      data: {
        'tls.crt': '{{ index (index . 0).data "tls.crt" }}',
        'tls.key': '{{ index (index . 0).data "tls.key" }}',
      },
    })
  ],

  prometheus+: {
    ocpMetricsClientCertSecret: targetSecret {
      metadata+: {
        namespace: config.values.common.namespace,
      },
      data:: {},
    },
    prometheus+: {
      spec+: {
        secrets+: [ targetSecret.metadata.name ],
      },
    },
  } + std.foldl(function(p, x) p { [x.metadata.name + '_' + x.kind]: x }, rlPatch, {}),
}
