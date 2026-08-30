# ping-status

A [SwiftBar](https://github.com/swiftbar/SwiftBar) plugin that keeps a connection health indicator in the macOS menu bar: a coloured dot plus average latency, with packet loss and min/max detail in the dropdown.

```
🟢 31ms          ← menu bar
─────────────
Target: 8.8.8.8
Latency avg: 31ms
Latency min/max: 29.603/34.1 ms
Packet loss: 0%
Packets: 5
Last check: 19:42:07
─────────────
Refresh now
```

## Install

This plugin needs SwiftBar, which is **not** part of the work-machine setup — it is deliberately excluded there as a personal tool. On a fresh machine, install it first:

```bash
brew install --cask swiftbar
```

Launch it once so it registers its menu bar item and writes its preferences.

SwiftBar runs every executable in one plugin folder. Rather than copying the script there, point that folder **at this repo** — then `git pull` updates the live plugin with no further steps.

```bash
git clone git@github.com-id:adwiarifin/ping-status.git ~/Projects/mine/ping-status
```

Then **SwiftBar → Preferences → Plugin Folder** and choose `~/Projects/mine/ping-status/plugins`. Verify it took:

```bash
defaults read com.ameba.SwiftBar PluginDirectory
# /Users/adwi/Projects/mine/ping-status/plugins
```

SwiftBar sets `MakePluginExecutable = 1` by default, so it marks the script executable itself — no `chmod` needed.

Finally **SwiftBar → Refresh all**. The dot appears immediately; there is nothing else to configure.

The trade-off of pointing the folder at a repo: SwiftBar will try to run *anything* executable you add under `plugins/`. Keep that directory to plugins only, and put helper scripts elsewhere in the repo.

xbar works too. The script declares `<xbar.*>` metadata, which SwiftBar also reads, so the same file drops into either app unchanged.

## The filename is configuration

`ping-status.10s.sh` — the `10s` is not decoration. SwiftBar parses `<name>.<interval>.<ext>` and re-runs the script on that interval. Rename the file to change it:

| Filename | Refresh |
|---|---|
| `ping-status.10s.sh` | every 10 seconds (default) |
| `ping-status.1m.sh` | every minute |
| `ping-status.30s.sh` | every 30 seconds |

**Keep the interval comfortably above the ping duration.** With the defaults the script spends up to 5 seconds pinging, so 10s leaves reasonable headroom. Drop it to `5s` and each run risks overlapping the next.

## Settings

Three variables at the top of the script:

| Variable | Default | Meaning |
|---|---|---|
| `TARGET` | `8.8.8.8` | host to ping — swap for a gateway or an internal host to measure a different hop |
| `COUNT` | `5` | packets per batch; also the denominator for the loss percentage |
| `TIMEOUT` | `5` | seconds before `ping` exits regardless of replies received |

`COUNT` and `TIMEOUT` interact. macOS `ping` sends one packet per second, so `-c 5` needs roughly 4 seconds plus the round trip. At `TIMEOUT=5` a slow final reply can be cut off and counted as loss, which shows up as a spurious 20% and a yellow dot. If you see intermittent yellow on a connection you believe is healthy, raise `TIMEOUT` before suspecting the network.

## How the colour is decided

Packet loss outranks latency — a fast connection dropping packets is worse than a slow one that isn't.

```
unreachable (no latency parsed) ──────────────► 🔴  "down"
packet loss > 20%  ───────────────────────────► 🔴
packet loss > 0%   ───────────────────────────► 🟡
             else, by average latency:
                 > 150 ms ─────────────────────► 🔴
                 >  50 ms ─────────────────────► 🟡
                 otherwise ────────────────────► 🟢
```

Latency thresholds are only consulted when loss is exactly zero. "Unreachable" means the round-trip line was absent from `ping` output — DNS failure, no route, and a fully dropped batch all land here, and loss is reported as 100%.

## Dropdown

Everything below the separator is the detail view: target, average latency, min/max, packet loss, packet count, and the timestamp of the last run. `Refresh now` forces a run without waiting for the interval.

When the target is unreachable the latency rows are replaced by `Status: UNREACHABLE` in red, since there are no numbers to show.

## Requirements

`bash`, `ping`, `awk`, `sed`, `grep` — all present on stock macOS. No dependencies to install.

## Notes

Output parsing is tuned to macOS `ping`, which prints `round-trip min/avg/max/stddev = ...`. Linux `ping` prints `rtt min/avg/max/mdev`; the `round-trip|min/avg/max` match catches both, but the plugin is only exercised on macOS.
