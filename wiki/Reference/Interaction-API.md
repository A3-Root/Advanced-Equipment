# Interaction API

Interaction functions initialize and manage ACE actions for AE3 equipment.

## Public Calls

| Function | Purpose |
| --- | --- |
| `AE3_interaction_fnc_compileEquipment` | Compile equipment config and initialize interactions. |
| `AE3_interaction_fnc_initInteraction` | Initialize a custom interactive object. |
| `AE3_interaction_fnc_initAce3Interactions` | Initialize ACE drag/carry/cargo state. |
| `AE3_interaction_fnc_manageAce3Interactions` | Update blocked interaction states. |
| `AE3_interaction_fnc_initLamp` | Initialize AE3 lamp behavior. |
| `AE3_interaction_fnc_lamp_turnOn` | Turn on an AE3 lamp. |
| `AE3_interaction_fnc_lamp_turnOff` | Turn off an AE3 lamp. |
| `AE3_interaction_fnc_initLaptop` | Initialize laptop interaction actions. |
| `AE3_interaction_fnc_laptop_open` | Open a laptop lid. |
| `AE3_interaction_fnc_laptop_close` | Close a laptop lid. |
| `AE3_interaction_fnc_initDesk` | Initialize desk state. |
| `AE3_interaction_fnc_desk_open` | Open a desk. |
| `AE3_interaction_fnc_desk_close` | Close a desk. |

## Example

```sqf
[_lamp] call AE3_interaction_fnc_initLamp;
[_lamp] call AE3_interaction_fnc_lamp_turnOn;

[_laptop, "inUse", false] remoteExecCall ["AE3_interaction_fnc_manageAce3Interactions", 2];
```
