# Register Desktop Apps

Register a runtime GUI app on every client that should see it, usually from addon preInit/postInit.

```sqf
["my_status", "Status", "myTag_fnc_statusApp", [0.45, 0.35], true, true] call AE3_desktop_fnc_registerApp;
```

Entry function shape:

```sqf
params ["_winId", "_ctrlGroup", "_computer", "_args"];

private _text = _ctrlGroup ctrlCreate ["RscText", -1];
_text ctrlSetText "Site status: nominal";
_text ctrlSetPosition [0, 0, 0.4, 0.05];
_text ctrlCommit 0;

createHashMap
```

For web-desktop integrations, register a command handler:

```sqf
["myCommand", {
    params ["_computer", "_user", "_data", "_rid"];
    [_rid, createHashMapFromArray [["ok", true]]] call AE3_desktop_fnc_jsReply;
}] call AE3_desktop_fnc_registerCmd;
```
