/**
 * \file Helper to create Prometheus Operator objects and configure cluster monitoring
 **/
local kube = import 'lib/kube.libjsonnet';

local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.prometheus;


local getInstanceConfig(instance) = params.base + com.makeMergeable(params.instances[instance]);

/**
 * \brief Patch the provided Namespace to be picked up by Prometheus
 *
 * This function adds a label to the namespace that will make the provided
 * Prometheus instance discover ServiceMonitors, PodMonitors, and Probes in
 * the namespace. If no instance is provided than the default instance is used.
 *
 * If you don't provide an instance and no default instance is configured the
 * function will return the unmodifed namespace.
 *
 * The`cluster-monitoring` addon needs to be enabled for this label to take effect.
 *
 * \arg `namespace` The namespace to annotate
 * \arg `instance` The name of the instance that should pick up the namespace
 */
local registerNamespace(namespace, instance=params.defaultInstance) = namespace {
  metadata+: {
    labels+: {
      [if instance != null then 'monitoring.syn.tools/%s' % instance]: 'true',
    },
  },
};

/**
 * \brief A NetworkPolicy allowing ingress traffic from Prometheus
 *
 * This function returns a NetworkPolicy that allows ingress traffic from
 * the namespace of the provided Prometheus instance. If no instance is
 * provided than the default instance is used.
 *
 * If you don't provide an instance and no default instance is configured the
 * function will return an empty object.
 *
 * \arg `instance` The name of the instance to allow traffic from
 */
local networkPolicy(instance=params.defaultInstance) =
  if instance == null then
    {}
  else
    kube.NetworkPolicy('allow-from-prometheus-%s' % instance) {
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
