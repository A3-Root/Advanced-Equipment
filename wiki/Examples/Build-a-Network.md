# Build a Network

This recipe connects laptops to routers and prepares network behavior for ping, SSH, messages, browser-adjacent clues, or mission systems that depend on IP reachability.

It includes Eden Editor, Zeus, and API workflows.

## Result

Players can use terminal commands such as:

```text
ip
ping 10.0.0.12
ssh admin@10.0.0.12
msg 10.0.0.12 hello
```

Exact commands depend on which terminal commands are installed and whether the mission provides credentials.

## Copy-Paste Network Bundle

Use this when the network itself is the clue chain:

```sqf
if (isServer) then {
    [_routerA, "HQ Net", 150, "hq-pass", "10.0.0.1", false, ""] call AE3_network_fnc_applyRouterConfig;
    [_routerB, "Depot Net", 100, "depot-pass", "10.0.1.1", true, "10\\.0\\.0\\..*"] call AE3_network_fnc_applyRouterConfig;

    [_routerB, _routerA] call AE3_network_fnc_createNetworkConnection;
    [_hqLaptop, _routerA] call AE3_network_fnc_createNetworkConnection;
    [_depotLaptop, _routerB] call AE3_network_fnc_createNetworkConnection;

    ["intel.root/home", "Operations Index", "See intel.root/depot and intel.root/radio.", _hqLaptop] call AE3_desktop_fnc_registerWebpage;
    [_hqLaptop, "intel.root/home", "02:03"] call AE3_desktop_fnc_addHistoryEntry;
};
```

Pair it with the browser sample pages when the network should lead players into a richer webpage rather than a plain terminal result.

## Eden Editor Workflow

Use this before mission start.

### Simple Router Network

1. Place an AE3 router.
2. Double-click the router and configure:
   - `Network Name (SSID)`: for example `Depot Net`.
   - `Default Gateway`: for example `10.0.0.1`.
   - `Wifi Range (m)`: for example `100`.
   - `Network Password`: blank for open network or a password players can discover.
   - `Powered On At Start`: enabled if players should use it immediately.
3. Place one or more AE3 laptops.
4. Configure each laptop:
   - Interface Mode: CLI or Both if players will use terminal network commands.
   - Static IP: optional; leave blank for DHCP.
   - Powered On At Start: optional.
5. Right-click/connect using `AE3: connect device to network router`.
6. Connect each laptop to the router.
7. Ensure laptops and router have power or internal charge.
8. Preview and test `ip` and `ping`.

### Multi-Router Network in Eden

Use this only when routing is part of the mission.

1. Place Router A and Router B.
2. Give them different gateways, for example:
   - Router A: `10.0.0.1`.
   - Router B: `10.0.1.1`.
3. Connect laptops to their intended router.
4. Connect Router B to Router A with `AE3: connect device to network router`.
5. If cross-gateway SSH or ping should work, enable external access on the target router.
6. Configure `External Allowed IPs` if only some sources may connect.
7. Preview on a dedicated server when possible.

## Zeus Workflow

Use this to modify or repair a network during live play.

1. Open Zeus.
2. Place a router and laptop if they do not already exist.
3. Open the router's Zeus attributes/details if available and verify SSID, gateway, range, password, and power state.
4. Use `AE3: Add Connection` or the Zeus connection workflow to connect a laptop to a router.
5. Power on the router and laptop if needed.
6. If players need cross-network access, enable/configure external access on the relevant router.
7. Tell players through in-world information that the network is available or changed.

Live repair examples:

- Reconnect a laptop that was placed without an uplink.
- Spawn a router as a fallback after players destroy the first one.
- Enable external access after players capture credentials.
- Disconnect a compromised laptop from a router.

## API Workflow

Run network setup on the server.

```sqf
if (isServer) then {
    [_router, "Depot Net", 100, "depot-pass", "10.0.0.1", false, ""] call AE3_network_fnc_applyRouterConfig;
    [_laptopA, _router] call AE3_network_fnc_createNetworkConnection;
    [_laptopB, _router] call AE3_network_fnc_createNetworkConnection;
};
```

Static IP setup:

```sqf
if (isServer) then {
    [_laptopA, "10.0.0.20"] call AE3_network_fnc_setStaticIp;
    [_laptopB, "10.0.0.21"] call AE3_network_fnc_setStaticIp;
};
```

Cross-gateway router setup:

```sqf
if (isServer) then {
    [_routerA, "HQ Net", 150, "hq-pass", "10.0.0.1", false, ""] call AE3_network_fnc_applyRouterConfig;
    [_routerB, "Depot Net", 100, "depot-pass", "10.0.1.1", true, "10\\.0\\.0\\..*"] call AE3_network_fnc_applyRouterConfig;

    [_routerB, _routerA] call AE3_network_fnc_createNetworkConnection;
    [_hqLaptop, _routerA] call AE3_network_fnc_createNetworkConnection;
    [_depotLaptop, _routerB] call AE3_network_fnc_createNetworkConnection;
};
```

Debug a route:

```sqf
private _ip = ["10.0.1.12"] call AE3_network_fnc_str2ip;
private _route = [_hqLaptop, _ip] call AE3_network_fnc_resolve;
_route params ["_target", "_length"];

if (isNull _target) then {
    systemChat "No route or route blocked";
} else {
    systemChat format ["Route found, length %1", _length];
};
```

## Player Testing

On the source laptop terminal:

```text
ip
ping 10.0.0.20
ssh admin@10.0.0.20
msg 10.0.0.20 test
```

Also test:

- Router powered off.
- Router powered on.
- Laptop with DHCP.
- Laptop with static IP.
- Wrong subnet/static duplicate.
- Cross-gateway allowed and blocked cases.

## Common Mistakes

| Problem | Fix |
| --- | --- |
| `ping` fails | Check power, router connection, IP, and gateway policy. |
| Laptop has no IP | Router may be off, connection missing, or DHCP not refreshed. |
| Static IP does not apply | Use an IP in the router subnet and avoid duplicates. |
| SSH fails but ping works | Credentials, installed commands, or SSH compatibility may be the issue. |
| Zeus network repair works for one player only | Ensure state-changing calls happen on the server. |

## Related Pages

- [Networking System](../Systems/Networking.md)
- [Network API](../Reference/Network-API.md)
- [Terminal Commands](../Reference/Terminal-Commands.md)
- [Browser Sample Pages](Browser-Sample-Pages.md)
- [Examples Library](README.md)
