local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.syn_kube_prometheus;
local argocd = import 'lib/argocd.libjsonnet';
local instance = inv.parameters._instance;

local app = argocd.App(instance, params.namespace) {
  spec+: {
    ignoreDifferences+: [
      {
        group: '',
        kind: 'ServiceAccount',
        jsonPointers: [
          '/imagePullSecrets',
        ],
      },
    ],
  },
};

{
  [instance]: app,
}
