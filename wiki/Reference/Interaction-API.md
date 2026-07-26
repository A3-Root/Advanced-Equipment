# Interaction API

The Interaction component owns player-facing ACE actions, equipment animations, laptop lid open/close behavior, desk open/close behavior, and lamp on/off behavior.

Use this API for small scripted interactions. For new equipment classes, see [Config Classes](Config-Classes.md) and [Addon Components](../Developer/Addon-Components.md).

## Laptop Lid

### `AE3_interaction_fnc_laptop_open`

Animates a laptop lid to the open position.

```sqf
private _ok = [_laptop] call AE3_interaction_fnc_laptop_open;
```

Return value: `true`.

Example:

```sqf
[_laptop] call AE3_interaction_fnc_laptop_open;
```

### `AE3_interaction_fnc_laptop_close`

Animates a laptop lid to the closed position.

```sqf
private _ok = [_laptop] call AE3_interaction_fnc_laptop_close;
```

Return value: `true`.

Example:

```sqf
[_laptop] call AE3_interaction_fnc_laptop_close;
```

Normal ACE actions check whether the computer mutex is free before allowing open/close. If you call these directly, enforce your own safety check if needed:

```sqf
if (isNull (_laptop getVariable ["AE3_computer_mutex", objNull])) then {
    [_laptop] call AE3_interaction_fnc_laptop_close;
};
```

## Lamps

### `AE3_interaction_fnc_lamp_turnOn`

Turns a lamp on and updates ACE interaction state.

```sqf
private _ok = [_lamp] call AE3_interaction_fnc_lamp_turnOn;
```

The function uses `BIS_fnc_switchLamp` globally and tells the server to update interaction state.

### `AE3_interaction_fnc_lamp_turnOff`

Turns a lamp off and updates ACE interaction state.

```sqf
private _ok = [_lamp] call AE3_interaction_fnc_lamp_turnOff;
```

Example:

```sqf
[_lamp] call AE3_interaction_fnc_lamp_turnOn;
sleep 5;
[_lamp] call AE3_interaction_fnc_lamp_turnOff;
```

## Desks and Generic Equipment

The following functions are mostly used by configured equipment classes and ACE actions:

| Function | Purpose |
| --- | --- |
| `AE3_interaction_fnc_desk_open` | Opens configured desk/cabinet-style equipment. |
| `AE3_interaction_fnc_desk_close` | Closes configured desk/cabinet-style equipment. |
| `AE3_interaction_fnc_animateAction` | Runs a configured animation action. |
| `AE3_interaction_fnc_animateInteraction` | Handles configured interaction animation behavior. |
| `AE3_interaction_fnc_initAce3Interactions` | Adds ACE interactions defined by config. |
| `AE3_interaction_fnc_manageAce3Interactions` | Updates interaction availability/state on the server. |

For mission scripts, prefer the high-level action functions such as laptop open/close and lamp on/off. For addon development, define behavior in config so the component initializes interactions automatically.

## Interaction State

AE3 interactions often use named states such as:

| State | Meaning |
| --- | --- |
| `turnedOn` | Lamp or power-style object is currently on. |
| `inUse` | Computer is currently held by a player session. |
| `powerConnected` | Power consumer has a provider cable/link. |
| `networkConnected` | Network consumer has an uplink. |

State is generally updated on the server:

```sqf
[_object, "turnedOn", true] remoteExecCall ["AE3_interaction_fnc_manageAce3Interactions", 2];
```

Use existing public APIs when possible because they update interaction state for you.

## Related Pages

- [Power API](Power-API.md)
- [Network API](Network-API.md)
- [Config Classes](Config-Classes.md)
- [Lights and Interaction System](../Systems/Lights-and-Interaction.md)
