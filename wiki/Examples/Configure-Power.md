# Configure Power

```sqf
if (isServer) then {
    [_generator, 1.0] call AE3_power_fnc_setFuelLevel;
    [_battery, 0.75] call AE3_power_fnc_setBatteryLevel;

    [_laptop, _generator] call AE3_power_fnc_createPowerConnection;
    [_router, _battery] call AE3_power_fnc_createPowerConnection;

    [_generator] call AE3_power_fnc_turnOnDevice;
    [_battery] call AE3_power_fnc_turnOnDevice;
};
```

Crash a laptop for a scripted event:

```sqf
[_laptop] call AE3_power_fnc_crashDevice;
```

Power-cycle it to recover.
