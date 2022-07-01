// This addon allows this component to be deployed on OpenShift clusters.
// It:
// - patches the upstream ServiceMonitors to work with OpenShift.
// - adds the `remove-securitycontext` addon to remove the security context from deployments.
// - adds the `nodeexporter` addon to assign a sufficient SCC to the nodeexporter service account and change the default nodeexporter port.
// - copies the metrics mTLS secrets to the stacks namespace using the `openshift-certs` addon.

(import './remove-securitycontext.libsonnet')
+
(import './openshift4-nodeexporter.libsonnet')
+
(import './openshift4-control-plane.libsonnet')
+
(import './openshift-certs.libsonnet')
