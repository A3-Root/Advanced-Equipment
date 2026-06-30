# Power API

## Device Control

| Function | Purpose |
| --- | --- |
| `AE3_power_fnc_turnOnDevice` | Turn on a configured power device. |
| `AE3_power_fnc_turnOffDevice` | Turn off a configured power device. |
| `AE3_power_fnc_standbyDevice` | Put a device in standby. |
| `AE3_power_fnc_crashDevice` | Crash a running computer until power-cycled. |
| `AE3_power_fnc_getPowerState` | Return state: off, on, standby, or crashed. |

## Connections and Levels

| Function | Purpose |
| --- | --- |
| `AE3_power_fnc_createPowerConnection` | Connect consumer to provider. |
| `AE3_power_fnc_removePowerConnection` | Remove provider link from a consumer. |
| `AE3_power_fnc_getFuelLevel` | Return generator fuel data. |
| `AE3_power_fnc_setFuelLevel` | Set generator fuel percent. |
| `AE3_power_fnc_getBatteryLevel` | Return battery level data. |
| `AE3_power_fnc_setBatteryLevel` | Set battery level percent. |
| `AE3_power_fnc_getPowerOutput` | Return current provider output. |
| `AE3_power_fnc_updatePower` | Recalculate provider load. |
| `AE3_power_fnc_batteryCalculation` | Calculate battery charge/discharge state. |
| `AE3_power_fnc_solarCalculation` | Calculate solar output. |

## Examples

```sqf
[_laptop, _generator] call AE3_power_fnc_createPowerConnection;
[_generator, 0.8] call AE3_power_fnc_setFuelLevel;

if ([_laptop] call AE3_power_fnc_turnOnDevice) then {
    systemChat "Laptop powered";
};
```
