---
title: "OKD with VictoriaMetrics"
date: 2022-07-29T12:29:00+02:00
draft: false
comments:
  host: social.vrutkovs.eu
  username: vadim
  id: AMHEoRTGDrf6hG83Em
---

# Y tho

[OKD](https://okd.io) is an opionioned k8s distro. It heavily uses operators to deploy its components,
apply changes and upgrade between versions.

One of OKD components is cluster monitoring, which uses Prometheus as a storage and query engine
to ensure cluster problems could be easily detected by collecting metrics from its components.
However, some might find Prometheus to be too resource-hungry. You might have heard of [VictoriaMetrics](https://victoriametrics.com/) (or just VM), specifically designed to be high performant TSDB solution.

In this blog post, I'll describe how to install VictoriaMetrics on OKD using the operator. In the second
the part we'll learn how to replace in-cluster Prometheus with our own VictoriaMetrics cluster.

All manifests described in this blog post are available at https://github.com/vrutkovs/victoriametrics-okd/

# Operators all the way down

OKD 4 is a k8s distro built around the idea of operators. If you're not familiar with the concept,
an operator is an app, running in the cluster, which takes care of deploying and reconciling some child resources (called "operand"(s)). For instance, instead of `kubectl apply` or `helm install` you could write an app, which ensures necessary
objects are created in the cluster, without describing them in YAML, but using your favorite programming language and k8s API.
Thus an operator is a k8s-native service, built to deploy and control user applications.

The benefit of this approach is improved control over the operand's lifecycle - the operator watches the operand state and ensures changes are applied automatically and the operand is not being removed. This also allows complicated pre- or post-deploy hooks to be executed on update.

# Installing VictoriaMetrics operator

Operators can be bundled in container images, similar to any other k8s apps. [OperatorHub](https://operatorhub.io) is a primary source of community-built operators. Apart from hosting operator images, it also has [Operator Lifecycle Manager](https://olm.operatorframework.io/) utility, which allows listing, installing, and updating operators easily. OKD comes with OperatorHub subscription and OLM out of the box.

In OKD console you'll find "Operators" tab with OperatorHub subitem. It opens a list of available operators. Operators can be installed in a specific namespace or cluster-wide. Different operator versions can be installed by selecting a channel (if available). OLM will ensure the operator is updated when a new version in the channel is posted.
In VictoriaMetrics case, the operator is usually cluster-wide (to scrape metrics from user apps in different namespaces).

Operators can be controlled by Custom Resourced. OLM outputs which CRs the operator is controlling in "Provided APIs" section.
For VictoriaMetrics the easiest to start with would be `VMSingle`, describing a single node all-in-one VictoriaMetrics cluster.

Here's an example CR for it:
```yaml
apiVersion: operator.victoriametrics.com/v1beta1
kind: VMSingle
metadata:
  finalizers:
    - apps.victoriametrics.com/finalizer
  name: my-little-monitoring
  namespace: openshift-operators
spec:
  image: {}
  removePvcAfterDelete: true
  resources:
    limits:
      cpu: 500m
      memory: 850Mi
    requests:
      cpu: 250m
      memory: 350Mi
  retentionPeriod: 2w
  storage:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 20Gi
  storageMetadata: {}
```

It describes the following aspects of the deployment:
* `spec.resources` sets requests for the pod
* `spec.storage` allocates a PVC with 20GB for data
* `spec.image` is unset to use VM image at operator's discretion

On `Resources` tab, a list of created k8s resources is displayed. Make sure that `Deployment` there is ready and pods are running without crashlooping.

Let's expose the VictoriaMetrics so that we could open its UI in a browser:
```yaml
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  name: vm
  namespace: openshift-operators
  labels:
    app.kubernetes.io/component: monitoring
    app.kubernetes.io/instance: my-little-monitoring
    app.kubernetes.io/name: vmsingle
    managed-by: vm-operator
spec:
  to:
    kind: Service
    name: vmsingle-my-little-monitoring
  tls:
    termination: edge
  port:
    targetPort: http
```

The operator is creating `VMServiceScrape` object automatically so that VM could monitor itself:
```yaml
apiVersion: operator.victoriametrics.com/v1beta1
kind: VMServiceScrape
metadata:
    name: vmsingle-my-little-monitoring
  uid: 0e65647e-b848-4d21-8180-a5f50547b091
  namespace: openshift-operators
  ownerReferences:
    - apiVersion: operator.victoriametrics.com/v1beta1
      blockOwnerDeletion: true
      controller: true
      kind: VMSingle
      name: my-little-monitoring
      uid: 0caf0a5c-ef74-47d7-a1fd-d9530c368699
  labels:
    app.kubernetes.io/component: monitoring
    app.kubernetes.io/instance: my-little-monitoring
    app.kubernetes.io/name: vmsingle
    managed-by: vm-operator
spec:
  endpoints:
    - path: /metrics
      port: http
  namespaceSelector: {}
  selector:
    matchLabels:
      app.kubernetes.io/component: monitoring
      app.kubernetes.io/instance: my-little-monitoring
      app.kubernetes.io/name: vmsingle
      managed-by: vm-operator
```
However, another component is required to configure scraping - `VMAgent`.

The operator can spin up VMAgent for us:
```yaml
kind: VMAgent
apiVersion: operator.victoriametrics.com/v1beta1
metadata:
  name: vmagent
  namespace: openshift-operators
spec:
  extraArgs:
    memory.allowedPercent: '40'
  nodeScrapeSelector: {}
  podScrapeSelector: {}
  probeSelector: {}
  remoteWrite:
    - url: 'http://vmsingle-my-little-monitoring.openshift-operators.svc:8429/api/v1/write'
  replicaCount: 1
  resources:
    limits:
      cpu: 500m
      memory: 850Mi
    requests:
      cpu: 250m
      memory: 350Mi
  serviceScrapeSelector: {}
  staticScrapeSelector: {}
```

The operator would create a `vmagent` pod, which scrapes the previously mentioned `VMServiceScrape` and send data
to VictoriaMetrics. We can ensure VM metrics are collected by querying for `vm_app_version` in the UI.


# Replacing OKD Prometheus with VictoriaMetrics

Once we've learned to deploy VictoriaMetrics we could ask ourselves - why would we want two monitoring
solutions in our cluster - Prometheus and VictoriaMetrics. OKD can deploy another instance of Prometheus
to keep user metrics - see [Enabling monitoring for user-defined projects](https://docs.okd.io/latest/monitoring/enabling-monitoring-for-user-defined-projects.html) so that cluster and user metrics would be separated.
This comes at a cost of running another Prometheus instance.

For some users, this may require too many resources and we can replace cluster Prometheus with VictoriaMetrics and use
the latter for both metrics. This will use fewer resources but complicate the separation of concerns.

{{< notice warning >}}
The following procedure will make your OKD cluster unupgradable and you have to reverse the procedure
to update it. OKD requires all operators to be configured via Custom Resources to be upgradable,
and the following procedure will disable `cluster-monitoring-operator` as it can't deploy VictoriaMetrics
instead of Prometheus. As we intervene in the deployed operator status CVO cannot guarantee that upgrade
would pass and will not start it. You can upgrade again after removing overrides, which will deploy Prometheus
and revert some manual changes.
{{< /notice >}}

OKD is an operator-based k8s distro. This means all OKD operators - changing settings, updates, etc. - are performed
by operators. These are however not posted to OperatorHub but included in the OKD payload, as they are not meant to
be used separately, but in collaboration with other, "core" operators.

Default Prometheus instance is deployed by `prometheus-operator` in the `openshift-monitoring` namespace. This operator
cannot be modified directly, as its being created and reconciled by `cluster-monitoring-operator`. As of today, in OKD 4.10,
`cluster-monitoring-operator` cannot be controlled to avoid deploying Prometheus, as it's a core part of the monitoring solution.
OKD's core principle is "batteries included" so it cannot leave the user without any kind of monitoring.

However, we can disable `cluster-monitoring-operator` after it has created the necessary resources and replace it with a custom solution.
This operator, in its turn, is not deployed separated but controlled by OKD's top-level operator - Cluster Version Operator.

Cluster Version Operator (or simply CVO) can be configured to turn a blind eye to some changes:
```yaml
apiVersion: config.openshift.io/v1
kind: ClusterVersion
metadata:
  name: version
spec:
  overrides:
    - group: apps
      kind: Deployment
      name: cluster-monitoring-operator
      namespace: openshift-monitoring
      unmanaged: true
```

This tells CVO to stop reconciling the `cluster-monitoring-operator` deployment in `openshift-monitoring` namespaces so that the user can change it. This override will prevent CVO from upgrading the cluster until this override is removed.

Next, we can scale down `cluster-monitoring-operator` to zero replicas:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cluster-monitoring-operator
  namespace: openshift-monitoring
spec:
  replicas: 0
```

Prometheus operator is still running and we could ask it to scale down Prometheus to zero:
```yaml
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  name: k8s
  namespace: openshift-monitoring
spec:
  replicas: 0
```

{{< figure src="/images/okd-vm-01.png" caption="Look ma, no Prometheus" >}}

Instead of prometheus, we could now deploy another VictoriaMetrics instance. This time we'll deploy
a proper cluster with 2 instances for resilience:
```yaml
apiVersion: operator.victoriametrics.com/v1beta1
kind: VMCluster
metadata:
  name: vmcluster
  namespace: openshift-monitoring
spec:
  replicationFactor: 2
  retentionPeriod: 15d
  vminsert:
    replicaCount: 2
    resources:
      limits:
        cpu: '1'
        memory: 1000Mi
      requests:
        cpu: 500m
        memory: 500Mi
  vmselect:
    cacheMountPath: /select-cache
    replicaCount: 2
    resources:
      limits:
        cpu: '1'
        memory: 1000Mi
      requests:
        cpu: 500m
        memory: 500Mi
    storage:
      volumeClaimTemplate:
        spec:
          resources:
            requests:
              storage: 2Gi
  vmstorage:
    replicaCount: 2
    resources:
      limits:
        cpu: '1'
        memory: 1500Mi
    storage:
      volumeClaimTemplate:
        spec:
          resources:
            requests:
              storage: 10Gi
    storageDataPath: /vm-data
```

We need to place it in the `openshift-monitoring` namespace so that OKD console could query it.

Now we can deploy `VMAgent` so that it would convert prometheus-operator's `ServiceMonitors`/`PodMonitoring` into VM-specific objects:
```yaml
apiVersion: operator.victoriametrics.com/v1beta1
kind: VMAgent
metadata:
  name: vmagent
  namespace: openshift-monitoring
spec:
  selectAllByDefault: true
  resources:
    limits:
      cpu: 500m
      memory: 850Mi
    requests:
      cpu: 250m
      memory: 350Mi
  extraArgs:
    memory.allowedPercent: '40'
    configAuthKey: 'foobar'
  replicaCount: 1
  serviceAccountName: prometheus-k8s
  remoteWrite:
    - url: >-
        http://vminsert-vmcluster.openshift-monitoring.svc.cluster.local:8480/insert/0/prometheus/api/v1/write
  secrets:
  - metrics-client-certs
  - kube-etcd-client-certs
  configMaps:
  - serving-certs-ca-bundle
  - kubelet-serving-ca-bundle
```
OKD cluster serves system metrics from kubelet/etcd via HTTPS, so this VMAgent pod will mount CA bundles and secrets to access them.

Now we also need an additional, home-grown service to rewrite requests for the console. The reason being is that OKD console uses Thanos API, connecting to `thanos-querier` so that it could display metrics from system Prometheus and user-level Prometheus.

In our deployment we don't need it - a single VM cluster is serving all requests. As a result, we can deploy a simple Nginx to route Thanos API requests to VictoriaMetrics:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: vm-to-prom-proxy-conf
  namespace: openshift-monitoring
data:
  vm-proxy.conf: |
    server {
      listen       8080;
      listen       [::]:8080;
      location / {
        proxy_pass http://vmselect-vmcluster:8481/select/0/prometheus/;
      }
    }
```

Now we can deploy nginx, wrapped in `oauth-proxy` so that it could use in-cluster CA and self-signed certificates:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vm-to-prom-proxy
  namespace: openshift-monitoring
spec:
  selector:
    matchLabels:
      app: vm-to-prom-proxy
  replicas: 1
  template:
    metadata:
      labels:
        app: vm-to-prom-proxy
    spec:
      containers:
      - name: nginx
        image: quay.io/packit/nginx-unprivileged:1.21.6
        volumeMounts:
            - name: nginx-conf
              mountPath: /etc/nginx/conf.d
              readOnly: true
      - resources:
          requests:
            cpu: 1m
            memory: 20Mi
        terminationMessagePath: /dev/termination-log
        name: prometheus-proxy
...
```
This pod would use the same secrets/configmaps as the original OKD thanos-querier pod.

Now existing services need to be reconfigured to point to the proxy:
```yaml
---
kind: Service
apiVersion: v1
metadata:
  name: prometheus-k8s
  namespace: openshift-monitoring
spec:
  ports:
    - name: web
      protocol: TCP
      port: 9091
      targetPort: web
  selector:
    app: vm-to-prom-proxy
---
kind: Service
apiVersion: v1
metadata:
  name: prometheus-k8s-thanos-sidecar
  namespace: openshift-monitoring
spec:
  ports:
    - name: thanos-proxy
      protocol: TCP
      port: 10902
      targetPort: thanos-proxy
  selector:
    app: vm-to-prom-proxy
---
kind: Service
apiVersion: v1
metadata:
  name: thanos-querier
  namespace: openshift-monitoring
spec:
  ports:
    - name: web
      protocol: TCP
      port: 9092
      targetPort: web
    - name: tenancy-rules
      protocol: TCP
      port: 9093
      targetPort: tenancy-rules
    - name: metrics
      protocol: TCP
      port: 9094
      targetPort: metrics
  selector:
    app: vm-to-prom-proxy
```

Now we're ready to scale down the existing `thanos-querier`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: thanos-querier
  namespace: openshift-monitoring
spec:
  replicas: 0
```

and voila.

{{< figure src="/images/okd-vm-02.png" caption="VictoriaMetrics running in openshift-monitoring" >}}

After all these operations OKD console would still display metrics for pods/deployments and can use
the in-console UI to make requests, but the requests would be processed by VictoriaMetrics. One of the most
immediate benefits would be lower resource consumption.

{{< figure src="/images/okd-vm-03.png" caption="Pod details" >}}

Additionally, we can deploy `VMAlert` component to route alerts to OKD Alertmanager:
```yaml
apiVersion: operator.victoriametrics.com/v1beta1
kind: VMAlert
metadata:
  name: vmalert
  namespace: openshift-monitoring
spec:
  replicaCount: 1
  datasource:
    url: "http://vmselect-vmcluster.openshift-monitoring.svc.cluster.local:8481/select/0/prometheus"
  notifier:
    url: "http://vmalertmanager-vmalertmanager.openshift-monitoring.svc.cluster.local:9093"
  evaluationInterval: "30s"
  ruleSelector: {}
  extraArgs:
    remoteWrite.url: http://vminsert-vmcluster.openshift-monitoring.svc.cluster.local:8480/insert/0/prometheus
```

and expose VMSelect to make use of VM UI:
```yaml
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  name: vmselect
  namespace: openshift-monitoring
spec:
  to:
    kind: Service
    name: vmselect-vmcluster
    weight: 100
  port:
    targetPort: http
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
  wildcardPolicy: None
```

{{< figure src="/images/okd-vm-04.png" caption="VMUI" >}}

## Conclusion

VictoriaMetrics is a powerful monitoring solution with several distinct features and lower resource
consumption. VM operator is making VictoriaMetrics deployment a breeze.

Replacing the in-cluster monitoring solution in OKD is however not trivial, as it requires overriding
operator settings. While the procedure may seem complicated, doing so is still possible, showing the flexibility of OKD and
operator pattern in general
