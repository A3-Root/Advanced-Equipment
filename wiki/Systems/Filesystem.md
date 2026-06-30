# Filesystem

Every AE3 laptop has a virtual filesystem. It stores folders, files, logs, browser history, mail data, media markers, mounted flash drives, and command files.

## Player View

Players can access the filesystem through:

- GUI Files app.
- Terminal commands.
- Desktop apps that read files, such as Browser or Mail.

The same files are shared between GUI and terminal. If a mission maker adds a text file, players may be able to open it in Files or read it in the terminal depending on laptop access.

## Common Folders

Typical paths include:

- `/home`: user folders.
- `/home/admin`: a likely admin user folder.
- `/var/log`: logs such as browser history.
- `/tmp`: temporary files.
- `/mnt`: mounted flash drives.
- `/bin` and `/sbin`: terminal command locations.
- `/root`: root/admin area.

Mission makers can use any clear path, but should keep paths readable for players.

## Permissions

Files and folders can have owners and permissions. In editor modules, permissions are exposed as checkboxes for owner and everyone.

Simple mission guidance:

- For a normal clue, allow owner read and everyone read.
- For private content, restrict everyone read.
- For folders, execute permission usually means players can enter or traverse the folder.
- Do not overuse permissions unless permissions are part of the puzzle.

## No-Code Setup

Use `AE3: Add Directory` before adding files inside a new folder. Use `AE3: Add File` to create readable documents. Sync each module to the target laptop.

If a file does not appear, check:

- Is the module synced?
- Does the folder path exist?
- Is the file path typed correctly?
- Does the player have permission to read it?

Direct filesystem function calls belong in [Filesystem API](../Reference/Filesystem-API.md).
