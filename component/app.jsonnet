local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.monitoring;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('monitoring', params.namespace);

{
  monitoring: app,
}
