# Debugging

## HEMTT

Final validation should run:

```sh
hemtt check -p -Lc14 -e
```

## Runtime Checks

- Confirm the laptop has power before testing GUI/TUI.
- Confirm interface mode: `cli`, `gui`, or `both`.
- Confirm access condition allows the current player.
- Confirm user credentials exist on the target laptop.
- Confirm network links and router power before testing `ping`, `ssh`, or `msg`.
- Confirm mounted flash drives appear under `/mnt/<interface>`.
- Confirm browser history exists at `/var/log/browser_history`.

## Network Debugging

Network route functions log more detail when AE3/network debug mode is enabled. Use ping and resolve checks to isolate power-off routers, blocked external routing, bad IPs, or disconnected devices.
