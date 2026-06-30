# Add Users and Passwords

This recipe adds login credentials to AE3 laptops. It includes Eden Editor, Zeus, and API workflows.

Users matter for both interfaces:

- Terminal/TUI requires a login before shell access.
- Desktop GUI uses the logged-in user to decide home folder, Desktop launchers, and readable content.

## Design the Credentials First

Before placing modules or writing scripts, decide:

| Question | Example answer |
| --- | --- |
| Who should log in? | `admin`, `guest`, `operator`, `analyst`, a character name. |
| Where do players learn the password? | Briefing, paper note, email, another laptop, browser page, Zeus roleplay. |
| What should the user see after login? | Files, browser pages, mail, media, terminal commands. |
| Should there be multiple users? | Guest sees decoys; admin sees the real clue. |

Avoid pure password guessing. If players need credentials, the mission should provide a discoverable clue.

## Eden Editor Workflow

Use this before mission start.

1. Place an AE3 laptop.
2. Place the `AE3: Add User` module.
3. Double-click the module.
4. Set `Username`, for example `admin`.
5. Set `Password`, for example `swordfish`.
6. Sync the module to the target laptop.
7. If the user needs files, place/sync file, email, webpage, or media modules after planning the user's home path.
8. Preview the mission.
9. Open the laptop and test the username/password.

When the user is added, AE3 creates `/home/<username>` for non-root users and seeds the user's Desktop with app launchers where applicable.

## Zeus Workflow

Use this during a live mission.

1. Open Zeus.
2. Place the `AE3: Add User` module.
3. Enter the username and password in the curator dialog.
4. Place the module on, or sync it to, the target laptop depending on the dialog workflow.
5. Confirm/apply the module.
6. Tell players how they learn the credential in-world.

Live-use examples:

- Zeus adds a temporary `guest` account after players capture a technician.
- Zeus adds an `admin` account after players find a password in a document.
- Zeus adds a decoy user on a second laptop to redirect players.

## API Workflow

Run user setup on the server.

```sqf
if (isServer) then {
    [_laptop, "admin", "swordfish"] call AE3_armaos_fnc_computer_addUser;
    [_laptop, "guest", "guest"] call AE3_armaos_fnc_computer_addUser;
};
```

Add user and create a file in that user's home:

```sqf
if (isServer) then {
    [_laptop, "operator", "relay-17"] call AE3_armaos_fnc_computer_addUser;

    private _fs = _laptop getVariable "AE3_filesystem";
    [[], _fs, "/home/operator/Desktop", "root", "operator"] call AE3_filesystem_fnc_ensureDir;
    [[], _fs, "/home/operator/Desktop/brief.txt", "Relay code is 52.7.", "root", "operator"] call AE3_filesystem_fnc_ensureFile;
    _laptop setVariable ["AE3_filesystem", _fs, true];
};
```

## Multi-User Example

Use multiple accounts when you want different layers of access.

```sqf
if (isServer) then {
    [_laptop, "guest", "guest"] call AE3_armaos_fnc_computer_addUser;
    [_laptop, "admin", "orchard"] call AE3_armaos_fnc_computer_addUser;

    private _fs = _laptop getVariable "AE3_filesystem";
    [[], _fs, "/home/guest/Desktop/readme.txt", "Nothing useful here.", "root", "guest"] call AE3_filesystem_fnc_ensureFile;
    [[], _fs, "/home/admin/Desktop/orders.txt", "Move convoy at 0415.", "root", "admin"] call AE3_filesystem_fnc_ensureFile;
    _laptop setVariable ["AE3_filesystem", _fs, true];
};
```

## Testing

1. Preview as the intended player side.
2. Open the laptop interface.
3. Log in with each account.
4. Confirm wrong passwords fail.
5. Confirm the user can see the intended files/apps.
6. Confirm other users cannot read protected content if permissions are meant to block them.

## Common Mistakes

| Problem | Fix |
| --- | --- |
| User module was placed but login fails | Make sure the module is synced/applied to the laptop. |
| User exists but home files are missing | Add files under `/home/<username>` after the user exists. |
| Players never find the password | Add a clue in briefing, email, browser page, file, or Zeus roleplay. |
| GUI Desktop looks empty | Ensure the user home/Desktop was seeded and the interface is GUI or Both. |
| API call from client does nothing | `computer_addUser` is server-only. Run it on server. |

## Related Pages

- [ArmaOS API](../Reference/ArmaOS-API.md)
- [Filesystem API](../Reference/Filesystem-API.md)
- [Player Guide](../Player-Guide.md)
