local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local com = import 'lib/commodore.libjsonnet';
// The hiera parameters for the component
local params = inv.parameters.kube_prometheus;

local kp =
  (import 'kube-prometheus/main.libsonnet') {
    values+:: {
      common+: {
        namespace: params.namespace,
      },
    },

    kubernetesControlPlane+: com.makeMergeable(params.kubernetes_control_plane.params),
  };

{
  ['80_kubernetes-control-plane-' + name]: kp.kubernetesControlPlane[name]
  for name in std.objectFields(kp.kubernetesControlPlane)
}
