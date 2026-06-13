# GUI Laptop — Mission Maker Guide

How to set up the AE3 desktop (GUI) laptop in **Zeus**, **3DEN** and **via script API**, plant
intel for players to find, protect files with passwords, and add your own apps.

The GUI laptop is the same laptop as the CLI one — same filesystem, users, power and network.
Players switch between the two interfaces; everything planted is reachable from both.

---

## 1. Setting up the laptop

### In 3DEN

1. Place an AE3 laptop (Assets ▸ AE3, e.g. *Rugged Laptop* — `Land_Laptop_03_black_F_AE3`).
   The vanilla `Land_Laptop_03_black_F` prop has **no** ArmaOS — use the AE3 variant.
2. Power: place an AE3 battery/generator and connect in game, or just rely on the internal
   battery. Network: place an AE3 router and use the *AE3 Network Connection* in 3DEN
   (Connect mode) or connect in game via ACE.
3. Double-click the laptop and pick its **Interface (CLI / GUI / Both)** attribute:
   *Default* follows the CBA setting `AE3_Desktop_DefaultMode`, *Both* gives the laptop two
   ACE actions (Use Terminal / Use Desktop). Who may use which interface is the mission
   maker's call — see **Interface access control** below. Players have no switch.
4. Plant intel with the **AE3: Add Intel** module (category AE3) — sync it to specific
   laptops, or leave it unsynced to target **all** laptops. Files can also be added with the
   classic *AddFile* / *AddDir* modules.

### In Zeus

1. Place the AE3 laptop from the AE3 assets category.
2. Set the interface mode from the Zeus debug console (players cannot switch it):
   ```sqf
   [_laptop, "both"] call AE3_desktop_fnc_setInterfaceMode; // "cli" | "gui" | "both"
   ```
3. Place the **AE3: Add Intel** module **on a laptop** to target it, or anywhere else to
   target all laptops. Pick the type — the three fields re-label themselves:

   | Type | Field 1 | Field 2 | Field 3 |
   |------|---------|---------|---------|
   | Email | From | Subject | Body |
   | Webpage | URL | Title | Content (`\|` = new line, `[[url\|label]]` = link) |
   | Browser history entry | URL | Time (HH:MM, optional) | — |
   | Calendar entry | Date (YYYY-MM-DD HH:MM) | Title | Details |
   | Media file | Source path (`\mod\file.paa`) | image / video / audio | Filesystem destination |
   | Password-protected file | Filesystem path | Password | Content |

   The other AE3 Zeus modules (Add User, Add File, Add Directory, Add Games, Add Security
   Commands) work on GUI laptops exactly as on CLI laptops.

### Interface access control (framework)

Which interfaces a laptop offers — and **who** may open each — is entirely mission-maker /
mod-developer controlled. There is intentionally no player-facing switch, so other mods can
build their own access models (keycards, hacking states, ranks) on top:

```sqf
// what the laptop offers: "cli", "gui" or "both"
[_laptop, "both"] call AE3_desktop_fnc_setInterfaceMode;

// who may use each interface - ARRAY of UIDs and/or sides ...
[_laptop, "gui", [west]] call AE3_desktop_fnc_setInterfaceAccess;
[_laptop, "cli", ["76561198000000000", east]] call AE3_desktop_fnc_setInterfaceAccess;

// ... or arbitrary CODE: [_laptop, _player] -> BOOL (evaluated live in the ACE condition)
[_laptop, "gui", { (_this select 1) getVariable ["myMod_hasKeycard", false] }] call AE3_desktop_fnc_setInterfaceAccess;

// the check other mods can call (or override per laptop via the variables directly):
//   AE3_interfaceMode, AE3_cliAccessCondition, AE3_guiAccessCondition
[_laptop, player, "gui"] call AE3_desktop_fnc_canAccessInterface; // -> BOOL
```

All of it is server-routed and JIP-safe (public object variables).

### Via script API (init.sqf, triggers, debug console — any machine, JIP-safe)

```sqf
// interface mode (see access control above)
[_laptop, "both"] call AE3_desktop_fnc_setInterfaceMode;

// plain file (also via Zeus/3DEN AddFile)
[_laptop, "/home/user/orders.txt", "Move out at dawn.", false, "root",
 [[true, true, false], [true, false, false]]] remoteExecCall ["AE3_filesystem_fnc_device_addFile", 2];

// email (Mail app + /var/mail/)         target: laptop | "all" | netId
[_laptop, "informant", "Meeting", "Safehouse C4, 0300."] call AE3_desktop_fnc_addEmail;

// webpage + a planted history trail (Browser app)
["intel.root/convoys", "Convoy Schedule",
 ["0400 - Route Red", "0600 - Route Blue", "[[intel.root/routes|Route map]]"]] call AE3_desktop_fnc_registerWebpage;
[_laptop, "intel.root/convoys", "02:47"] call AE3_desktop_fnc_addHistoryEntry;

// calendar entry (Calendar app)
[_laptop, "2035-06-24 04:00", "Convoy departs", "Route Red, 3 trucks"] call AE3_desktop_fnc_addCalendarEvent;

// media: image / video / audio (Files, Music apps; images double as wallpapers)
["\myMod\img\map_photo.paa", "image", "/home/user/photo.paa", [_laptop]] call AE3_desktop_fnc_registerMedia;
["\a3\missions_f\video\a_in.ogv", "video", "/home/user/intel.ogv", "all"] call AE3_desktop_fnc_registerMedia;

// password-protected file (see section 3)
[_laptop, "/home/user/codes.txt", "hunter2", "Launch code: 7741"] call AE3_desktop_fnc_addLockedFile;

// CCTV camera for the CCTV app
["Compound Gate", _cctvProp] call AE3_desktop_fnc_registerCamera;

// crash the laptop (blue screen until power-cycled)
[_laptop] call AE3_power_fnc_crashDevice;
```

