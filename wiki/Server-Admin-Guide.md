# Server Admin Guide

Advanced Equipment is designed for multiplayer, JIP, and dedicated servers. Device state such as filesystems, users, power, network links, browser pages, history, and mail is generally stored on server-owned objects or broadcast public variables.

## Load Order

Load CBA_A3 and ACE3 before Advanced Equipment.

## Multiplayer Notes

- Mission setup scripts that change laptop content should run on the server.
- Some public APIs route client calls to the server, but server execution avoids race conditions.
- Device access is controlled through ACE interaction state, mutex locking, interface mode, and optional interface access conditions.
- Validate custom scripts on a dedicated server when they use power, network, filesystem, or remote desktop data.

## Debugging

Use AE3 debug and network debug helpers when route or device state is unclear. See [Debugging](Developer/Debugging.md).
