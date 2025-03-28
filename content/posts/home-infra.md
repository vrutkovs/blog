---
title: "Home infra - beyond k8s"
date: 2025-02-20T13:01:00+02:00
draft: false
comments:
  host: m.vrutkovs.eu
  username: vadim
  id: 114233623672937261
---

Recently, running a home server has become less of a nerd hobby and more of a necessity to preserve privacy and protect against enshittification.
However, more experienced users won't just run a single machine and will apply various approaches to satisfy various requirements from themselves and significant others.

In this blog post, I'll describe what kind of infra am I hosting myself and will attempt to describe the reason for some decisions made.

# Gumball

The most common use case for home servers is to store data. For that, you'll want a lot of disk space, so I picked a Mini-ITX motherboard with multiple SATA ports, added various drives, and stuck it in a small computer case. Now it just needs power, Ethernet cable, and done! It still emits quite some noise so I hid in an under TV cabinet.

This machine runs CentOS Stream 9 and with [Cockpit](https://cockpit-project.org/) I can quickly check up on its status and set up Samba shares.

{{< figure src="../../images/home-infra-01.png" caption="Cockpit" >}}

This machine also runs [Jellyfin](https://jellyfin.org/) to stream TV shows or movies. I host several webcams to monitor activity in and outside of the house, so [Frigate](https://frigate.video/) is running on this machine.

{{< figure src="../../images/home-infra-02.png" caption="Podman containers" >}}

Since this machine is distributing sweet-sweet data I assigned it a Gumball hostname.

# Gunter

This machine used to run a lot more services, but then I decided it was not wise to make it a [single point of failure](https://en.wikipedia.org/wiki/Single_point_of_failure). Instead, I bought a rather cheap and underpowered MiniPC on Intel N100. This machine now hosts critical services, and thanks to the CPU being a bit more powerful than an average potato this list of critical services is really short.

Previously I got burned by some DNF-related problems on CentOS and wanted to make this machine hard to break. My tool of choice to achieve that is [Fedora CoreOS](https://fedoraproject.org/coreos/). This OS can update itself atomically - if the upgrade fails it just reverts to the previous successful version. Also, it can apply updates automatically at night, so I don't get disruptions in the middle of the day. The downside of it all is that it pushes to deliver software via containers, so it makes it less easy to experiment. However, since I intend to keep it stable no matter, what it's a benefit for me.

So, what could such a machine host? The first thing I need to run there is [AdGuard Home](https://adguard.com/en/adguard-home/overview.html). This service does all things DNS - it can cache DNS requests, add custom DNS records, and block some ad domains. It also doubles as a DHCP server, so I can also apply custom rules to different devices.

{{< figure src="../../images/home-infra-03.png" caption="AdGuard Home" >}}

Another crucial service is [Home Assistant](https://www.home-assistant.io/) which helps with automation around the house. Alongside it runs [Mosquitto](https://mosquitto.org/) and [Zigbee2MQTT](https://www.zigbee2mqtt.io/) so that Zigbee devices I have installed around the house can be controlled with Home Assistant. The previously mentioned AdGuard custom DNS name allows an app on the phone to control it from any part of the house.

Since this machine is small, not very smart, and may fall on its head I call it Gunter.

# Neptr

Now that we have important bits set up, it's time to have a playground for experiments. Since my daily job is working with OpenShift clusters I chose k8s as a place to run small services with an option of quickly changing or removing them. In my opinion, it leaves much less cruft around and since all k8s are already containerized some services may eventually "upgraded" to persistent (the same happened to Frigate and Jellyfin, now hosted on NAS machine). As an OS I picked Fedora CoreOS - the benefits of it were described earlier. As for the distribution I'm running [k3s](https://k3s.io/), which is - good enough I guess? I don't have enough free hardware to run a full-blown high availability cluster, so it runs on a single node - an ancient by modern standards but still worthy laptop Lenovo X220.

{{< figure src="../../images/home-infra-04.png" caption="k3s monitoring" >}}

Since this machine was initially created for an entirely different purpose, its codename is Neptr.

# Automation

Managing this zoo of machines may become tricky. There are quite a few well-established solutions for k8s - namely [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) which uses the GitOps approach. This makes the k8s cluster self-managed with a git repo - and I'm using private Github repos to store data there. I started writing manifests and charts to split secrets from pure configuration so that the latter could be properly open-sourced. That, however, hasn't happened yet.

{{< figure src="../../images/home-infra-11.png" caption="ArgoCD apps" >}}

Alongside Continuous Delivery some actions need to run on other hosts - for that, I use [Tekton](https://tekton.dev/) to run
Ansible playbooks. For example, with Ansible Home Assistant configuration is laid on the host and the service is restarted. Similarly, a new configuration for Gunter and Gumball is applied by Ansible when a pipeline is triggered by a GitHub push.

{{< figure src="../../images/home-infra-06.png" caption="Ansible via Tekton" >}}

# Overwatch

Maintenance work at home is the worst - you don't get paid, there is no reward to keep it all up and you're to blame when TV shows. This is why its important to quickly diagnose the issue first. Observability is achieved via collecting metrics, logs and alert notifications.

Collecting metrics is probably the simplest task, as [Prometheus](https://prometheus.io) has become an industry standard and most apps already expose metrics in Prometheus format. For OS level metrics multiple exporters can send necessary data. That's what I used until I needed to collect logs too. Instead of running just another container, I figured [Grafana Alloy](https://grafana.com/docs/alloy/latest/) could do both and include the most popular exporters too. This agent now runs on every host and configuration looks much more accessible.

{{< figure src="../../images/home-infra-07.png" caption="Grafana Alloy" >}}

Previously I was using a free [grafana.net](https://grafana.net) account to send metrics and logs too - but I quickly hit the free limits. Instead of supporting their excellent work with money, I chose to try something else. All metrics are sent to [VictoriaMetrics](https://victoriametrics.com/) and most important sent to [grafana.net](https://grafana.net). This option allows me to send important metrics (i.e. systemd service) to the cloud where it can send back alerts via an extremely useful [Grafana IRM](https://grafana.com/products/cloud/irm/) app and get notified of failures quicker.

{{< figure src="../../images/home-infra-08.png" caption="Grafana IRM" >}}

The total amount of metrics I collect is too much for standard Prometheus to handle (80k time series is resource instensive for my resource constraints), but VM handles it with ease. These metrics are used for informational graphs via self-hosted Grafana, the most interesting is Home Assistant exposed metrics to build complicated graphs.

{{< figure src="../../images/home-infra-09.png" caption="VictoriaMetrics" >}}

Similar to metrics, all machines send journald and container logs to [VictoriaLogs](https://victoriametrics.com/products/victorialogs/), which is essentially VictoriaMetrics for logs. It's an excellent choice for resource-constrained machines too, as it doesn't require S3 or fast disk, unlike most alternatives.

{{< figure src="../../images/home-infra-10.png" caption="VictoriaLogs" >}}

# Updates

As much as it's fun to install new things it's tedious to keep them up to date. CentOS has unattended upgrades and FCOS has [zincati](https://coreos.github.io/zincati/), but it doesn't apply to most software. This is where storing manifests in Github to maintain it better is becoming useful. I'm using [Renovate](https://www.mend.io/renovate/) to scan ArgoCD manifests and Ansible configuration for container image references to find installed versions of the
software. Once a new version comes out and the container image is available, Renovate will create a pull request with a proposed version bump and a changelog.

{{< figure src="../../images/home-infra-05.png" caption="renovate" >}}

Once the pull request is merged Tekton pipeline applies it on hosts (or ArgoCD applies it to k8s cluster). Next, the monitoring may alert if the update was unsuccessful - my main approach in this case is reverting a commit. It took quite a while to get right but now it works like a charm.

# Conclusion

Running a server at home is becoming mainstream, but it can range from "single RaspberryPi" all the way up to "a mini data center". For me, I think I found a sweet spot between features and complexity and constantly tweaked selected software stack to ensure it's easy to maintain and get necessary features.
