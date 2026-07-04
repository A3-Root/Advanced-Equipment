# Lights and Interaction

AE3 uses ACE interactions for equipment. Players interact with laptops, lights, desks, routers, generators, batteries, solar panels, and flash drives through ACE menus rather than actions or scripted dialogs.

## What Interaction Controls

The interaction system handles:

- Opening and closing laptops (lid animation).
- Opening and closing desks/cabinets.
- Turning lights (lamps) on and off.
- Turning power devices on and off.
- Carrying, dragging, and loading objects into cargo when configured to allow it.
- Blocking movement or use while a device is connected, powered, open, or already in use.

All AE3 equipment shares one parent ACE action so power, network, and equipment-specific actions nest under a single menu entry instead of cluttering the top-level ACE menu with duplicates.

## Lamps

Lamps have two states, `turnedOn` and `turnedOff`, exposed as ACE actions. State is tracked on the object and synced through the server so every client sees the same lamp state.

Player flow:

1. Find the light.
2. Ensure it has power if the mission requires it (see [Power](Power.md)).
3. Use ACE interaction ("Turn On" / "Turn Off") to switch it.

Scripted equivalent (for cutscenes, triggers, or Zeus-driven effects):

```sqf
[_lamp] call AE3_interaction_fnc_lamp_turnOn;
sleep 5;
[_lamp] call AE3_interaction_fnc_lamp_turnOff;
```

## Laptops and Desks

Laptops and desks can have open/close interactions. A laptop will not close while someone is actively using its GUI or terminal session — this is enforced through the laptop's mutex (`AE3_computer_mutex`), which prevents interrupting an active session and prevents two players from using the same laptop at once.

Desks/cabinets use the same open/close pattern but have no session concept.

## Mission-Maker Tips

- Do not place important equipment where players cannot reach the ACE interaction point (test line-of-sight and distance in preview).
- If players need to carry an object, test carrying and cargo behavior in preview — dragging/carrying/cargo permissions are configured per equipment class.
- If an object refuses to open, close, or move, check whether it is powered, connected, open, or already in use (`inUse` state) by another player.
- Use lights to signal power state, objective areas, or player progress — a lit lamp is a cheap, readable way to tell players "this area has power" without a HUD element.
- Locked/blocked interactions are a common source of "broken mission" bug reports — see [Interaction API](../Reference/Interaction-API.md) for the interaction states (`turnedOn`, `inUse`, `powerConnected`, `networkConnected`) if you need to debug or drive them from script.

## Related Pages

- [Interaction API](../Reference/Interaction-API.md) — scripted laptop/lamp/desk calls and interaction state.
- [Power](Power.md) / [Power API](../Reference/Power-API.md) — power state that gates many interactions.
