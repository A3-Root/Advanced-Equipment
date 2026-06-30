# Mission Maker Guide

This guide is for mission makers building AE3 gameplay in 3DEN without writing scripts. The Examples pages include separate Eden Editor, Zeus, and API sections; use the Eden and Zeus sections for no-code work, and use the API sections only when a mission framework or addon script is appropriate.

## Start With the Player Experience

Before placing modules, decide what the players should actually do.

Good AE3 scenarios usually answer these questions:

- What object do players need to find?
- Do they use a graphical desktop, a terminal, or both?
- Do they need credentials?
- Is the useful information in a file, email, browser page, history entry, media file, calendar event, or locked file?
- Does the laptop need power?
- Does the laptop need network access?
- Does a flash drive matter?
- Can Zeus add or change information during the mission?

## Choosing GUI, Terminal, or Both

Use GUI desktop when players should read and browse:

- Email inboxes.
- Browser pages.
- Browser history.
- Files and folders.
- Images, video, or audio.
- Calendar entries.
- CCTV cameras.
- Map or system information.

Use terminal when players should do command-line tasks:

- Search folders.
- Read logs.
- Use SSH.
- Check IP addresses.
- Ping devices.
- Mount USB drives.
- Unlock passworded files.
- Use installed mission-specific commands.

Use both when the laptop should feel like a full computer or when different players may prefer different workflows.

## Basic 3DEN Workflow

1. Place AE3 objects.
2. Configure object attributes by double-clicking each object.
3. Place AE3 modules for users, files, directories, intel, or special behavior.
4. Double-click each module and fill in its fields.
5. Sync each module to the laptop or target object it should affect.
6. Use AE3 connection tools for power and network links.
7. Preview the mission.
8. Test as a player, not only as the editor camera.

## Recommended Laptop Setup Order

For a reliable no-code laptop:

1. Place the laptop.
2. Set interface mode in object attributes.
3. Add a user.
4. Add folders before files that should live inside those folders.
5. Add files, webpages, emails, media, and locked files.
6. Add browser history after the webpage exists.
7. Add power and network connections.
8. Preview and verify both the player interaction and the content.

## Building Intel Chains

AE3 works best when one clue leads to the next. Examples:

- A note gives laptop credentials.
- Browser history points to a mission webpage.
- The webpage mentions an email subject.
- The email gives a network address.
- The network address leads to an SSH target.
- The remote laptop contains a locked file.
- The locked file password is found on a flash drive.

You can build that entire flow with editor objects and modules. Use the Examples pages for step-by-step recipes; each recipe labels which steps are for Eden Editor, which are for Zeus, and which are for API/script setup.

## Power as Gameplay

Power can be a simple requirement or a puzzle.

Simple setup:

- Laptop starts powered.
- Router starts powered.
- Players interact immediately.

Puzzle setup:

- Laptop starts off.
- Generator starts empty or disconnected.
- Battery has limited charge.
- Players must connect a source and turn devices on.

Use power only when it adds something to the mission. If the main objective is reading intel, do not hide it behind too many unrelated power steps.

## Network as Gameplay

Networks are useful when the mission needs multiple devices:

- A laptop in one building must reach another laptop.
- Players must discover the correct IP address.
- A router password gates access.
- External access rules allow or block cross-network SSH.
- A Zeus operator changes access live.

For basic missions, connect laptops to one router. Use multiple routers only when route discovery or network separation is part of the gameplay.

## Common Mistakes

- Placing a module but not syncing it to the laptop.
- Syncing a file module before creating the folder path it uses.
- Creating browser history for a page that was never added.
- Giving players GUI-only access, then expecting them to use terminal commands.
- Giving players terminal-only access, then putting all clues in GUI apps.
- Forgetting that dedicated servers must allow GUI/Desktop file extensions.
- Testing only in singleplayer when the mission depends on Zeus, network, power, or multiplayer locality.

## Where Scripts Belong

If you need script calls, use:

- The API section inside the relevant [Examples](Home.md#mission-recipes) recipe for a complete scenario pattern.
- [Reference](Reference/API-Overview.md) for exact public API signatures.
- [Developer](Developer/Architecture.md) for addon extension notes.

This guide intentionally avoids SQF examples so mission makers can build with 3DEN and Zeus first. The recipe and Reference pages contain the technical examples.
