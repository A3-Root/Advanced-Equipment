# Locality and Multiplayer

AE3 is multiplayer-oriented. Many operations route to the server or publish object variables, but extension code should still be explicit about locality.

## Rules of Thumb

- Initialize mission content on the server.
- Broadcast object state only when players or JIP clients need it.
- Use public APIs instead of editing internals where possible.
- Validate power, network, filesystem, and GUI/TUI access on a dedicated server.

## Example

```sqf
if (isServer) then {
    [_laptop, "both"] call AE3_desktop_fnc_setInterfaceMode;
    [_laptop, "admin", "password"] call AE3_armaos_fnc_computer_addUser;
    [_laptop, _router] call AE3_network_fnc_createNetworkConnection;
};
```

GUI app registration is local to clients that should see the app. Run runtime app registration on clients during addon initialization.
