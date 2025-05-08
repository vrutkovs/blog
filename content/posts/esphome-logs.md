---
title: "ESPHome - persistent logging"
date: 2025-05-08T08:01:00+02:00
draft: false
comments:
  host: m.vrutkovs.eu
  username: vadim
  id: none
---
Recently I started improving the observability status of my home lab and it felt that I was missing some crucial parts. I collected metrics and logs from all machines and built a few beautiful dashboards and yet something was missing. Then it dawned on me - I have a few [ESP microcontrollers](https://shop.m5stack.com/products/atom-lite-esp32-development-kit) scattered around the house, provisioned by [ESPHome](https://www.esphome.io/) and controlled by [Home Assistant](https://www.home-assistant.io/). Are they observable?

They are mostly not, as they can't run a [Prometheus exporter](https://prometheus.io/docs/instrumenting/exporters/) there. Any metrics I can scrape are coming via Home Assistant metrics. I also don't store their logs anywhere, so I have no visibility into the history of the data it sends to HA, etc.

I decided to improve this last part. ESP microcontrollers cannot be configured to run [Vector](https://vector.dev/)/[Promtail](https://grafana.com/docs/loki/latest/send-data/promtail/) log collectors, so this option is off the table. They can be configured to send logs as MQTT messages, but it feels wrong to mix loglines and legitimate messages.

ESPHome can send HTTP requests, so this is the path I chose. Here's how I configured to send log lines as JSON lines to my VictoriaLogs instance:
```
esphome:
  includes:
  - <iostream>
  - <regex>
  - <string.h>

# Enable logging
logger:
  on_message:
    then:
      - http_request.post:
          url: http://gumball.vrutkovs.eu:9428/insert/jsonline?_stream_fields=instance,tag,level
          headers:
            Content-Type: application/json
          json:
            instance: m5stack-atom-echo
            tag: !lambda return to_string(tag);
            # Strip ANSI colors
            _msg: !lambda return std::regex_replace(message, std::regex("\x1b\[[0-9;]*m"), "");
            # Convert int level into a string
            level: !lambda |-
              if (level == 1 ) {
                return "ERROR";
              } else if (level == 2) {
                return "WARN";
              } else if (level == 3) {
                return "INFO";
              } else if (level == 4) {
                return "DEBUG";
              } else if (level == 5) {
                return "VERBOSE";
              } else {
                return "VERY_VERBOSE";
              }
```

This will strip ANSI colors from the message, add appropriate log level and instance tags, and send them to the central log location. Unfortunately, there is no disk to buffer unsuccessful requests, so there is no retry and thus no guarantee that the log line will be delivered.

If you're using Loki for log storage the JSON needs to be reformatted, but it's fairly trivial and left as an exercise to the reader.
