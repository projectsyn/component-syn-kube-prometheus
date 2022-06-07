/**
 * \file Helper to create Prometheus Operator objects and configure cluster monitoring
 **/
local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.prometheus;

local registerNamespace(namespace, instance=null) = namespace {
  local inst = if instance != null
  then instance
  else
    if std.length(params.instances) > 0
    then std.objectFields(params.instances)[0]  // TODO(glrf): Probably not a reasonable default. Switch to some explicit default instance?
    else null
  ,

  metadata+: {
    labels+: {
      [if inst != null then 'monitoring.syn.tools/%s' % inst]: 'true',
    },
  },
};

{
  RegisterNamespace: registerNamespace,
}
