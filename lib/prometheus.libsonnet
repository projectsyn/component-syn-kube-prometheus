/**
 * \file Helper to create Prometheus Operator objects and configure cluster monitoring
 **/
local kube = import 'lib/kube.libjsonnet';

local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.prometheus;


local defaultInstance = if std.length(params.instances) > 0
then std.objectFields(params.instances)[0]  // TODO(glrf): Probably not a reasonable default. Switch to some explicit default instance?
else null;

local getInstanceConfig(instance) = params.base + com.makeMergeable(params.instances[instance]);

local registerNamespace(namespace, instance=defaultInstance) = namespace {
  metadata+: {
    labels+: {
      [if instance != null then 'monitoring.syn.tools/%s' % instance]: 'true',
    },
  },
};

local networkPolicy(instance=defaultInstance) = kube.NetworkPolicy('allow-from-prometheus-%s' % instance) {
  local config = getInstanceConfig(instance),
  local namespace = (config.common + com.makeMergeable(config.prometheus)).namespace,
  spec+: {
    ingress+: [ {
      from: [
        {
          namespaceSelector: {
            matchLabels: {
              'kubernetes.io/metadata.name': namespace,
            },
          },
        },
      ],
    } ],
  },
};

{
  RegisterNamespace: registerNamespace,
  NetworkPolicy: networkPolicy,
}
