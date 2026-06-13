# GUI Laptop — Mission Maker Guide

Set up the AE3 desktop (GUI) laptop in **3DEN** and **Zeus** using only placed assets,
attributes and modules — **no scripting required**. Plant intel for players to find, lock
files with passwords, add CCTV feeds, and (optionally) control who gets which interface.

The GUI laptop is the same laptop as the CLI one — same filesystem, users, power and network.
Everything you plant is reachable from both interfaces.

---

## 0. Quick start (zero config)

1. Place an **AE3 laptop** (Assets ▸ AE3, e.g. *Rugged Laptop* — `Land_Laptop_03_black_F_AE3`).
   The vanilla `Land_Laptop_03_black_F` prop has **no** ArmaOS — use the AE3 variant.
2. Done. By default the laptop offers **both interfaces** and players freely switch between
   them: walk up, open the ACE interaction, and pick **Use Terminal** (CLI) or **Use Desktop**
   (GUI).

That's the whole minimum setup. Everything below is **optional** — add it only when you want
intel, restrictions or extra apps.

> The mission-wide default is the CBA setting **`AE3_Desktop_DefaultMode`** (default **Both**).
> Set it to CLI or GUI if you'd rather laptops start in one interface across the whole mission.

---

## 1. Planting intel (optional)

### In 3DEN

Place an **AE3: Add Intel** module (Systems ▸ Modules ▸ AE3), then double-click it to fill in
the fields. **Sync** the module to one or more laptops to target them; leave it unsynced to
target **all** laptops. The classic **AE3: Add File** / **AE3: Add Directory** modules work the
same way.

### In Zeus

Place the **AE3: Add Intel** module **on a laptop** to target it, or anywhere else to target
all laptops. Pick the **Type** — the three fields re-label themselves:

| Type | Field 1 | Field 2 | Field 3 |
|------|---------|---------|---------|
| Email | From | Subject | Body |
| Webpage | URL | Title | Content (`\|` = new line, `[[url\|label]]` = link) |
| Browser history entry | URL | Time (HH:MM, optional) | — |
| Calendar entry | Date (YYYY-MM-DD HH:MM) | Title | Details |
| Media file | Source path (`\mod\file.paa`) | image / video / audio | Filesystem destination |
| Password-protected file | Filesystem path | Password | Content |

The other AE3 modules (**Add User**, **Add File**, **Add Directory**, **Add Games**, **Add
Security Commands**) work on GUI laptops exactly as on CLI laptops, in both 3DEN and Zeus.

---

## 2. CCTV cameras (optional)

Place the **AE3: Add Camera** module on (or synced to) the object the camera view should come
from — a CCTV prop, a vehicle, anything. Set the **Camera name**. The feed then appears in the
laptop's **CCTV** app for every laptop in the mission.

---

## 3. Crashing a laptop (optional)

Place the **AE3: Crash Device** module on (or synced to) a laptop to blue-screen it until it is
powered off and on again. In 3DEN you can gate it behind a trigger; in Zeus, dropping it on a
laptop crashes it immediately. Useful for "the enemy wiped the device" beats.

---

## 4. Controlling who gets CLI / GUI (optional, Zeus)

By default everyone gets both interfaces and switches freely — you only need this if you want
to **restrict** access (e.g. only the hacker may open the desktop).

Place the **AE3: Interface & Access** module **on a laptop** in Zeus. The dialog gives you:

- **Interface mode** — what the laptop offers: *Default*, *CLI only*, *GUI only*, *Both*.
- **Players** — pick a connected player, then click **CLI**, **GUI**, **Both** or **None** to
  set what they can open. A player set to **Both** keeps the free CLI/GUI switch.
- **Side fallback** — what each side (BLUFOR / OPFOR / Independent / Civilian) gets if a player
  isn't listed individually. This covers players who **join after** you set it.

A player's own setting always wins; everyone else falls back to their side. Leave everything on
**Both** for the default behaviour.

> In **3DEN** there are no players yet (no UIDs at edit time), so per-player access is Zeus-only.
> For 3DEN, use the laptop's **Interface (CLI / GUI / Both)** attribute (double-click the laptop)
> to set the mode for everyone, and apply per-player rules from Zeus or a script (see appendix)
> once the mission is running.

