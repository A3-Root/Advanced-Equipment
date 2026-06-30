# Lights and Interaction

AE3 interaction wraps equipment behavior in ACE actions. Laptops, desks, lights, generators, batteries, solar panels, routers, and flash drives use this layer for opening, closing, carrying, dragging, cargo, turning on, and use-state restrictions.

## Lights

AE3 light classes integrate with the power system. They can be turned on and off through ACE actions or script:

```sqf
[_lamp] call AE3_interaction_fnc_lamp_turnOn;
[_lamp] call AE3_interaction_fnc_lamp_turnOff;
```

## Equipment State

The interaction manager can block ACE carrying, dragging, or cargo while equipment is connected, open, turned on, or in use.

```sqf
[_laptop, "inUse", true] remoteExecCall ["AE3_interaction_fnc_manageAce3Interactions", 2];
```

## Custom Equipment

Addon developers can use `AE3_Equipment`, animation points, and ACE interaction config classes to make equipment behave like native AE3 objects.
