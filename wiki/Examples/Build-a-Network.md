# Build a Network

```sqf
if (isServer) then {
    [_router, "Depot Net", 120, "depot123", "10.0.0.1", true, "10\\.1\\.0\\..*"] call AE3_network_fnc_applyRouterConfig;

    [_laptopA, _router] call AE3_network_fnc_createNetworkConnection;
    [_laptopB, _router] call AE3_network_fnc_createNetworkConnection;

    [_laptopA, "10.0.0.20"] call AE3_network_fnc_setStaticIp;
};
```

Terminal validation:

```text
ip
ping 10.0.0.20
ssh admin@10.0.0.20
```

Use router external access when another subnet should reach this router's devices.
