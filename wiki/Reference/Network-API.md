# Network API

## Public Calls

| Function | Purpose |
| --- | --- |
| `AE3_network_fnc_createNetworkConnection` | Connect a device/router to a router. |
| `AE3_network_fnc_removeNetworkConnection` | Remove a network uplink. |
| `AE3_network_fnc_disconnect` | Disconnect a device from its parent router. |
| `AE3_network_fnc_applyRouterConfig` | Set router SSID, range, password, gateway, and external policy. |
| `AE3_network_fnc_ping` | Return target object and route length for an IP. |
| `AE3_network_fnc_resolve` | Resolve and authorize a target IP from a source device. |
| `AE3_network_fnc_setStaticIp` | Set or clear a laptop static IP for the current router. |
| `AE3_network_fnc_ip2str` | Convert `[10,0,0,1]` to `10.0.0.1`. |
| `AE3_network_fnc_str2ip` | Convert `10.0.0.1` to `[10,0,0,1]`. |

## Examples

```sqf
[_laptop, _router] call AE3_network_fnc_createNetworkConnection;
[_router, "Depot Net", 100, "depot", "10.0.0.1", false, ""] call AE3_network_fnc_applyRouterConfig;

private _target = ["10.0.0.12"] call AE3_network_fnc_str2ip;
private _route = [_laptop, _target] call AE3_network_fnc_resolve;
```

`AE3_network_fnc_setStaticIp` returns a hashmap describing success or failure.
