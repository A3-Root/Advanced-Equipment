# Power

AE3 power makes devices depend on generators, batteries, solar panels, internal batteries, and connection state.

## Power Sources

Common power sources:

- Generator: usually needs fuel.
- Battery: uses stored charge.
- Solar panel: output depends on configuration and sun behavior.
- Internal battery: built into some devices such as routers or laptops.

## Power Consumers

Common consumers:

- Laptops.
- Routers.
- Lights.
- Batteries being charged.

## Editor Setup

Use `AE3: connect device to power source`.

Typical setup:

1. Place a laptop or router.
2. Place a generator, battery, or solar panel.
3. Configure fuel or power level in object attributes.
4. Connect the consumer to the source.
5. Preview and test turn-on behavior.

## Player Workflow

Players may need to:

- Find a power source.
- Turn on a generator.
- Check fuel or charge.
- Connect a device to power.
- Turn on the laptop or router.
- Restore power after a device crashes or shuts down.

## Good Power Design

- Use power when it creates a meaningful objective.
- Do not hide critical intel behind too many unrelated power steps.
- Make fuel, batteries, or generators discoverable.
- Test whether players can physically reach and use the power objects.
- If a laptop starts off, make that clear through mission context.

Script power calls belong in [Power API](../Reference/Power-API.md).
