# Networking: SSH and Messaging

## ssh

Open a remote shell on another AE3 computer over the simulated network:

```
ssh USER@192.168.0.5 PASSWORD
```

- The route is validated over the AE3 network (router/connection topology, power states).
- Credentials are checked against the target's user list. Root login over ssh follows the
  `AE3_AllowRootLogin` CBA setting (default: disabled - use a normal user + `sudo`).
- While connected, every entered command runs on the **remote** computer's filesystem and
  the output appears in the local terminal. The prompt shows `user@remote-host:path`.
- The remote computer is locked (same mutex as physical terminal access) for the duration.
- `exit` ends the session; closing the terminal or a remote `shutdown` also ends it.
- Interactive/graphical programs (games) are blocked over ssh (`sshCompatible = 0`).

## msg

Send an instant message to another computer:

```
msg 192.168.0.5 meet at the safehouse
```

- Delivered over the simulated network (route is validated with the same logic as ping).
- Stored in the target's `/var/mail/inbox` - read with `cat /var/mail/inbox`.
- If someone is using the target terminal, they get a live notification line.

## sudo and /etc/sudoers

Direct root login is disabled by default (`AE3_AllowRootLogin`). To run privileged
commands, add users to `/etc/sudoers` (one username per line, root-writable file) and use:

```
sudo cat /var/log/auth.log
```

All sudo usage (and denials) is logged to `/var/log/auth.log`.

## Other shell additions

- `ip` / `ifconfig` - replaces the windows-style `ipconfig`; `ip r` also shows the gateway.
- `grep [-i] [-v] PATTERN FILE...` - regex search in file contents.
- Quoted arguments are supported everywhere: `cd "my dir"`, `echo 'hello world'`.
- File copies (`cp`) simulate transfer time based on file size and medium
  (CBA settings: `AE3_TransferSpeedLocal` / `Usb` / `Network`; 0 disables).
- A configurable error sound plays on command errors (`AE3_EnableErrorSound`).
- Computers can be crashed via `AE3_power_fnc_crashDevice` (script/mission API): the
  machine shows a blue screen and is unusable until turned off and on again.
