---
title: "OKD with VictoriaMetrics"
date: 2022-07-29T12:29:00+02:00
draft: true
GHIssueID: 3
---

# Y tho

OKD is an opionionated k8s distro, but it's choices may not suit everyone. Here's an example of how to override them.
For example, one of the most resource-hungry components in the cluster is Prometheus. It is used to store metrics,
collected from various cluster components. Its designed to be resilient, so two instances of Prometheus are running 
in the cluster (one if a single node cluster is deployed).

However, it might not be the best choice for smaller cluster available. You might have heard of [VictoriaMetrics](https://victoriametrics.com/), specificially designed to be high performant TSDB solution.
In this blog post I'll describe how to install it on OKD and explore some options around it.

All manifests described in this blog post are available at https://github.com/vrutkovs/victoriametrics-okd/

# Operators all the way down

OKD 4 is a k8s distro built around the idea of operators. If you're not familiar with the concept, 
operator is an app, running in the cluster, which takes care of deploying and reconciling some child resources (called "operand"(s)). For instance, instead of `kubectl apply` or `helm install` you could write an app, which ensures necessary
objects are created in the cluster, without describing them in YAML, but using your favourite programming language and k8s API.
Thus an operator is a k8s-native service, built to deploy and control user applications.

The benefit of this approach is better control over the operand's lifecycle - the operator watches operand state and ensures changes are applied automatically and the operand is not being removed. This also allows complicated pre- or post-deploy hooks to be executed on update.

# Installing VictoriaMetrics operator

Operators can be bundled in container images, same as any other k8s apps. [OperatorHub](https://operatorhub.io) is a primary source of community-built operators. Apart from hosting operator images, it also has [Operator Lifecycle Manager](https://olm.operatorframework.io/) utility, which allows listing, installing and updating operators easily. OKD comes with OperatorHub subscription and OLM out of the box.

In OKD console you'll find "Operators" tab with OperatorHub subitem. It opens a list of available operators. Operators can be installed in a specific namespace, can be namespace-wide or cluster-wide. Different operator versions can be installed by selecting a channel (if available). OLM will ensure the operator is updated when a new version in the channel is posted.
In VictoriaMetrics case, operator is usually cluster-wide (to scrape metrics from user apps in different namespaces).

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
  logLevel: PANIC
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

On `Resources` tab a list of created k8s resources is displayed. Make sure that `Deployment` there is ready and pods are running without crashlooping.

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

Operator is creating `VMServiceScrape` object automatically, so that VM could monitor itself:
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

Operator can spin up VMAgent for us:
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

Operator would create `vmagent` pod, which scrapes previously mentioned `VMServiceScrape` and send data 
to VictoriaMetrics. We can ensure VM metrics are collected by quiering for `vm_app_version` in the UI.


# Replacing OKD Prometheus with VictoriaMetrics

TODO:
