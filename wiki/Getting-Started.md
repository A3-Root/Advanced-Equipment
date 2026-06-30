# Getting Started

This page is for mission makers who want to place AE3 equipment in the editor without writing scripts.

## What AE3 Adds to a Mission

AE3 equipment is meant to be used by players during play. A laptop can be a simple prop, a terminal puzzle, a full desktop computer, a file repository, a browser clue, a mail inbox, a network target, or an object that must be powered and connected before it works.

The usual building blocks are:

- Laptop: the computer players interact with.
- Router: gives laptops a network to connect to.
- Generator, battery, or solar panel: provides power.
- Flash drive: portable storage that players can connect and mount.
- Files, webpages, mail, media, calendar events, and locked files: the information players discover.
- Zeus and 3DEN modules: no-code tools for adding users, files, intel, and device behavior.

## First Simple Laptop

1. Open 3DEN Editor.
2. Place an AE3 laptop from the AE3 asset category.
3. Double-click the laptop to open its object attributes.
4. Set the laptop's interface mode:
   - `CLI` for terminal only.
   - `GUI` for graphical desktop only.
   - `Both` for both access actions.
   - `Default` to use the mission/server default.
5. Place an `AE3: Add User` module.
6. Double-click the module and enter a username and password.
7. Sync the module to the laptop.
8. Preview the mission.
9. Interact with the laptop through ACE.

If the laptop is powered off at mission start, turn it on through ACE or set its initial power state in the object attributes.

## First Intel Laptop

To make the laptop contain useful information:

1. Place a laptop.
2. Add a user with `AE3: Add User`.
3. Add a folder with `AE3: Add Directory`.
4. Add a readable text file with `AE3: Add File`.
5. Add a webpage with `AE3: Add Webpage`.
6. Add a browser history entry with `AE3: Add Browser History`.
7. Sync every module to the same laptop.

Players can then find the information through the GUI Files and Browser apps, or through terminal commands if the laptop exposes CLI access.

## First Networked Laptop

1. Place a laptop.
2. Place an AE3 router.
3. Double-click the router and set its SSID, password, range, and powered-on state.
4. Use the 3DEN connection tool `AE3: connect device to network router`.
5. Drag the connection from the laptop to the router.
6. Preview and use the laptop's network tools.

For two laptops on the same network, connect both laptops to the same router.

## First Powered Setup

1. Place a laptop.
2. Place a generator, battery, or solar panel.
3. Double-click the power source and set its fuel or battery level if the object has that attribute.
4. Use the 3DEN connection tool `AE3: connect device to power source`.
5. Drag the connection from the laptop to the power source.
6. Preview and turn on the source and laptop through ACE if they are not already running.

## Where to Go Next

- Use [Eden Editor Guide](Eden-Editor-Guide.md) for detailed module and sync instructions.
- Use [Mission Maker Guide](Mission-Maker-Guide.md) for scenario planning.
- Use [Player Guide](Player-Guide.md) to understand what players will experience.
- Use Reference pages only when you need script or addon API calls.
