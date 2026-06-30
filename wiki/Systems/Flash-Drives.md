# Flash Drives

Flash drives are portable storage. They can be carried by players, connected to laptop USB ports, mounted, read, unmounted, and disconnected.

## Player Flow

1. Find or receive a flash drive.
2. Connect it to a laptop through ACE interaction.
3. Use terminal USB commands to detect and mount it.
4. Open the mounted files through terminal or GUI Files app.
5. Unmount the drive when finished.
6. Disconnect it if the mission requires moving it elsewhere.

## Mission-Maker Setup

Use flash drives when:

- A clue must be physically transported.
- Players must choose which laptop to inspect it on.
- A password or key file should be separated from the main laptop.
- The mission wants evidence transfer or courier gameplay.

## Mount Paths

Mounted drives usually appear under `/mnt/<interface>`, such as a USB interface folder. Players can browse that location after mounting.

## Common Problems

- Drive connected but files are missing: check whether it is mounted.
- Cannot mount: check the USB interface and laptop state.
- Cannot read files: check file permissions or required credentials.
- Drive disconnected too early: reconnect and mount again if needed.

Script flash drive calls belong in [Flashdrive API](../Reference/Flashdrive-API.md).
