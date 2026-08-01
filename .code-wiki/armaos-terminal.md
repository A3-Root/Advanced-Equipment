---
topic: armaos-terminal
status: verified
last-verified: 2026-07-08
confidence_score: 1.0
priority: core
rank: 5
tokens: ~590
code-paths:
  - addons/armaos/
  - addons/armaos/functions/fnc_os_*.sqf
  - addons/armaos/functions/fnc_shell_*.sqf
  - addons/armaos/functions/fnc_terminal_*.sqf
related-topics: [desktop-gui-and-browser, filesystem-model, network-routing-and-ssh, flashdrive-usb, interaction-equipment, multiplayer-locality-and-sync]
related-docs:
  - wiki/Systems/Terminal-TUI.md
  - wiki/Reference/Terminal-API.md
---

# ArmaOS Terminal

## overview

The ArmaOS component owns the terminal/TUI interface, command shell, laptop state capture/restore, user authentication, bundled commands, security commands, games, and UI-on-texture terminal mirroring.

## current behavior

- Built-in shell commands are prepared through `addons/armaos/XEH_PREP.hpp` and implemented as `fnc_os_*.sqf` files.
- `AE3_armaos_fnc_shell_process` tokenizes a user command, resolves the command name through the execution computer's `AE3_Links` hashmap, executes the resolved file, then restores the shell prompt. During SSH, command lookup switches to `_sshTarget` and uses that object's links.
- SSH changes the execution target: most output still appears on the local terminal, but command files and filesystem state are read from the remote laptop stored in `AE3_terminal` under `AE3_sshTarget`.
- Commands can be installed without config through `AE3_armaos_fnc_computer_addCustomCommand`, which creates a command file in the virtual filesystem and adds a shell link.
- Login and password validation use the laptop's `AE3_Userlist`. Every device init seeds a `root` account (password from the object var `AE3_rootPassword`, else the CBA setting `AE3_DefaultRootPassword`, default `toor`). Direct root login is resolved per laptop by `AE3_armaos_fnc_computer_allowsRootLogin`: object var `AE3_allowRootLogin` (`"allow"`/`"deny"`) wins, otherwise the global CBA setting `AE3_AllowRootLogin`. Terminal login, `ssh` and the desktop login all call it.
- Superuser rights outside root come from `/etc/sudoers`, read through `AE3_armaos_fnc_computer_getSudoers` / `computer_isSudoer` and managed with the server-side `computer_addSudoer` / `computer_removeSudoer` (both ensure device init, create the file, dedupe, broadcast). `sudo` and the desktop file/volume handlers share that one check.
- Terminal display preferences are CBA settings, including keyboard layout, terminal design, scroll speed, default size, UI-on-texture toggles, and UI-on-texture update intervals.
- Session-local UI state is kept in `AE3_terminal`; the persisted handoff is the compact `AE3_terminal_sync` array, which is saved on unload and restored on the next open.
- CLI file commands use the same virtual filesystem functions as the desktop Files/Notepad apps, so permissions and owner checks should match between TUI and GUI paths.
- The laptop power functions in this component call into the power component wrappers to turn on, turn off, and stand by devices.

## decisions

- The shell uses filesystem-backed command links instead of hard-coding every command in the parser, letting mission scripts and other addons add commands that behave like native commands.
- SSH reuses the local terminal display while swapping the execution computer, keeping one UI session instead of opening a second remote dialog in multiplayer.
- The durable terminal handoff is `AE3_terminal_sync`, not the full session-local `AE3_terminal` hashmap. This supports closing/reopening the interface without treating each client session object as persisted state.
- Direct root login is per laptop with a CBA fallback: missions want one global switch, but individual laptops (an admin box vs. a captured field laptop) need to differ, so the object variable overrides the setting rather than replacing it.
- Sudoers membership is stored in the filesystem file itself, not in a separate object variable, so it stays discoverable and editable in-fiction; the API exists because a hand-written `writeToFile` before device init silently does nothing.

## gotchas

- The laptop lock (`AE3_computer_mutex`) is released by the terminal display's `Unload` handler, which `fnc_terminal_init` now wires up **before** its suspending `getRemoteVar` fetches (not late via `fnc_terminal_addEventHandler`). This is what stops an early close (before startup finishes) from orphaning the mutex and bricking every mutex-gated laptop ACE action. `fnc_terminal_init` also bails (`isNull _consoleDialog`) after the fetches if the display was closed meanwhile.
- `fnc_terminal_onUnload` must stay null-safe for a partial init (terminal HashMap / per-frame handles may be absent) and only releases the mutex/`inUse` when NOT hosted inside a desktop session (`_inDesktop`); when inside the native desktop, the desktop owns the lock and cleans up on its own unload, so `fnc_app_terminal` no longer re-claims the mutex.
- Commands that are graphical or interactive must be marked SSH-compatible before they can run over SSH.
- `fnc_os_sudo` elevates by writing `AE3_terminalLoginUser` to `root` and restoring it after the call; a command that suspends can widen that window.
- The terminal command runner assumes the execution computer has populated `AE3_terminal`, `AE3_filesystem`, and `AE3_Links` state.
- `AE3_main_fnc_getRemoteVar` can suspend, so functions that call it must run in a scheduled context or deliberately spawn.
- Several terminal helper headers still contain placeholder argument descriptions.

## re-verify when

- A command file, shell parser, terminal UI function, login/auth function, or `CfgOsFunctions` entry changes.
- A new UI mode or SSH behavior is added.
- CBA settings in `addons/armaos/XEH_preInit.sqf` change.

## references

- `addons/armaos/functions/fnc_shell_process.sqf`
- `addons/armaos/functions/fnc_computer_addCustomCommand.sqf`
- `addons/armaos/functions/fnc_terminal_init.sqf`
- `addons/armaos/functions/fnc_terminal_onUnload.sqf`
- `addons/armaos/XEH_preInit.sqf`

