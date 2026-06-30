# Networking

AE3 networking lets laptops and routers communicate. Missions can use it for ping tests, SSH chains, chat, remote laptop access, and network-gated objectives.

## Core Objects

- Router: creates a network and assigns addresses.
- Laptop: connects to a router and uses network tools.
- Parent router: can connect router networks together.

## Router Settings

Configure routers in object attributes:

- Network Name (SSID): visible network name.
- Default Gateway: optional router address.
- Wifi Range (m): connection range.
- Network Password: required password, or blank for open network.
- Powered On At Start: starts the router automatically.
- Allow External SSH: allows access from other gateways.
- External Allowed IPs: optional allow list for external routes.

For simple missions, leave Default Gateway blank and let AE3 assign addresses.

## Editor Connections

Use `AE3: connect device to network router`.

Common setups:

- One laptop to one router.
- Multiple laptops to one router.
- Router to parent router for multi-network scenarios.

## Player Workflow

When configured, players can:

- Check their network information.
- Ping another address.
- Connect to remote systems through SSH.
- Send messages.
- Use network-aware desktop apps.

## Good Network Design

- Give players a reason to know or discover an IP address.
- Avoid too many routers unless routing is part of the puzzle.
- If a password is required, make it discoverable.
- If external access is required, test it on a dedicated server.
- Keep router names and addresses readable.

Scripted network setup belongs in [Network API](../Reference/Network-API.md).
