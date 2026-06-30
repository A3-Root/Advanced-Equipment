# Architecture

AE3 is split into addon components under `addons/`.

- `main`: shared helpers, Zeus modules, debug helpers, editor connection handlers.
- `armaos`: TUI terminal, shell, users, commands, encryption, games, laptop state.
- `desktop`: GUI desktop, apps, web bridge, browser, mail, chat, media, intel, interface access.
- `filesystem`: virtual filesystem and permissions.
- `flashdrive`: inventory/world flash drives, USB interfaces, mounts.
- `interaction`: ACE interactions, equipment open/close/animate behavior, lights.
- `network`: routers, DHCP, IPs, routing, ping, SSH/message support.
- `power`: generators, batteries, solar panels, consumers, power states, connections.

Most systems store state on objects with `setVariable`. Shared mission registries use `missionNamespace`. Server ownership is preferred for persistent state and multiplayer correctness.