`"all"` targets every initialized laptop; media also accepts `"future"` (current **and**
laptops spawned later). The engine cannot list files inside mods — media must be registered
with explicit paths.

---

## 2. What players can do on the GUI laptop

| App | Function |
|-----|----------|
| Terminal | the full CLI (every command incl. `ssh`, `msg`, `grep`, `sudo`, `unlock`, third-party commands) |
| Files | browse the filesystem, open text (Notepad), media, locked files |
| Notepad | open / edit / save any text file |
| Mail | read `/var/mail/`, compose and send to other laptops over the network |
| Chat | instant messages (same store as the `msg` command) |
| Browser | registered webpages, clickable links, Back, history in `/var/log/browser_history` |
| Calendar | month grid of the in-game date with plantable events |
| Map | mission map centered on the laptop |
| CCTV | registered camera feeds (local render-to-texture) |
| Music | play registered audio at the laptop |
| System Monitor | battery, power, IP, gateway, USB, uptime |
| Settings | theme, wallpaper, switch back to CLI |

While someone uses the desktop, other players see a static lock screen on the laptop texture
(intentional: zero GUI network traffic). The laptop is locked (mutex) — one user at a time,
including over SSH.

---

## 3. Password-protected files

Format on disk: `AE3_LOCKED|<password>|<content>` — you can also create these with the plain
AddFile Zeus/3DEN module by typing that format directly. The password must not contain `|`;
the content may be anything, including a media marker (`AE3_MEDIA|image|\mod\img.paa`) for a
password-protected photo.

- **CLI:** `cat` shows *password protected*; `unlock /home/user/codes.txt hunter2` prints the
  content; `unlock -p ...` permanently removes the protection (needs write permission).
- **GUI:** opening the file in Files pops up a password prompt; the correct password opens
  the content with the normal viewer (text or media).
- Wrong attempts (CLI and GUI) are logged to `/var/log/auth.log` — itself readable intel.

```sqf
[_laptop, "/home/user/codes.txt", "hunter2", "Launch code: 7741"] call AE3_desktop_fnc_addLockedFile;
```

---

## 4. Session persistence

The laptop keeps the state the previous user left it in:

- **GUI:** open windows, their positions, the Files path, the Browser URL, the Calendar
  month and **unsaved Notepad text** are stored on the laptop (synced) when the desktop
  closes and restored for the next user — even on a different client.
- **CLI:** the terminal buffer, login, prompt and history are persisted via the existing
  `AE3_terminal_sync` mechanism; `/var/log/browser_history`, `/var/mail` and all files live
  in the server-side filesystem anyway.
- Picking the laptop up into the inventory and redeploying it also preserves the filesystem.

This makes "find the laptop the enemy officer was just using" scenarios work: the desktop
opens with his mail, his browser tab and his half-written note still on screen.

---

## 5. Creating your own app

Config (addon) or runtime (mission) registration — see `App-Framework.md` for the full API.

```sqf
// initPlayerLocal.sqf - runtime registration (local effect, register on every client)
["myMission_uplink", "Uplink", "myMission_fnc_uplinkApp", [0.5, 0.5]] call AE3_desktop_fnc_registerApp;

// the app entry
myMission_fnc_uplinkApp = {
    params ["_winId", "_ctrlGroup", "_computer", "_args"];
    private _display = ctrlParent _ctrlGroup;

    private _btn = _display ctrlCreate ["RscButton", -1, _ctrlGroup];
    _btn ctrlSetPosition [0.01, 0.05, 0.3, 0.05];
    _btn ctrlSetText "Transmit intel";
    _btn ctrlCommit 0;
    _btn ctrlAddEventHandler ["ButtonClick", { ["myMission_intelSent", []] call CBA_fnc_serverEvent; }];

    // optional callbacks: onClose, getState (session persistence)
    createHashMap
};
```

Apps can persist their own state across users by returning a `getState` callback and reading
it back from `_args` (see `fnc_app_files.sqf` for the pattern).

---

## 6. Relevant CBA settings

| Setting | Effect |
|---------|--------|
| `AE3_Desktop_DefaultMode` | CLI or GUI for laptops without per-laptop override |
| `AE3_Desktop_DefaultTheme` | default theme (Dark / Light / Olive) |
| `AE3_Desktop_EnableDragDrop` | allow window dragging |
| `AE3_Desktop_EnableFileBrowsing` | allow the Files app |
| `AE3_AllowRootLogin` | allow direct root login (default off — use sudo) |
| `AE3_EnableErrorSound` | error beep on failed commands |
| `AE3_TransferSpeedLocal/Usb/Network` | simulated copy speeds (0 = instant) |
| `AE3_UiKeystrokeSyncInterval` etc. | CLI screen-texture sync tuning |
