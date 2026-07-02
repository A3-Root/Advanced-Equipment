# Configure Power

This recipe connects AE3 laptops, routers, and other devices to power sources. It includes Eden Editor, Zeus, and API workflows.

Power matters because laptops and routers may not function when off, unpowered, out of fuel, or out of battery.

## Eden Editor Workflow

Use this before mission start.

### Simple Powered Laptop

1. Place an AE3 laptop.
2. Place a generator, battery, or solar/power setup.
3. Double-click the power source.
4. Set fuel, charge, or power level as appropriate.
5. Enable `Powered On At Start` if the source should already be running.
6. Double-click the laptop.
7. Enable `Powered On At Start` if the laptop should be ready immediately.
8. Use `AE3: connect device to power source`.
9. Connect the laptop to the power source.
10. Preview the mission.
11. Use ACE interactions to turn on the source and laptop if they did not start on.

### Powered Router

1. Place a router.
2. Place a power source.
3. Configure router network attributes.
4. Configure router power/start attributes.
5. Connect the router to the power source with `AE3: connect device to power source`.
6. Preview and test network behavior.

### Battery and Solar Setup

1. Place a battery.
2. Place a solar panel.
3. Place a laptop or router.
4. Connect the battery to the solar panel.
5. Connect the laptop/router to the battery.
6. Set initial charge levels.
7. Preview in daylight and verify the setup sustains the intended device.

## Copy-Paste Power Bundle

Use this when you want the mission to show the full power chain:

```sqf
if (isServer) then {
    [_generator, 100] call AE3_power_fnc_setFuelLevel;
    [_battery, 80] call AE3_power_fnc_setBatteryLevel;

    [_battery, _solarPanel] call AE3_power_fnc_createPowerConnection;
    [_laptop, _battery] call AE3_power_fnc_createPowerConnection;
    [_router, _generator] call AE3_power_fnc_createPowerConnection;

    [_solarPanel] call AE3_power_fnc_turnOnDevice;
    [_generator] call AE3_power_fnc_turnOnDevice;
    [_battery] call AE3_power_fnc_turnOnDevice;
    [_laptop] call AE3_power_fnc_turnOnDevice;
    [_router] call AE3_power_fnc_turnOnDevice;
};
```

This bundle gives you a powered laptop and router, plus a battery fallback and a solar option for missions that need moving parts.

## Zeus Workflow

Use this during live play.

1. Open Zeus.
2. Select or place the device and power source.
3. Use the Zeus connection workflow or `AE3: Add Connection` to connect the device to the provider.
4. Turn on the provider if needed.
5. Turn on or standby the laptop/router if needed.
6. If players are troubleshooting, let them discover the power state through ACE interactions rather than silently fixing everything.

Live-use examples:

- Zeus cuts laptop power during a sabotage event.
- Zeus connects an emergency generator after players repair it.
- Zeus crashes a laptop, then players power-cycle it to recover.
- Zeus drains or restores a battery to control mission pacing.

## API Workflow

Run durable power setup on the server.

Generator example:

```sqf
if (isServer) then {
    [_generator, 100] call AE3_power_fnc_setFuelLevel;
    [_laptop, _generator] call AE3_power_fnc_createPowerConnection;

    [_generator] call AE3_power_fnc_turnOnDevice;
    [_laptop] call AE3_power_fnc_turnOnDevice;
};
```

Battery and solar example:

```sqf
if (isServer) then {
    [_battery, 80] call AE3_power_fnc_setBatteryLevel;

    [_battery, _solarPanel] call AE3_power_fnc_createPowerConnection;
    [_laptop, _battery] call AE3_power_fnc_createPowerConnection;

    [_solarPanel] call AE3_power_fnc_turnOnDevice;
    [_battery] call AE3_power_fnc_turnOnDevice;
    [_laptop] call AE3_power_fnc_turnOnDevice;
};
```

Crash and recover:

```sqf
[_laptop] call AE3_power_fnc_crashDevice;

// Later:
[_laptop] call AE3_power_fnc_turnOffDevice;
[_laptop] call AE3_power_fnc_turnOnDevice;
```

Read state:

```sqf
private _stateText = [_laptop] call AE3_power_fnc_getPowerState;
private _stateNumber = _laptop getVariable ["AE3_power_powerState", -1];
private _fuel = [_generator] call AE3_power_fnc_getFuelLevel;
```

## Player Testing

1. Approach the power source.
2. Use ACE actions to check fuel/charge/output if available.
3. Turn on the source.
4. Turn on the laptop/router.
5. Open the intended interface.
6. Disconnect or turn off the source and confirm the failure behavior is acceptable.

## Common Mistakes

| Problem | Fix |
| --- | --- |
| Laptop will not turn on | Check provider, internal battery, fuel/charge, and power connection. |
| Router network appears broken | Router may be unpowered even if network connection exists. |
| Battery API returns false | `setBatteryLevel` must run on the server. |
| Solar panel output seems wrong | Check daylight, panel orientation, line of sight, and mission time. |
| Power is not meant to be a puzzle | Start devices powered and provide enough fuel/charge. |

## Related Pages

- [Power System](../Systems/Power.md)
- [Power API](../Reference/Power-API.md)
- [Network API](../Reference/Network-API.md)
- [Examples Library](README.md)
