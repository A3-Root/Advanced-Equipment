# Filesystem

Every AE3 laptop has a virtual filesystem, stored as nested hashmaps on the laptop object (`AE3_filesystem`). It holds folders, files, logs, browser history, mail data, media markers, mounted flash drives, and command files — the GUI and terminal both read and write the same underlying structure.

## Player View

Players can access the filesystem through:

- GUI Files app.
- Terminal commands (`ls`, `cd`, `cat`, `mkdir`, `touch`, `rm`, `mv`, `cp`, `find`, `grep`).
- Desktop apps that read files, such as Browser or Mail.

If a mission maker adds a text file, players may be able to open it in Files or read it in the terminal depending on which interface the laptop offers (see [Laptops and Interfaces](Laptops-and-Interfaces.md)).

## Common Folders

Typical paths, matching Unix convention so terminal-savvy players feel at home:

| Path | Contents |
| --- | --- |
| `/home/<user>` | Per-user home folder. |
| `/var/log` | Logs such as `browser_history` and `auth.log` (failed `unlock` attempts). |
| `/tmp` | Temporary files. |
| `/mnt/<interface>` | Mounted flash drives (see [Flash Drives](Flash-Drives.md)). |
| `/bin`, `/sbin` | Terminal command locations. |
| `/root` | Root/admin area. |

Mission makers can use any clear path, but keep paths readable for players — `/home/admin/payroll_q3.txt` communicates more than `/tmp/f1.txt`.

## Permissions

Files and folders have an owner and permissions. In editor modules, permissions are exposed as owner/everyone checkboxes for read, write, and execute.

Simple mission guidance:

- For a normal clue, allow owner read and everyone read.
- For private content, restrict everyone read — pair it with a `sudo` password or a reason the player's character has access.
- For folders, execute permission usually controls whether players can enter/traverse the folder.
- Do not overuse permissions unless permissions are part of the puzzle; a folder players can't enter is a dead end unless that's the point.

## Symlinks and Locked Content

- Symlinks use a sentinel string prefix (`AE3_SYMLINK|`) internally; you don't need to know the format to use `AE3: Add Directory`/`AE3: Add File`, but it matters if you're reading raw filesystem content from script.
- Locked (passworded) files use the `AE3_LOCKED|` sentinel format — see [Encryption and Security](Encryption-and-Security.md).
- Both ride through the normal `[content, owner, perms]` triple, so network sync is unaffected.

## No-Code Setup

Use `AE3: Add Directory` before adding files inside a new folder. Use `AE3: Add File` to create readable documents. Sync each module to the target laptop.

If a file does not appear, check:

- Is the module synced to the laptop?
- Does the parent folder path exist (create it with `AE3: Add Directory` first)?
- Is the file path typed correctly (case, leading slash, trailing slash)?
- Does the player have permission to read it?

## Related Pages

- [Filesystem API](../Reference/Filesystem-API.md) — direct filesystem function calls (`getFile`, `writeToFile`, `createFile`, permissions helpers).
- [Add Files and Folders](../Examples/Add-Files-and-Folders.md) — step-by-step tutorial.
- [Flash Drives](Flash-Drives.md) — a separate `AE3_filesystem` mounted into the laptop's.
