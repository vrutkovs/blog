---
title: "Installing OKD using Assisted Installer in a disconnected environment"
date: 2022-09-05T10:35:00+02:00
draft: false
comments:
  host: social.vrutkovs.eu
  username: vadim
  id: AOecTLKBFyKU9lkcV6
---

## Architecture

Setting up OKD may become a challenge when you don't have experience - this is where Assisted Installer may be helpful. In restricted networking environments setting up a mirror registry and configuring installer to use it instead of quay.io requires few additional steps.

This tutorial would cover the process of mirroring OKD release and steps to install disconnected Assisted Installer. On a helper node we'll run container registry, copy OKD release images there and run Assisted Installer - a service which can guide us through creating a cluster which can only access the internal registry.

Note, that in my setup helper node with the registry has access both to quay.io and internal network (so called, "partially disconnected" installation). If your installation environment is fully air gapped, check out [oc-mirror docs](https://docs.okd.io/latest/installing/disconnected_install/installing-mirroring-disconnected.html) for mirror configuration options.

Our first step would be setting up container registry on a helper node.

## DNS names

The following DNS records will be used in this post:
* `registry.vrutkovs.eu` - points to helper VM where disconnected registry mirroring OKD content is situated
* `assisted.vrutkovs.eu` - points to helper VM where Assisted Service will be running
* `api.disconnected.vrutkovs.eu`, `api-int.disconnected.vrutkovs.eu`, `*.apps.disconnected.vrutkovs.eu` - API, internal API and router records pointing to a machine which will be used as single node OKD cluster

## Prepare certificates for registry

Use `openssl` to generate certificates or, simply, use LetsEncrypt wildcard cert:
```
mkdir /srv/registry/certs -p
cp -vf /etc/letsencrypt/live/vrutkovs.eu/fullchain.pem /srv/registry/certs/domain.crt
cp -vf /etc/letsencrypt/live/vrutkovs.eu/privkey.pem /srv/registry/certs/domain.key
```

## Generate authentication for local registry

Login: `root`
Password: `sikret`
```
mkdir /srv/registry/auth -p
podman run --rm --entrypoint htpasswd docker.io/registry:2.7.0 -Bbn root sikret > /srv/registry/auth/htpasswd
```

## Start a local registry

```
podman run -d \
  --restart=always \
  --name registry \
  -v /srv/registry/auth:/auth:z \
  -v /srv/registry/certs:/certs:z \
  -e REGISTRY_AUTH=htpasswd \
  -e REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
  -e REGISTRY_HTTP_ADDR=0.0.0.0:443 \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  -p 443:443 \
  docker.io/registry:2.7.0
podman login registry.vrutkovs.eu
```

## Host local source of Fedora CoreOS images

```
mkdir /srv/registry/fcos
cd /srv/registry/fcos
export FCOS_VERSION="36.20220806.3.0"
wget https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/${FCOS_VERSION}/x86_64/fedora-coreos-${FCOS_VERSION}-live.x86_64.iso
podman run -d \
  --name image-storage \
  -v /srv/registry/fcos:/data:z \
  -w /data \
  -p 3000:3000 \
  docker.io/python:latest python3 -m http.server 3000
```

## Pull secret

Our registry requires authentication, so we'll need to re-login to get a pullsecret:
```
mkdir ~/.docker
podman login registry.vrutkovs.eu --authfile=~/.docker/config.json
cat ~/.docker/config.json
```

## Mirror OKD and additional images to the local registry

In order to run Assisted Installer we're going to need to mirror some more additional images. `oc-mirror` is a great tool to keep those updated:
```yaml
wget https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable-4.11/openshift-client-linux-4.11.1.tar.gz -O - | sudo tar -xz -C /usr/local/bin
wget https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable-4.11/oc-mirror.tar.gz -O - | sudo tar -xz -C /usr/local/bin
chmod a+x /usr/local/bin/oc-mirror

export OKD_VERSION="4.11.0-0.okd-2022-10-15-073651"

cat > /tmp/oc-mirror-config <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  platform:
    channels:
      - name: stable-4
        type: okd
        minVersion: "${OKD_VERSION}"
        maxVersion: "${OKD_VERSION}"
  additionalImages:
    - name: quay.io/vrutkovs/okd-rpms:4.11
    - name: quay.io/centos7/postgresql-12-centos7:latest
    - name: quay.io/edge-infrastructure/assisted-service:latest
    - name: quay.io/edge-infrastructure/assisted-image-service:latest
    - name: quay.io/edge-infrastructure/assisted-installer:latest
    - name: quay.io/edge-infrastructure/assisted-installer-ui:latest
    - name: quay.io/edge-infrastructure/assisted-installer-agent:latest
    - name: quay.io/edge-infrastructure/assisted-installer-controller:latest
    - name: quay.io/karmab/aicli
EOF
```

`oc-mirror` can also make a custom mirrored OperatorHub:
```yaml
cat >> /tmp/oc-mirror-config << EOF
  operators:
    - catalog: registry.access.redhat.com/redhat/community-operator-index:v4.11
      headsOnly: false
      packages:
        - name: argocd-operator
        - name: grafana-operator
EOF
```

See other oc-mirror features at the [docs](https://docs.okd.io/latest/installing/disconnected_install/installing-mirroring-disconnected.html)

Lets mirror this to our registry:
```
oc mirror --config /tmp/oc-mirror-config docker://registry.vrutkovs.eu
```

## Run Assisted Installer in podman

Fetch configuration and pod definition:
```
mkdir /srv/assisted-service
cd /srv/assisted-service
wget -O disconnected-okd-configmap.yml https://github.com/openshift/assisted-service/raw/master/deploy/podman/okd-configmap.yml
wget -O disconnected-pod.yml https://github.com/openshift/assisted-service/raw/master/deploy/podman/pod.yml
```

These images are using `quay.io` and use `127.0.0.1` as address. Instead we want to use the local mirror and `assisted.vrutkovs.eu`:

```yaml
sed -i 's;quay.io/;registry.vrutkovs.eu/;g' disconnected-pod.yml
sed -i 's;127.0.0.1:8;assisted.vrutkovs.eu:8;g' disconnected-okd-configmap.yml
sed -i '/RELEASE_IMAGES/d' disconnected-okd-configmap.yml
sed -i '/OS_IMAGES/d' disconnected-okd-configmap.yml
sed -i '/OKD_RPMS_IMAGE/d' disconnected-okd-configmap.yml
cat >> disconnected-okd-configmap.yml << EOF
  OS_IMAGES: |
    [
      {
        "openshift_version":"4.11",
        "cpu_architecture":"x86_64",
        "url":"http://assisted.vrutkovs.eu:3000/fedora-coreos-${FCOS_VERSION}-live.x86_64.iso",
        "version":"${FCOS_VERSION}"
      }
    ]
  RELEASE_IMAGES: |
    [
      {
        "openshift_version":"4.11",
        "cpu_architectures":["x86_64"],
        "url":"registry.vrutkovs.eu/openshift/release-images:${OKD_VERSION}-x86_64",
        "version":"${OKD_VERSION}",
        "default":true
      }
    ]
  OKD_RPMS_IMAGE: registry.vrutkovs.eu/vrutkovs/okd-rpms:4.11
EOF
```

The cluster's mirroring settings prevent mirroring by tags, so we need custom setting to use Assisted Installer controller image via digest

```yaml
cat >> disconnected-okd-configmap.yml << EOF
  CONTROLLER_IMAGE: $(skopeo inspect docker://registry.vrutkovs.eu/edge-infrastructure/assisted-installer-controller:latest --format "{{.Name}}@{{.Digest}}")
EOF
```

Once config and pod definition are updated for disconnected use, lets use podman to start Assisted Installer:
```
podman play kube --configmap disconnected-okd-configmap.yml disconnected-pod.yml
```

## OKD installation

Now we can start the installation, let's click "Create New Cluster" at `assisted.vrutkovs.eu:8080`:

{{< figure src="../../images/okd-disconnected-assisted-01.png" caption="Cluster details" >}}

On "Operators" screen we'll just click "Next" - no operators were mirrored:

{{< figure src="../../images/okd-disconnected-assisted-02.png" caption="Operators" >}}

At "Host discovery" stage usually, we'd generate the ISO and boot from it, but it would attempt to pull images from `quay.io`, so first, we need to patch these with mirroring configuration via Ignition override. This assisted installer option
is available via API only, so we'll use [aicli](https://github.com/karmab/aicli) to interact with it:
```
alias aicli='podman run --net host -it --rm -e AI_URL=assisted.vrutkovs.eu:8080 -v /tmp:/workdir registry.vrutkovs.eu/karmab/aicli:latest'
```

Before discovery ISO can be booted it needs to be amended with mirroring configuration:
```yaml
cat > /tmp/install-override<<EOF
registry_url: registry.vrutkovs.eu:443
installconfig:
  imageContentSources:
  - mirrors:
    - registry.vrutkovs.eu/centos7
    source: quay.io/centos7
  - mirrors:
    - registry.vrutkovs.eu/edge-infrastructure
    source: quay.io/edge-infrastructure
  - mirrors:
    - registry.vrutkovs.eu/openshift/release-images
    source: quay.io/openshift/okd
  - mirrors:
    - registry.vrutkovs.eu/openshift/release
    source: quay.io/openshift/okd-content
EOF
```

The installer also needs an SSH key to be able to ssh on the nodes:
```yaml
cat >>/tmp/install-override<<EOF
ssh_public_key: |
  $(cat ~/.ssh/id_rsa.pub)
EOF
```

Now we can patch the infrastructure environment, telling assisted image service to have these changes ending up in the cluster:
```
aicli update cluster disconnected --paramfile /workdir/install-override
aicli update infraenv disconnected --paramfile /workdir/install-override
```
where `disconnected` is the cluster name.

Click 'Add Host' to configure discovery ISO (ssh key is already filled in by `aicli`):
{{< figure src="../../images/okd-disconnected-assisted-03.png" caption="Add Host dialog" >}}

"Generate Discovery ISO" button will show a link and suggested command to download discovery ISO:
{{< figure src="../../images/okd-disconnected-assisted-04.png" caption="Discover ISO link" >}}

Alternatively, you can use `aicli info iso disconnected` to get ISO URL. `aicli` can work with the API the same way as UI (see [docs](https://aicli.readthedocs.io/en/latest)), but in this tutorial, I'll be using UI for the sake of demonstration.

Now we can boot hosts with discovery ISO.

Wait for all nodes to register themselves:
{{< figure src="../../images/okd-disconnected-assisted-05.png" caption="The host has registered itself" >}}
and click "Next"

This is a bare-metal installation, so on "Storage" screen we proceed by clicking "Next".

Network details are autodetected from DHCP:
{{< figure src="../../images/okd-disconnected-assisted-06.png" caption="Installation details" >}}

On the "Review and create" screen lets double-check all parameters:
{{< figure src="../../images/okd-disconnected-assisted-07.png" caption="Installation details" >}}
and start the installation.

After Assisted Installer verifies that nodes can pull all necessary images it would run the installer, generate `bootstrap.ign`, and pass it to the bootstrap node. The node would apply Ignition without reboot, run `bootkube.service`, and other bootstrap tasks.
Now the node would run Machine Config Server so that other masters would be able to fetch master Ignition (if necessary), convert bootstrap node into master, and reboot.
{{< figure src="../../images/okd-disconnected-assisted-08.png" caption="Install step 5 out of 10" >}}
and start the installation.

The host would remain in "Rebooting" state until the assisted-installer controller would not be started as a pod and report the installation progress back to the
{{< figure src="../../images/okd-disconnected-assisted-09.png" caption="Install step 8 out of 10" >}}
and start the installation.

Now the host is installed and cluster installations proceeds. Once the ingress and console are running Assisted Installer UI would display the kubeadmin password and a link to the cluster console.
{{< figure src="../../images/okd-disconnected-assisted-10.png" caption="Install step 9 out of 10" >}}
and start the installation.

Once all operators have reported success the cluster installation is complete, and voila.
