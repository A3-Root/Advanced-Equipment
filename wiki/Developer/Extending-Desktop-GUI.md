# Extending Desktop GUI

## Config App

Add a class to `CfgAE3Apps`:

```cpp
class CfgAE3Apps
{
    class MyApp
    {
        displayName = "My App";
        entry = "myTag_fnc_myApp";
        icon = "";
        defaultSize[] = {0.5, 0.5};
        showOnDesktop = 1;
        singleton = 1;
        requiresFilesystem = 1;
    };
};
```

Entry function:

```sqf
params ["_winId", "_ctrlGroup", "_computer", "_args"];
createHashMapFromArray [["onClose", {}]]
```

## Runtime App

```sqf
["my_runtime_app", "Runtime App", "myTag_fnc_runtimeApp", [0.5, 0.5], true, true] call AE3_desktop_fnc_registerApp;
```

Register runtime apps on all clients that should see them.
