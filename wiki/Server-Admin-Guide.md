# Server Admin Guide

This page explains what a server administrator needs to know to host missions using AE3.

## Required Mods

Load these on the server and clients:

- CBA_A3
- ACE3
- Advanced Equipment Revamped

All players should use compatible versions. Mismatched client/server mod versions can cause missing actions, missing UI, or desynchronized equipment state.

## Recommended Load Order

Load dependencies first:

1. CBA_A3
2. ACE3
3. Advanced Equipment Revamped
4. Mission-specific AE3 extension mods, if any

## CBA Settings Worth Reviewing

AE3 exposes ~28 CBA settings (server/mission-wide, no scripting needed) covering debug logging, terminal branding/appearance, network-sync bandwidth tuning, and the laptop deployment model. See [Config Classes](Reference/Config-Classes.md#cba-settings) for the full list. Two are worth deciding on before a populated dedicated server session:

- `AE3_DeploymentType` — **Stable** (simple hide/show, vanilla laptop items) vs **Experimental** (full state preservation, custom items). Changing this requires a mission restart; pick one before launch rather than mid-session.
- The UI-on-Texture sync settings (`AE3_UiPlayerRange`, `AE3_UiMaxConcurrentViewers`, `AE3_UiMaxTransmitLines`, `AE3_armaos_uiOnTexUpdateInterval`) — defaults are tuned for normal play; lower viewer/line limits if a mission has many players clustered around laptops.

## GUI/Desktop File Extensions

The GUI/Desktop interface uses files such as CSS, JavaScript, and Markdown. Dedicated servers that restrict loadable file types must allow these extensions.

At minimum, allow:

- `css`
- `js`
- `md`

If the GUI desktop does not load correctly on a dedicated server, check `allowedLoadFileExtensions[]` in `server.cfg`.

## Multiplayer Behavior

AE3 stores important state on mission objects and the server. This includes laptop contents, users, browser pages, mail, power state, network links, and mounted storage.

For mission testing:

- Test laptop login on a dedicated server.
- Test GUI and terminal access with at least one normal client.
- Test Zeus modules with an actual curator.
- Test reconnect/JIP if the mission depends on persistent laptop state.
- Test power and network puzzles after mission start and in editor preview.

## Performance Notes

Most missions will not need special tuning. To keep AE3 scenarios reliable:

- Avoid placing large numbers of fully configured laptops unless needed.
- Avoid unnecessary routers and cross-network routes.
- Keep media files reasonably sized.
- Prefer concise webpages and documents.
- Test Zeus-heavy missions with the expected player count.

## Common Server Issues

### GUI opens but content is missing

Check server file extension restrictions. The desktop may need `css`, `js`, and `md` to load correctly.

### Players cannot interact with equipment

Check:

- ACE3 is loaded on server and clients.
- The object is local/initialized correctly.
- The device is not already in use.
- The player is close enough and has ACE interaction access.

### Laptop works locally but not on dedicated server

Check:

- Mission setup modules are synced correctly.
- Required mods are loaded on the server.
- File extension whitelist is configured.
- The mission was tested from a client and in local preview.

### Network gameplay fails

Check:

- Router is powered.
- Laptop is connected to the router.
- Router range is large enough.
- Password is correct.
- External access is enabled if crossing gateways.

### Power gameplay fails

Check:

- Power source is turned on.
- Generator has fuel.
- Battery has charge.
- Device is connected to the intended power provider.
- The mission does not require a power source that players cannot access.

## Reporting Server Problems

When reporting a server issue, include:

- AE3 version.
- Arma 3 server version.
- CBA_A3 and ACE3 versions.
- Dedicated server or hosted multiplayer.
- Mod list.
- RPT logs from server and affected client.
- Whether GUI, terminal, power, network, Zeus, or 3DEN behavior is affected.
