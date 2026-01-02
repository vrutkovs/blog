---
title: "29 November - 5 December 2025"
date: 2025-12-06T00:00:00+02:00
draft: false
type: "reading-list"
url: "/reading-list/2025-w49/"
aliases:
  - "/posts/2025-w49-what-im-reading/"
comments:
  host: m.vrutkovs.eu
  username: vadim
  id: 115671947087295400
---

Here are the articles I've read this week:

* [How I Turned Gemini CLI into a Multi-Agent System with Just Prompts](https://aipositive.substack.com/p/how-i-turned-gemini-cli-into-a-multi)

  A deep dive into creating a multi-agent orchestration system in the Gemini CLI using only native features. My weekend Experiment with AI Sub-Agents, Thank you Anthropic!

  Tags: Gemini, Agent, Prompt, System, Command

* [Compressed Filesystems á la Language Models](https://grohan.co/2025/11/25/llmfuse/)

  A filesystem is the perfect black-box API to model with wacky backends (see “Harder drives”), and besides the joy of training an LLM for fun - there were a few deeper truths about language models that I wanted to explore.

  Tags: Filesystem, LLM, Compression, FUSE, Training

* [What does it mean to be massively against AI?](https://pythonbynight.com/blog/massively-against-ai)

  A question was asked on Mastodon, "Is this platform still massively against AI or has it moved towards acceptance?" But what does that mean?
  Opposition to "AI" on platforms like Mastodon often stems from the term's undefined nature and concerns over the industry's problematic ethical, societal, and environmental implications, rather than the technology's potential for workflow optimization.

  Tags: AI, Criticism, Ethics, Technology, Industry

* [Giving a rootful Podman container its own IP](https://www.blog.montgomerie.net/posts/2025-10-18-giving-a-rootful-podman-container-its-own-ip/)

  A cleaner, less "icky" method for assigning a rootful Podman container its own IP address, accessible by both the host and the LAN, by leveraging an existing Linux bridge and an unmanaged Podman network, overcoming common `macvlan`/`ipvlan` drawbacks and a past Netavark bug.

  Tags: Podman, Network, Container, Bridge, Pihole

* [Setting secrets in env vars](https://hugovk.dev/blog/2025/secrets-in-env-vars/)

  This article outlines how to securely manage sensitive environment variables on macOS by integrating 1Password CLI with direnv to prevent secret exfiltration.

  Tags: 1Password, Direnv, Secret, Environment, Shell

* [URL in C - Susam Pal](https://susam.net/url-in-c.html)

  TIL URLs can be a valid C code

  Tags: C, URL, Puzzle, Comment, Syntax

* [Self-Host Weekly #147: Ad-Free](https://selfh.st/weekly/2025-11-28/)

  Default branches, PDF toolkits, streaming subscriptions, and a face full of turkey

  Tags: Selfhost, Software, PDF, Automation, Backup

* [#226 Exporting Events](https://thisweek.gnome.org/posts/2025/11/twig-226/)

  Updates on what happens across the GNOME project from week to week
  
  Tags: GNOME, Update, Development, Feature, Release

* [#227 Circle Benefits](https://thisweek.gnome.org/posts/2025/11/twig-227/)

  Updates on what happens across the GNOME project from week to week

  Tags: GNOME

* [Stop Telling Us XMPP Should Use JSON](https://www.process-one.net/blog/stop-telling-us-xmpp-should-use-json/)

  XML vs. JSON: Stop Worrying About the Wrong Layer

  Tags: XMPP, XML, Performance, Protocol, Federation

* [Dotcom Survivor Syndrome – How Perl’s Early Success Created the Seeds of Its Downfall - Perl Hacks](https://perlhacks.com/2025/11/dotcom-survivor-syndrome-how-perls-early-success-created-the-seeds-of-its-downfall/)

  If you were building web applications during the first dot-com boom, chances are you wrote Perl. And if you're now a CTO, tech lead, or senior architect, you may instinctively steer teams away from it—even if you can’t quite explain why. This reflexive aversion isn’t just a preference. It’s what I call Dotcom Survivor Syndrome

  Tags: Perl, Web, Legacy, Syndrome, Version

* [Go proposal: Type-safe error checking](https://antonz.org/accepted/errors-astype/)

  errors.AsType is a modern alternative to errors.As.

  Tags: Error, Go, Function, Type, Update

* [Self-hosting my photos with Immich](https://michael.stapelberg.ch/posts/2025-11-29-self-hosting-photos-with-immich/)

  For every cloud service I use, I want to have a local copy of my data for backup purposes and independence. Unfortunately, the gphotos-sync tool stopped working in March 2025 when Google restricted the OAuth scopes, so I needed an alternative for my existing Google Photos setup. In this post, I describe how I have set up Immich, a self-hostable photo manager.

  Tags: Immich, Photo, Self-host, Backup, Manager


* [vanbi](https://xeiaso.net/blog/vanbi-01-08-2019/)

  Required reading if you write documentation for a software project.

  Tags: Vanbi, Sisti, Temci, Meknau, API

* [Week Ending November 30, 2025](https://lwkd.info/2025/20251203)

  Developer News
  Tags: Security, Release, Update, Scheduling, Contributor

* [Zed Has Rainbow Brackets - Zed Blog](https://zed.dev/blog/rainbow-brackets)

  From the Zed Blog: A whole new world of color comes to Zed.

  Tags: Zed, Bracket, Tree-sitter, Editor, Feature

* [How to quit Spotify](https://www.bloodinthemachine.com/p/a-complete-guide-to-quitting-spotify)

  This Black Friday, here's a guide to finding the best Spotify alternative

  Tags: Music, Streaming, Spotify, Artist, Ethical

* [Every pod eviction in Kubernetes, explained](https://ahmet.im/blog/kubernetes-evictions/)

  Anyone who is running Kubernetes in a large-scale production setting cares about having a predictable Pod lifecycle. Having unknown actors that can terminate your Pods is a scary thought, especially when you’re running stateful workloads or care about availability in general.There are so many ways Kubernetes terminates workloads, each with a non-trivial (and not always predictable) machinery, and there’s no page that lists out all eviction modes in one place. This article will dig into Kubernetes internals to walk you through all the eviction paths that can terminate your Pods, and why “kubelet restarts don’t impact running workloads” isn’t always true, and finally I’ll leave you with a cheatsheet at the end.
  
  Tags: Eviction, Kubernetes, Pod, Kubelet, Lifecycle
