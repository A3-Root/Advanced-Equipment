# Lights and Interaction

AE3 uses ACE interactions for equipment. Players interact with laptops, lights, desks, routers, generators, batteries, solar panels, and flash drives through ACE menus.

## What Interaction Controls

The interaction system handles:

- Opening and closing laptops.
- Opening and closing desks.
- Turning lights on and off.
- Turning power devices on and off.
- Carrying, dragging, and loading objects into cargo when allowed.
- Blocking movement or use while a device is connected, powered, open, or already in use.

## Lights

AE3 light variants can be placed in 3DEN or Zeus. They can be tied into power gameplay when configured as AE3 powered devices.

Player flow:

1. Find the light.
2. Ensure it has power if the mission requires it.
3. Use ACE interaction to turn it on or off.

## Laptops and Desks

Laptops and desks can have open/close interactions. A laptop may not close while someone is using it. This prevents interrupting active GUI or terminal sessions.

## Mission-Maker Tips

- Do not place important equipment where players cannot access the ACE interaction point.
- If players need to carry an object, test carrying and cargo behavior in preview.
- If an object refuses to move, check whether it is powered, connected, open, or in use.
- Use lights to signal power state, objective areas, or player progress.

Script interaction calls belong in [Interaction API](../Reference/Interaction-API.md).
