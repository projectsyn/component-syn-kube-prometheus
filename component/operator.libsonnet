// template for prometheus-operator
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.prometheus;

local common = import 'common.libsonnet';

local configuredOperator =
  common.withAddons(import 'kube-prometheus/main.libsonnet', params.addons) {
    local config = self,

    values+:: {
      common+: {
        images: std.mapWithKey(common.patch_image, super.images),
      } + com.makeMergeable(params.base.common) + com.makeMergeable(params.prometheusOperator.common),
    } + { prometheusOperator+: com.makeMergeable(params.prometheusOperator.config) },

    local namespaces = std.join(',', std.filter(function(name) params.namespaces[name] != null, std.objectFields(params.namespaces))),
    prometheusOperator+: {
      deployment+: {
        spec+: {
          template+: {
            spec+: {
              containers: [
                if c.name == config.values.prometheusOperator.name then
                  c {
                    args+: [
                      '--prometheus-instance-namespaces=%s' % namespaces,
                      '--thanos-ruler-instance-namespaces=%s' % namespaces,
                      '--alertmanager-instance-namespaces=%s' % namespaces,
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
    } + com.makeMergeable(params.prometheusOperator.overrides),
  };

local filterCRDs = function(obj)
  if params.prometheusOperator.installCRDs then
    obj
  else
    {
      [if obj[name].kind != 'CustomResourceDefinition' then name]: obj[name]
      for name in std.objectFields(obj)
    };

local prometheusOperator = {
  ['10_prometheusOperator_%s' % name]: configuredOperator.prometheusOperator[name] {
    metadata+: common.metadata,
  }
  for name in std.objectFields(filterCRDs(configuredOperator.prometheusOperator))
};

local namespace = kube.Namespace(params.prometheusOperator.namespace) {
  metadata+: {
    labels+: {
      SYNMonitoring: 'main',
    },
  },
};

(if params.prometheusOperator.enabled then prometheusOperator {
   '00_operator_namespace': namespace,
 } else {})
