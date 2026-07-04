# Encryption and Security

AE3 includes security-style gameplay through user accounts, file permissions, passworded files, optional security commands, and locked-file cracking/logging.

## User Accounts

User accounts control login credentials and home folders. Use accounts when players should need a username and password to access a laptop. Add users with the `AE3: Add User` module (Username, Password) or `AE3_armaos_fnc_computer_addUser` from script.

## File Permissions

Permissions control who can read, write, or execute files and folders. In editor modules, permissions are shown as owner and everyone checkboxes for read/write/execute.

Use permissions sparingly for player-facing missions. If players cannot read an important clue, make sure they have a way to learn the right credentials (`sudo`, a discoverable password, or a route around the restriction).

## Passworded / Locked Files

Locked files require a password before players can see the protected content. Add them with the `AE3: Add Passworded File` module (Path, Password, Protected Content, Owner, Permissions) or the filesystem/desktop API. Internally the content is stored as a single string:

```text
AE3_LOCKED|<passwordLength>|<password><payload>
```

Players open it with the terminal `unlock` command:

```text
unlock /home/admin/secret.txt hunter2
unlock -p /home/admin/secret.txt hunter2
```

`-p` permanently unlocks the file (rewrites it as plain text) if the player has write permission — useful when you want the file to "stay open" for the rest of the mission after it's solved once. Wrong passwords are written to `/var/log/auth.log` and play an error sound, so a laptop with a locked file can also give you a free "who tried to break in" clue trail.

Good passworded-file design:

- Put the password somewhere discoverable (a note, an email, a browser page, another laptop).
- Avoid random guessing — a password should be findable, not brute-forceable by the player.
- Make the locked file name meaningful (`payroll_q3.txt`, not `file2.txt`).
- Give players a reason to know it is worth opening before they find the password.

## Pre-Encrypted Files (Distinct From Locked Files)

`AE3: Add File` has separate encryption options (algorithm + key) that are **not** the same system as locked files:

| | Locked file | Pre-encrypted file |
| --- | --- | --- |
| Module | `AE3: Add Passworded File` | `AE3: Add File` with encryption options |
| What's stored | Plaintext + password, gated | Actual ciphertext, no password gate |
| How players open it | Terminal `unlock <path> <password>` prompt | Read the ciphertext directly (`cat`), then run `crypto -m decrypt` themselves |
| Failure mode | Wrong password logged to `/var/log/auth.log` | No prompt to "fail" — the file just reads as gibberish until decrypted |

Use a locked file when the interesting step is *finding the password*. Use a pre-encrypted file when the interesting step is *breaking or applying a cipher* — it composes naturally with the `crypto`/`crack` puzzles below, since the file itself can be exactly what a `crack` command targets. See [Filesystem API](../Reference/Filesystem-API.md#device-level-content-helpers) for the scripted call (`AE3_filesystem_fnc_device_addFile` with `_isEncrypted`).

## Security Commands

Laptops can optionally install `crypto` and `crack`, enabled per-laptop via the laptop's Crypto/Crack object attributes, or from script:

```sqf
[_laptop, true, true] call AE3_armaos_fnc_computer_addSecurityCommands;
```

These are not installed by default — a laptop with no security commands enabled will not show them in `help`, even if the mission narrative implies the character should have them.

If the mission expects players to use a security command, make sure:

- The laptop exposes terminal access (Interface Mode `cli` or `both`).
- The command is actually installed on that laptop.
- Players can discover the command through `help`, `man`, notes, or in-mission training.

## Cipher Puzzles (`crypto` / `crack`)

`crypto` encrypts/decrypts text with a key; `crack` tries to break it without one. Two algorithms are available, and they make very different puzzles:

- **Caesar** (letter shift) — easy to crack. `crack -m statistics` does frequency analysis and will usually guess the shift outright on real English text. Use this when you want players to succeed with the *tool*, not by solving the cipher manually — the interesting part of the puzzle should be finding the encrypted message, not the cryptanalysis.
- **Columnar** (transposition) — `crack` can only narrow down candidate key *lengths* (`-m key`) and dump the column/row grid for each candidate (`-m bruteforce`); it cannot recover the key string. Use this when you want players to actually work out the message by eye from the grid layout, or when the key itself should come from elsewhere in the mission (a note, a call sign, a serial number).

Worked example — a caesar puzzle a player can fully solve with tools alone:

1. Precompute the ciphertext yourself (or in a scratch terminal): `crypto -m encrypt -a caesar -k 3 "RENDEZVOUS AT PIER 4 0300"`.
2. Put the ciphertext in a file or webpage: `PHQGHCYRXV DW SLHU 4 0300`.
3. Player runs `crack -m statistics -a caesar "PHQGHCYRXV DW SLHU 4 0300"` and gets a probable key, or `crack -m bruteforce -a caesar "..."` and reads all 26 shifts to spot the English one.
4. Player confirms with `crypto -m decrypt -a caesar -k <key> "..."`.

Worked example — a columnar puzzle that needs an external key:

1. Encrypt with a key tied to mission fiction, e.g. the callsign `RAVEN`: `crypto -m encrypt -a columnar -k RAVEN "MEET_AT_THE_OLD_MILL_AT_NOON"`.
2. Put the ciphertext on the laptop; put `RAVEN` somewhere else discoverable (a radio log, another laptop, a dead drop note).
3. Player runs `crypto -m decrypt -a columnar -k RAVEN "<ciphertext>"` once they have both pieces.
4. Without the key, `crack -m key -a columnar "<ciphertext>"` only tells them possible key lengths — not enough to solve it, which is the point.

## Related Pages

- [ArmaOS API](../Reference/ArmaOS-API.md) and [Terminal Commands](../Reference/Terminal-Commands.md) — `unlock`, `crypto`, `crack`, `sudo`, `/var/log/auth.log`.
- [Filesystem](Filesystem.md) / [Filesystem API](../Reference/Filesystem-API.md) — permissions model.