### How the switch works

Each laptop shows up to two ACE actions — **Use Terminal** (CLI) and **Use Desktop** (GUI) —
and a player sees the ones they're allowed to use. A player allowed both simply picks either
each time; that **is** the switch. There is no separate toggle to manage.

While someone uses the desktop, other players see a static lock screen on the laptop texture
(intentional: zero GUI network traffic). The laptop is locked (mutex) — one user at a time,
including over SSH.

---

## 5. What players can do on the GUI laptop

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

---

## 6. Password-protected files

The easiest way is the **Add Intel** module with type **Password-protected file** (Zeus) — fill
in path, password and content. You can also create one with the plain **Add File** module by
typing the on-disk format directly:

`AE3_LOCKED|<password>|<content>` — the password must not contain `|`; the content may be
anything, including a media marker (`AE3_MEDIA|image|\mod\img.paa`) for a locked photo.

- **CLI:** `cat` shows *password protected*; `unlock /home/user/codes.txt hunter2` prints the
  content; `unlock -p ...` permanently removes the protection (needs write permission).
- **GUI:** opening the file in Files pops up a password prompt; the correct password opens the
  content with the normal viewer (text or media).
- Wrong attempts (CLI and GUI) are logged to `/var/log/auth.log` — itself readable intel.

---

## 7. Session persistence

The laptop keeps the state the previous user left it in:

- **GUI:** open windows, their positions, the Files path, the Browser URL, the Calendar month
  and **unsaved Notepad text** are stored on the laptop (synced) when the desktop closes and
  restored for the next user — even on a different client.
- **CLI:** the terminal buffer, login, prompt and history are persisted via `AE3_terminal_sync`;
  `/var/log/browser_history`, `/var/mail` and all files live in the server-side filesystem.
- Picking the laptop up into the inventory and redeploying it also preserves the filesystem.

This makes "find the laptop the enemy officer was just using" scenarios work: the desktop opens
with his mail, his browser tab and his half-written note still on screen.

---

## 8. Relevant CBA settings

| Setting | Effect |
|---------|--------|
| `AE3_Desktop_DefaultMode` | Default interface for laptops without a per-laptop override — **CLI / GUI / Both** (default **Both**) |
| `AE3_Desktop_DefaultTheme` | default theme (Dark / Light / Olive) |
| `AE3_Desktop_EnableDragDrop` | allow window dragging |
| `AE3_Desktop_EnableFileBrowsing` | allow the Files app |
| `AE3_AllowRootLogin` | allow direct root login (default off — use sudo) |
| `AE3_EnableErrorSound` | error beep on failed commands |
| `AE3_TransferSpeedLocal/Usb/Network` | simulated copy speeds (0 = instant) |
| `AE3_UiKeystrokeSyncInterval` etc. | CLI screen-texture sync tuning |

---

# Appendix — Advanced / scripting (optional)

Everything above is doable with buttons. This appendix is for power users and mod developers who
want to drive the same systems from `init.sqf`, triggers, the debug console, or another mod.
All of it is server-routed and JIP-safe (public object variables).

### Interface mode & access (framework)

There is intentionally **no player-facing switch** at the variable level — which interfaces a
laptop offers, and who may open each, is fully mod/mission controlled so other mods can layer
their own access models (keycards, hacking states, ranks) on top.

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

The Zeus **Interface & Access** module is just a front-end that builds these conditions for you.

### Planting intel & content from script

```sqf
// plain file (also via the Add File module)
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

// password-protected file (see section 6)
[_laptop, "/home/user/codes.txt", "hunter2", "Launch code: 7741"] call AE3_desktop_fnc_addLockedFile;

// CCTV camera for the CCTV app
["Compound Gate", _cctvProp] call AE3_desktop_fnc_registerCamera;

// crash the laptop (blue screen until power-cycled)
[_laptop] call AE3_power_fnc_crashDevice;
```

`"all"` targets every initialized laptop; media also accepts `"future"` (current **and** laptops
spawned later). The engine cannot list files inside mods — media must be registered with explicit
paths.

### Creating your own app

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

Apps can persist their own state across users by returning a `getState` callback and reading it
back from `_args` (see `fnc_app_files.sqf` for the pattern).
