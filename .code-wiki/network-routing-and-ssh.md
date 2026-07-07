---
topic: network-routing-and-ssh
status: verified
last-verified: 2026-06-30
confidence_score: 1.0
priority: core
rank: 3
tokens: ~850
code-paths:
  - addons/network/
  - addons/armaos/functions/fnc_os_ssh.sqf
  - addons/desktop/functions/fnc_sshOpServer.sqf
related-topics: [armaos-terminal, desktop-gui-and-browser, power-model, eden-zeus-tooling, multiplayer-locality-and-sync]
related-docs:
  - wiki/Systems/Networking.md
  - wiki/Reference/Network-API.md
---

# Network Routing And SSH

## overview

The network component manages routers, laptop/router network connections, DHCP/static addressing, wireless range and passwords, route resolution, ping, and the routing policy used by CLI and desktop SSH.

## current behavior

- Routers are initialized with gateway addresses, wireless range/password state, parent/child links, DHCP address tracking, and a global router registry in `AE3_network_routers`.
- Any router initialized with the default gateway address and no valid preset can receive the next sequential `/24` gateway: `192.168.0.1`, `192.168.1.1`, and so on. The code explicitly applies this to cascaded child routers too.
- Laptops connect to routers through Eden connections, Zeus object attributes, ACE interactions, desktop network app commands, or network API calls.
- `AE3_network_fnc_resolve` maps a target IP to the owning router by subnet, then calls `AE3_network_fnc_ping` from that router to find the device.
- Same-subnet targets still require the target device to enable SSH, similar to the router `AE3_network_allowExternalSsh` policy used for external access. Cross-gateway reachability depends on the target router's `AE3_network_allowExternalSsh` and optional `AE3_network_externalAllow` allow list.
- External allow-list entries can be gateway IPs, host IPs, or regex patterns matched against the source IP or source gateway prefix.
- CLI SSH is handled by terminal commands and changes the shell's execution target. Desktop SSH uses web commands, server-side operations, and asynchronous browser replies.
- Network debug output is controlled by global debug mode or `AE3_NetworkDebugEnabled`.

## decisions

- Cross-gateway routing uses a global router registry instead of requiring physical router-to-router links. This lets scenario authors model separated subnets while still allowing controlled intel/SSH routes.
- Router external access is enforced on the destination router, so the owner of the protected subnet decides whether external laptops may reach it.
- Desktop SSH runs sensitive operations on the server, keeping remote filesystem and user auth authoritative instead of trusting browser/client state.
- Wireless range and passwords are router object variables rather than global settings, allowing missions to mix open/locked networks with different ranges.

## gotchas

- `AE3_network_externalAllow` accepts regex, so invalid patterns are caught and ignored per entry.
- The global router registry can contain dead/null routers; lookup code skips them, but future registry iteration must do the same.
- `resolve` only gets callers to the target router. `ping` can still return `objNull` when the target device is dead or powered off.
- Desktop SSH payloads avoid HashMaps across network events; operation arguments are serialized as arrays/plain strings.
- A preset static IP/gateway must be a four-number array to be honored by router init.

## static IP is subnet-gated per gateway

When a device joins a router (`fnc_connect_device2router`) or a router refreshes leases (`fnc_dhcp_refresh`), the static address is resolved in order: per-router lease (`AE3_network_staticIpByRouter`, keyed by `netId` of the router — trusted as-is) → the 3DEN default `AE3_network_staticIpDefault`. The default is only honored when it sits in the **new gateway's /24** (`AE3_network_fnc_ipInSubnet`, compares first 3 octets against `_parent`/`_entity`'s own `AE3_network_address`); otherwise the device drops to a DHCP lease. This stops a static from a previous network carrying across when switching WiFi. `fnc_ipInUse` only checks duplicates, not subnet, so the subnet gate is what prevents out-of-subnet statics.

## re-verify when

- Router initialization, DHCP, static IP, route resolution, ping, SSH, or Zeus/Eden network connection behavior changes.
- New network policy variables or CBA settings are added.

## references

- `addons/network/functions/fnc_initRouter.sqf`
- `addons/network/functions/fnc_resolve.sqf`
- `addons/network/functions/fnc_ping.sqf`
- `addons/network/functions/fnc_createNetworkConnection.sqf`
- `addons/armaos/functions/fnc_os_ssh.sqf`
- `addons/desktop/functions/fnc_sshOpServer.sqf`

