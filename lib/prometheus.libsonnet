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
 * \return A namespace with correct label
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
 * \return A NetworkPolicy allowing ingress from Prometheus namespace
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

// Define Prometheus Operator API versions
local api_version = {
  monitoring: 'monitoring.coreos.com/v1',
};

/**
  * \brief Helper to create PrometheusRule objects.
  *
  * \arg The name of the PrometheusRule.
  * \return A PrometheusRule object.
  */
local prometheusRule(name) = kube._Object(api_version.monitoring, 'PrometheusRule', name);

/**
 * \brief Helper to create ServiceMonitor objects.
 *
 * \arg The name of the ServiceMonitor.
 * \return A ServiceMonitor object.
 */
local serviceMonitor(name) = kube._Object(api_version.monitoring, 'ServiceMonitor', name);


/**
 * \brief Helper to create PodMonitor objects.
 *
 * \arg The name of the PodMonitor.
 * \return A PodMonitor object.
 */
local podMonitor(name) = kube._Object(api_version.monitoring, 'PodMonitor', name);

/**
 * \brief Helper to create Probe objects.
 *
 * \arg The name of the Probe.
 * \return A Probe object.
 */
local probe(name) = kube._Object(api_version.monitoring, 'Probe', name);

{
  RegisterNamespace: registerNamespace,
  NetworkPolicy: networkPolicy,

  PrometheusRule: prometheusRule,
  ServiceMonitor: serviceMonitor,
  PodMonitor: podMonitor,
  Probe: probe,
}
