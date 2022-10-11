local com = import 'lib/commodore.libjsonnet';

local defaults = {
  local defaults = self,

  image: 'quay.io/oauth2-proxy/oauth2-proxy:latest',

  oauth2ProxyPort: 4180,
  rbacProxyPort: 4181,

  ingress: {
    enabled: true,
    host: null,
    annotations: {},
    tls: {
      enabled: true,
      secretName: null,
    },
  },

  resources: {
    limits: {
      cpu: '500m',
      memory: '128Mi',
    },
    requests: {
      cpu: '5m',
      memory: '64Mi',
    },
  },
  proxyEnv: {},
  proxyArgs: {
    'http-address': '0.0.0.0:%s' % defaults.oauth2ProxyPort,
    'silence-ping-logging': true,
    'skip-provider-button': true,
    'reverse-proxy': true,
  },
};

local componentSpecificDefaults = {
  prometheus: {
    proxyArgs+: {
      upstream: 'http://127.0.0.1:9090',
    },
  },
  alertmanager: {
    proxyArgs+: {
      upstream: 'http://127.0.0.1:9093',
    },
  },
};

local formatArgs = function(args)
  std.map(
    function(arg) '--%s=%s' % [ arg, args[arg] ],
    std.objectFields(args),
  );

local proxyFor = function(component) {
  local config = self,

  values+:: {
    common+: {
      images+: {
        kubeRbacProxy+: '',
      },
    },
    [component]+: {
      name+: '',
      namespace+: '',
      _oauth2Proxy+: {},
    },
  },

  local params = defaults + componentSpecificDefaults[component] + config.values[component]._oauth2Proxy,
  local oauthProxy = {
    name: 'oauth2-proxy',
    image: params.image,
    resources: params.resources,
    args: formatArgs(params.proxyArgs),
    env: com.envList(params.proxyEnv),
  },

  local rbacProxy = {
    args: formatArgs(componentSpecificDefaults[component].proxyArgs {
      'secure-listen-address': '0.0.0.0:%s' % params.rbacProxyPort,
      logtostderr: true,
      v: 0,
    }),
    image: config.values.common.images.kubeRbacProxy,
    name: 'kube-rbac-proxy',
    ports: [
      {
        containerPort: params.rbacProxyPort,
        name: 'rbac',
        protocol: 'TCP',
      },
    ],
    resources: params.resources,
  },

  [component]+: {
    [component]+: {
      metadata+: {
        labels+: {},
      },
      spec+: {
        listenLocal: true,
        containers+: [ oauthProxy, rbacProxy ],
      },
    },

    service+: {
      metadata+: {
        name+: '',
      },
      spec+: {
        selector+: {
        },
        ports+: [
          {
            name: 'rbac',
            port: params.rbacProxyPort,
            targetPort: params.rbacProxyPort,
          },
        ],
      },
    },

    local serviceAccountName = '%s-%s' % [ component, config.values[component].name ],
    local clusterRoleProxyName = '%s-proxy' % serviceAccountName,

    clusterRoleProxy: {
      apiVersion: 'rbac.authorization.k8s.io/v1',
      kind: 'ClusterRole',
      metadata: {
        labels: config[component][component].metadata.labels,
        name: clusterRoleProxyName,
      },
      rules: [
        {
          apiGroups: [
            'authentication.k8s.io',
          ],
          resources: [
            'tokenreviews',
          ],
          verbs: [
            'create',
          ],
        },
        {
          apiGroups: [
            'authorization.k8s.io',
          ],
          resources: [
            'subjectaccessreviews',
          ],
          verbs: [
            'create',
          ],
        },
      ],
    },

    clusterRoleBindingProxy: {
      apiVersion: 'rbac.authorization.k8s.io/v1',
      kind: 'ClusterRoleBinding',
      metadata: {
        labels: config[component][component].metadata.labels,
        name: clusterRoleProxyName,
      },
      roleRef: {
        apiGroup: 'rbac.authorization.k8s.io',
        kind: 'ClusterRole',
        name: clusterRoleProxyName,
      },
      subjects: [ {
        kind: 'ServiceAccount',
        name: serviceAccountName,
        namespace: config.values[component].namespace,
      } ],
    },

    serviceMonitor+: {
      spec+: {
        endpoints: [
          {
            bearerTokenFile: '/var/run/secrets/kubernetes.io/serviceaccount/token',
            path: '/metrics',
            port: 'rbac',
            scheme: 'https',
            tlsConfig: {
              insecureSkipVerify: true,
            },
          },
          { port: 'reloader-web', interval: '30s' },
        ],
      },
    },

    authService+: {
      apiVersion: 'v1',
      kind: 'Service',
      metadata+: config[component].service.metadata {
        name: config[component].service.metadata.name + '-auth',
      },
      spec: {
        selector+: config[component].service.spec.selector,
        ports+: [
          {
            name: 'web',
            port: params.oauth2ProxyPort,
            targetPort: params.oauth2ProxyPort,
          },
        ],
      },
    },

    [if params.ingress.enabled then 'authIngress']+: {
      local ingress = self,
      apiVersion: 'networking.k8s.io/v1',
      kind: 'Ingress',
      metadata+: {
        name: '%s-%s' % [ component, config.values[component].name ],
        namespace: config.values[component].namespace,
        annotations+: params.ingress.annotations,
      },
      spec+: {
        rules+: [
          {
            host: params.ingress.host,
            http: {
              paths: [
                {
                  backend: {
                    service: {
                      name: config[component].authService.metadata.name,
                      port: {
                        number: params.oauth2ProxyPort,
                      },
                    },
                  },
                  path: '/',
                  pathType: 'Prefix',
                },
              ],
            },
          },
        ],
        tls:
          if params.ingress.tls.enabled then [
            {
              hosts: [ params.ingress.host ],
              secretName: if params.ingress.tls.secretName == null then ingress.metadata.name + '-tls' else params.ingress.tls.secretName,
            },
          ]
          else
            [],
      },
    },
  },
};

proxyFor('alertmanager') + proxyFor('prometheus') + {
  local config = self,

  values+:: {
    prometheus+: {
      alerting+: {},
    },
  },

  alertmanager+: {
    serviceAccount+: {
      automountServiceAccountToken: true,
    },
  },

  prometheus+: {
    prometheus+: {
      spec+: {
        alerting+: {
          [if config.values.prometheus.alerting != {} then 'alertmanagers']: [ {
            namespace: config.values.alertmanager.namespace,
            name: 'alertmanager-' + config.values.alertmanager.name,
            port: 'rbac',
            apiVersion: 'v2',
            scheme: 'https',
            bearerTokenFile: '/var/run/secrets/kubernetes.io/serviceaccount/token',
            tlsConfig: {
              insecureSkipVerify: true,
            },
          } ],
        },
      },
    },

    clusterRole+: {
      rules+: [ {
        nonResourceURLs: [ '/api/v2/alerts' ],
        verbs: [ '*' ],
      } ],
    },
  },
}
