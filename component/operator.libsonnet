// main template for kube_prometheus
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.syn_kube_prometheus;

local common = import 'common.libsonnet';

local configuredOperator =
  (import 'kube-prometheus/main.libsonnet') +
  (import 'kube-prometheus/addons/podsecuritypolicies.libsonnet') {
    local config = self,

    values+:: {
      common+: {
        images: std.mapWithKey(common.patch_image, super.images),
      } + com.makeMergeable(params.base.common) + com.makeMergeable(params.prometheus_operator.common),
    } + {prometheusOperator+: com.makeMergeable(params.prometheus_operator.config)},

    prometheusOperator+: {
      deployment+: {
        spec+: {
          template+: {
            spec+: {
              containers: [
                if c.name == config.values.prometheusOperator.name then
                  c {
                    args+: [
                      '--prometheus-instance-namespaces=%s' % std.join(',', std.filter(function(name) params.namespaces[name] != null, std.objectFields(params.namespaces))),
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
    } + com.makeMergeable(params.prometheus_operator.overrides),
  };

local filterCRDs = function(obj)
  if params.prometheus_operator.install_crds then
    obj
  else
    {
      [if obj[name].kind != 'CustomResourceDefinition' then name]: obj[name]
      for name in std.objectFields(obj)
    };

local prometheus_operator = {
  ['10_prometheus_operator_%s' % name]: configuredOperator.prometheusOperator[name] {
    metadata+: common.metadata,
  }
  for name in std.objectFields(filterCRDs(configuredOperator.prometheusOperator))
};

local namespace = kube.Namespace(params.prometheus_operator.namespace) {
  metadata+: {
    labels+: {
      SYNMonitoring: 'main',
    },
  },
};

(if params.prometheus_operator.enabled then prometheus_operator {
   '00_operator_namespace': namespace,
 } else {})
