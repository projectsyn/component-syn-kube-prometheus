local com = import 'lib/commodore.libjsonnet';

local defaults = {
  local defaults = self,

  image: 'quay.io/oauth2-proxy/oauth2-proxy:latest',

  proxyPort: 4180,

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
    requests: {
      cpu: '20m',
      memory: '100Mi',
    },
  },
  proxyEnv: {},
  proxyArgs: {
    'http-address': '0.0.0.0:%s' % defaults.proxyPort,
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

local proxyFor = function(component) {
  local config = self,

  values+:: {
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
    args: std.map(
      function(arg) '--%s=%s' % [ arg, params.proxyArgs[arg] ],
      std.objectFields(params.proxyArgs),
    ),
    env: com.envList(params.proxyEnv),
  },

  [component]+: {
    [component]+: {
      spec+: {
        listenLocal: true,
        containers+: [ oauthProxy ],
      },
    },

    service+: {
      metadata+: {
        name+: '',
      },
      spec+: {
        selector+: {
        },
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
            port: params.proxyPort,
            targetPort: params.proxyPort,
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
                        number: params.proxyPort,
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

proxyFor('alertmanager') + proxyFor('prometheus')
