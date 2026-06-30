# Laptops and Interfaces

AE3 laptops are the main interactive computer objects. They can be carried or loaded when allowed, opened or closed, powered on or off, connected to routers, connected to power sources, and filled with mission content.

## Interface Modes

A laptop can offer one of these access modes:

- Default: uses the mission or server default.
- CLI: terminal command-line interface only.
- GUI: graphical desktop interface only.
- Both: players can choose between terminal and desktop actions.

Set this in the laptop's 3DEN object attributes. Zeus can also manage interface access during live play when the relevant module is available.

## GUI Desktop

The GUI desktop is best for readable, visual, and app-based gameplay:

- Browsing folders.
- Reading mail.
- Opening webpages.
- Inspecting browser history.
- Reading notes.
- Viewing images, audio, video, maps, CCTV, calendar entries, and system information.

Use GUI when players should interact like they are using a normal computer.

## Terminal

The terminal is best for command-line gameplay:

- Checking folders and logs.
- Discovering network addresses.
- Connecting through SSH.
- Mounting flash drives.
- Unlocking files.
- Using security or mission-specific commands.

Use terminal when the mission should feel like a technical investigation or hacking task.

## Access Restrictions

GUI and terminal access can be restricted separately. This lets a mission maker allow one group to use the desktop while another group can use the terminal, or require a player-specific condition set by Zeus or mission logic.

For no-code setup, use laptop attributes and Zeus interface tools. For scripted or addon-controlled access, use the Desktop API reference.

## Typical Laptop Build

1. Place a laptop.
2. Choose its interface mode.
3. Add at least one user.
4. Add the content players need.
5. Decide whether it needs power.
6. Decide whether it needs network access.
7. Test the laptop as a normal player.
