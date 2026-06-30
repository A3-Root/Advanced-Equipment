# Power

AE3 power connects consumers to providers and tracks generator fuel, battery charge, solar output, device state, and overload conditions.

## Power States

- `0`: off
- `1`: on
- `2`: standby
- `3`: crashed

## Connections

```sqf
[_laptop, _generator] call AE3_power_fnc_createPowerConnection;
[_router, _battery] call AE3_power_fnc_createPowerConnection;
[_laptop] call AE3_power_fnc_removePowerConnection;
```

## Device Control

```sqf
[_generator] call AE3_power_fnc_turnOnDevice;
[_laptop] call AE3_power_fnc_standbyDevice;
[_laptop] call AE3_power_fnc_turnOffDevice;
[_laptop] call AE3_power_fnc_crashDevice;
```

## Fuel and Battery Levels

```sqf
[_generator, 0.75] call AE3_power_fnc_setFuelLevel;
private _fuel = [_generator] call AE3_power_fnc_getFuelLevel;

[_battery, 0.5] call AE3_power_fnc_setBatteryLevel;
private _charge = [_battery] call AE3_power_fnc_getBatteryLevel;
```

Generators, batteries, and solar panels update connected devices through provider handlers. Validate custom power layouts on a dedicated server.
