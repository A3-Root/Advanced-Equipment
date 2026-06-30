# Networking

AE3 networking gives routers and devices IP addresses, wireless connections, DHCP, static IPs, ping, SSH, messaging, gateway routing, and optional external access rules.

## Routers

Routers have:

- SSID
- Gateway address
- Wireless range
- Optional password
- External SSH/routing toggle
- Optional external allow list

```sqf
[_router, "Depot Net", 80, "depot123", "10.0.0.1", true, "10\\.1\\.0\\..*"] call AE3_network_fnc_applyRouterConfig;
```

## Connections

```sqf
[_laptop, _router] call AE3_network_fnc_createNetworkConnection;
[_router2, _router1] call AE3_network_fnc_createNetworkConnection;
[_laptop] call AE3_network_fnc_removeNetworkConnection;
```

## Terminal Use

```text
ip
ping 10.0.0.5
ssh admin@10.0.0.5
msg 10.0.0.5 "status?"
```

## Static IPs

Static leases are stored per connected router.

```sqf
private _result = [_laptop, "10.0.0.42"] call AE3_network_fnc_setStaticIp;
```
