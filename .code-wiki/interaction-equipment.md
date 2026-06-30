---
topic: interaction-equipment
status: verified
last-verified: 2026-06-30
confidence_score: 1.0
priority: support
tokens: ~590
code-paths:
  - addons/interaction/
  - addons/interaction/CfgVehicles.hpp
related-topics: [power-model, armaos-terminal, flashdrive-usb]
related-docs:
  - wiki/Systems/Interactions.md
---

# Interaction Equipment

## overview

The interaction component compiles AE3 equipment config, initializes ACE interactions, manages open/close states, and provides actions for lamps, laptops, desks, solar panels, carrying, dragging, and cargo.

## current behavior

- `XEH_preInit.sqf` registers a CBA class event handler so all objects run AE3 interaction compilation/init logic.
- Equipment config supplies ACE dragging, carrying, cargo, animation, and condition settings.
- `AE3_interaction_fnc_initAce3Interactions` runs on the server, stores ACE settings in `AE3_SettingsACE3`, and calls `manageAce3Interactions` to apply the initial state.
- Laptop and desk open/close functions are separate from power functions, but power action conditions check `AE3_interaction_closeState`.
- Other components call into interaction helpers to nest their actions under the common equipment parent action when it exists.

## decisions

- A shared equipment parent action is used as a coordination point for power, network, laptop, and equipment-specific interactions, preventing multiple top-level ACE actions from accumulating on the same object.
- Interaction state is stored on object variables rather than recomputed from animation phase every time, giving ACE action visibility and multiplayer state a simple synchronized source.
- ACE dragging/carrying/cargo settings are compiled from config into a hashmap, so runtime code can work against one normalized shape regardless of how each vehicle class is configured.

## gotchas

- Duplicate action prevention is spread across components with component-specific flags.
- Interaction initialization differs between server authority and client ACE menu creation.
- Closing/opening state can block power operations.

## re-verify when

- ACE menu paths, equipment config classes, laptop/desk open-close functions, or action-added flags change.

## references

- `addons/interaction/functions/fnc_initAce3Interactions.sqf`
- `addons/interaction/functions/fnc_initInteraction.sqf`
- `addons/interaction/functions/fnc_manageAce3Interactions.sqf`
- `addons/interaction/functions/fnc_laptop_open.sqf`
- `addons/interaction/functions/fnc_laptop_close.sqf`

