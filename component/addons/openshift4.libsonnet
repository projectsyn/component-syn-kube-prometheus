// This addon allows this component to be deployed on OpenShift clusters.
// It:
// - patches the upstream ServiceMonitors to work with OpenShift.
// - adds the `remove-securitycontext` addon to remove the security context from deployments.

(import './remove-securitycontext.libsonnet')
+
(import './openshift4-control-plane.libsonnet')
