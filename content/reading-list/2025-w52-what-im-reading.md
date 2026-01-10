---
title: "21-31 December 2025"
date: 2025-31-01T00:00:00+02:00
draft: false
type: "reading-list"
url: "/reading-list/2025-w52/"
aliases:
  - "/posts/2025-w52-what-im-reading/"
comments:
  host: m.vrutkovs.eu
  username: vadim
  id: 115819374880335241
---

One more "what I'm reading" for 2025:

* [vm.overcommit_memory=2 is always the right setting for servers](https://ariadne.space/2025/12/16/vmovercommitmemory-is-always-the-right.html)

  The `vm.overcommit_memory=2` setting is recommended for servers because it disables memory overcommit, ensuring immediate and debuggable allocation failures or guaranteed success, unlike the default deferred promise model which complicates debugging.

  Tags: Memory, Overcommit, Kernel, Allocation, Debugging

* [How capacity hints work in Go](https://www.grobinson.net/2023/09/30/how-capacity-hints-work-in-go/)

  Today we will look at what capacity hints are in Go and how they work for slices and maps. We will see that when creating slices the Go runtime always allocates the requested capacity. However when creating maps the Go runtime uses lazy allocation for small hints, and allocates more capacity than hinted for large hints. Hopefully by the end of this page you will have a much better understanding of how both slices and maps work internally and how their memory is allocated and resized by the Go runtime.

  Tags: Go, Slice, Map, Capacity, Memory

* [Ralph Wiggum as a "software engineer"](https://ghuntley.com/ralph/)

  😎Here's a cool little field report from a Y Combinator hackathon event where they put Ralph Wiggum to the test."We Put a Coding Agent in a While Loop and It Shipped 6 Repos Overnight"https://github.com/repomirrorhq/repomirror/blob/main/repomirror.mdIf you've seen my socials lately,

  Tags: Ralph, Agent, Loop, Coding, Tuning

* [The best books, films and TV that tackled AI + tech in 2025](https://www.bloodinthemachine.com/p/the-best-books-films-and-tv-that)

  The Great Blood in the Machine Guide to All Media: best nonfiction books, films, and TV shows on tech and AI in 2025.

  Tags: AI, Tech, Media, Critique, Labor

* [I got hacked, my server started mining Monero this morning.](https://blog.jakesaunders.dev/my-server-started-mining-monero-this-morning/)

  A server was compromised through an RCE vulnerability in its Next.js-based Umami analytics container, leading to 10 days of Monero cryptomining, but robust container isolation prevented host system escape.

  Tags: Security, Container, Exploit, Hacking, NextJS

* [AI vending machine lost $1,000 to social engineering](https://boingboing.net/2025/12/18/ai-vending-machine-lost-1000-to-social-engineering.html)

  Anthropic's AI ran a vending machine for three weeks. Reporters convinced it to go communist and give everything away free.

  Tags: AI, Vending, Security, Social, Experiment

* [North Korean infiltrator caught working in Amazon IT department thanks to lag — 110ms keystroke input raises red flags over true location](https://www.tomshardware.com/tech-industry/cyber-security/north-korean-infiltrator-caught-working-in-amazon-it-department-thanks-to-lag-110ms-keystroke-input-raises-red-flags-over-true-location)

  A barely perceptible keystroke delay was the smoking gun that led to the uncovering of a malign imposter.

  Tags: Amazon, Security, Infiltrator, Espionage, Lag

* [Larian’s AI Usage Is A Perfect Storm Of Video Game Industry Ills](https://aftermath.site/podcasts/aftermath-hours-podcast-larian-ai-divinity-baldurs-gate/)

  "This is part of the larger story of video game industry precarity"

  Tags: Larian, AI, Gaming, Labor, Podcast

* [An uncomfortable but necessary discussion about the Debian bug tracker](https://nibblestew.blogspot.com/2025/12/an-uncomfortable-but-necessary.html?m=1)

  The Debian bug tracker's outdated email-only interface creates a terrible, insecure user experience that actively hinders contributions. An idea on how to improve and continuously integrate the new solution is proposed.

  Tags: Debian, Bug, Email, Legacy, Security

* [Integrating the NOUS E10 ZigBee Smart CO₂, Temperature & Humidity Detector with ZHA](https://www.bexelbie.com/2025/12/23/nous-e10-zha-quirk)

  Integrating the NOUS E10 ZigBee CO₂ detector into ZHA with a custom quirk.

  Tags: Zigbee, HomeAssistant, Quirk, Sensor, Tuya

* [A Mole Infiltrated the Highest Ranks of American Militias. This Is What He Found.](https://www.propublica.org/article/ap3-oath-keepers-militia-mole)

  Disgusted by Jan. 6, John Williams set out on a two-year undercover operation. The one person he told was a ProPublica reporter.

  Tags: Militias, Infiltration, Extremism, Undercover, Vigilante

* [How The Widget Revolutionized Canned Beer](https://hackaday.com/2025/08/14/how-the-widget-revolutionized-canned-beer/)

  Walk into any pub and order a pint of Guinness, and you’ll witness a mesmerizing ritual. The bartender pulls the tap, fills the glass two-thirds full, then sets it aside to settle before topp…

  Tags: Widget, Beer, Engineering, Innovation, Nitrogen

* [Saving Millions on Logging: Finding Relevant Savings](https://product.hubspot.com/blog/savings-logging-part1)

  In this two-part blog series, we will look at a structured method we use for approaching cost savings work and demonstrating how we apply it at Hubspot to save millions on the storage costs of our application logs.

  Tags: Cost, Logging, Storage, Engineering, Optimization

* [I'm returning my Framework 16](https://yorickpeterse.com/articles/im-returning-my-framework-16/)

  Why Framework 16 is not worth its €2000 price due to non-premium design, display issues, excessive weight, and various usability flaws, despite its repairability and Linux compatibility

  Tags: Framework, Laptop, Linux, Hardware, Review

* [How Rob Pike got spammed with an AI slop “act of kindness”](https://simonwillison.net/2025/Dec/26/slop-acts-of-kindness/)

  Rob Pike received an unsolicited, AI-generated "thank you" email, which infuriated him. Simon Willison criticizes this practice, highlighting the ethical issues of unreviewed AI agents sending unprompted communications to real people and wasting their time, deeming it an irresponsible application of the technology

  Tags: AI, Spam, Agent, Ethics, Pike

* [Defeating Nondeterminism in LLM Inference](https://thinkingmachines.ai/blog/defeating-nondeterminism-in-llm-inference/)

  Reproducibility is a bedrock of scientific progress. However, it’s remarkably difficult to get reproducible results out of large language models.For example, you might observe that asking ChatGPT the same question multiple times provides different results. This by itself is not surprising, since getting a result from a language model involves “sampling”, a process that converts the language model’s output into a probability distribution and probabilistically selects a token.What might be more surprising is that even when we adjust the temperature down to 0This means that the LLM always chooses the highest probability token, which is called greedy sampling. (thus making the sampling theoretically deterministic), LLM APIs are still not deterministic in practice (see past discussions here, here, or here). Even when running inference on your own hardware with an OSS inference library like vLLM or SGLang, sampling still isn’t deterministic (see here or here).

  Tags: Determinism, Inference, Numeric, Batch, Kernel

* [Premium - How The AI Bubble Bursts In 2026](https://www.wheresyoured.at/premium-how-the-ai-bubble-bursts-in-2026/)

  Hello and welcome to the final premium edition of Where's Your Ed At for the year. Since kicking off premium, we've had some incredible bangers that I recommend you revisit (or subscribe and read in the meantime!): * The Hater's Guide To NVIDIA, a comprehensive guide to the largest and weirdest

  Tags: AI, Bubble, OpenAI, Oracle, Finance

* [How To Argue With An AI Booster](https://www.wheresyoured.at/how-to-argue-with-an-ai-booster/)

  This extensive guide equips readers to counter common, often vague and misleading, arguments from AI boosters by exposing the lack of real-world utility, economic viability, and factual basis behind generative AI's massive hype and investment.

  Tags: AI, Critic, Finance, Hype, Tech

* [NVIDIA Isn't Enron - So What Is It?](https://www.wheresyoured.at/nvidia-isnt-enron-so-what-is-it/)

  Don't you think that NVIDIA now resembled Dotcom bubble companies?

  Tags: NVIDIA, AI, Finance, Scandal, GPU

* [The Enshittifinancial Crisis](https://www.wheresyoured.at/the-enshittifinancial-crisis/)

  An overview of the upcoming financial crisis caused by unrestrained AI investments.

  Tags: AI, Bubble, Finance, Venture, Market

* ["Why is the Rust compiler so slow?"](https://sharnoff.io/blog/why-rust-compiler-slow)

  A developer reduced Rust compilation time in Docker from 175s to 9.1s by systematically profiling `rustc` and LLVM, then applying optimizations including LTO/debug symbol disabling, LLVM inlining adjustments, async function refactoring, enabling generic sharing, and switching from Alpine to Debian.

  Tags: Rust, Compiler, Performance, Optimization, Docker

* [Xz format inadequate for general use](https://www.nongnu.org/lzip/xz_inadequate.html)

  One of the challenges of digital preservation is the evaluation of data formats. It is important to choose well-designed data formats for general use. This article describes the reasons why the xz compressed data format is inadequate for most uses, including long-term archiving, data sharing, and free software distribution. The relevant weaknesses and design errors in the xz format are analyzed and, where applicable, compared with the corresponding behavior of the bzip2, gzip, and lzip formats. 

  Tags: XZ, Compression, Format, Integrity, Archiving

* [Backing up Spotify](https://annas-archive.li/blog/backing-up-spotify.html)

  Anna Archive backed up Spotify (metadata and music files). It’s distributed in bulk torrents (~300TB). It’s the world’s first “preservation archive” for music which is fully open (meaning it can easily be mirrored by anyone with enough disk space), with 86 million music files, representing around 99.6% of listens.

  Tags: Spotify

* [Obsidian’s CEO on why productivity tools need community more than AI](https://www.theverge.com/decoder-podcast-with-nilay-patel/760522/obsidian-ceo-steph-ango-kepano-productivity-software-notes-app)

  Steph “kepano” Ango on becoming the CEO of Obsidian and why he thinks you don’t need AI to be more productive.

  Tags: Productivity, Note, Community, Software, AI

* [Embark: Dynamic documents for making plans](https://www.inkandswitch.com/embark/)

  Gradually enriching a text outline with travel planning tools.

  Tags: Document, Planning, Dynamic, Outline, Computation

* [Compile and Install a Linux Kernel in Asahi Linux](https://blog.clf3.org/post/asahi-kernel-compile/)

  How to compile and install a Linux kernel in Asahi Linux - a linux distribution for Apple Silicon Macs.

  Tags: Kernel, Asahi, Linux, Compile, Apple

* [Learn why you can’t ping a Kubernetes service](https://medium.com/@danielepolencic/learn-why-you-cant-ping-a-kubernetes-service-dec88b55e1a3)

  In this article, you will learn how ClusterIP services and kube-proxy work in Kubernetes.

  Tags: Kubernetes, Service, Network, Iptable, Proxy

* [i'm just having fun](https://jyn.dev/i-m-just-having-fun/)

  programming isn't a competition

  Tags: Programming, Learning, Experiment, Passion, Empowerment

* [How I think about Kubernetes](https://garnaudov.com/writings/how-i-think-about-kubernetes/)

  More than a container orchastrator

  Tags: Kubernetes, Declarative, Runtime, Type, Reconcile

* [Make a smarter Diffuser :: Digital Dilemma](https://digdilem.org/home-automation/smarter-diffuser/)

  Making a diffuser a little smarter Making nicer smells My dumb diffuserI bought this bargain diffuser second-hand from Ebay last year. You fill the container with water and add a few drops of an essential oil and it makes your room smell nice. There’s a little ultrasonic emitter inside that turns the liquid into a cool mist that pours forth from the tip.It works well enough like this. You press a button and it starts. You press the same button two more times and it stops. There are some pretty lights too.

  Tags: Diffuser, Automation, ESPHome, Hardware, DIY

* [Stopping systemd services under memory pressure](https://blog.cyplo.dev/posts/2025/12/stopping-services-under-memory-pressure/)

  This article presents a Nix-based (but portable Bash) systemd service designed to automatically stop and start other services based on configurable memory thresholds, preventing Out-Of-Memory errors on servers with multiple responsibilities.

  Tags: Memory, Systemd, Service, Automation, Monitor

* [Dealing with Time in the Roman Calendar](https://aransentin.github.io/roman_calendar/)

  How bad do you think the Roman Calendar was? It was a lot worse.

  Tags: Calendar, Roman, Time, History, Ancient

* [My first KubeCon + CloudNativeCon: A journey through community, inclusivity, and neurodiversity](https://www.cncf.io/blog/2025/12/04/my-first-kubecon-cloudnativecon-a-journey-through-community-inclusivity-and-neurodiversity/)

  Stepping into my first KubeCon + CloudNativeCon, held this year in November in Atlanta, Georgia, felt like entering a world I had been following from afar for…

  Tags: Community, Neurodiversity, Inclusion, KubeCon, OpenTelemetry

* [Self-Host Weekly #151: Figgy Pudding](https://selfh.st/weekly/2025-12-26/)

  Backing up Spotify, a modern take on recipes, and strange software names

  Tags: SelfHost, Software, Backup, Security, Media

* [Zed Moves Toward Secure-by-Default: Introducing Worktree Trust - Zed Blog](https://zed.dev/blog/secure-by-default)

  From the Zed Blog: We're introducing a new worktree trust mechanism while maintaining options for a low-friction experience you expect from Zed.

  Tags: Security, Zed, Trust, Vulnerability, Restricted

* [Merry Christmas, Ya Filthy Animals (2025) — Ludicity](https://ludic.mataroa.blog/blog/merry-christmas-ya-filthy-animals-2025/)

  Tags: Reflection, Uncertainty, Mortality, Generosity, Ethics

* [I want a better build executor](https://jyn.dev/i-want-a-better-build-executor/)

  I want a way to gradually transition existing builds to be hermetic.

  Tags: Build, Executor, Tracing, Query, Ronin

* [Sam Altman’s Dirty DRAM Deal](https://www.mooreslawisdead.com/post/sam-altman-s-dirty-dram-deal)

  Or: How the AI Bubble, Panic, and Unpreparedness Stole ChristmasWritten by Tom of Moore’s Law Is DeadSpecial Assistance by KarbinCry & kari-no-sugataBased on this Video: https://youtu.be/BORRBce5TGwIntroduction — The Day the RAM Market SnappedAt the beginning of November, I ordered a 32GB DDR5 kit for pairing with a Minisforum BD790i X3D motherboard, and three weeks later those very same sticks of DDR5 are now listed for a staggering $330– a 156% increase in price from less than a month ago! At

  Tags: AI, DRAM, Scarcity, Market, OpenAI

* [What's Wrong with Kubernetes Today](https://www.devzero.io/blog/whats-wrong-with-kubernetes-today)

  Kubernetes isn’t built for efficiency. Learn rightsizing, smart bin packing, and autoscaling fixes to cut costs and boost utilization.

  Tags: Kubernetes, Cost, Optimization, Resource, Efficiency

* [DIY Zigbee Presence Sensor with an ESP32-C6](https://smarthomescene.com/guides/diy-zigbee-mmwave-presence-sensor-with-esp32-c6-and-ld2410/)

  Detailed guide for creating your own Zigbee presence sensor with an ESP32-C6 board and a HLK-LD2410C mmWave radar sensor.

  Tags: Zigbee, Sensor, ESP32, Radar, DIY

* [On LLMs in programming](https://blog.danieljanus.pl/2025/12/27/llms/)

  A "conscious LLM-skeptic," details his anxiety regarding the rapid rise and impact of LLMs in programming. While acknowledging their utility, he consciously chooses to direct his attention and excitement towards programming fundamentals rather than LLMs.

  Tags: LLM, Programming, Anxiety, Attention, Change

* [Commoning open-source versus growth-hacking open-source](https://garagehq.deuxfleurs.fr/blog/2025-commoning-opensource/)

  Deuxfleurs, a French open-source community making Garage S3 server, discusses the differences between commoning open-source and growth-hacking open-source. They argue that commoning open-source is more sustainable and ethical than growth-hacking open-source.

  Tags: OpenSource, License, Commoning, Strategy, AGPL
