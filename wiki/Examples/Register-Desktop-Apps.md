# Register Desktop Apps

Registering new desktop apps is an addon/developer workflow. This recipe explains what Eden, Zeus, and API paths can and cannot do.

Most mission content should use built-in apps instead of creating a new app.

## No-Code Alternatives

| Need | Built-in app/workflow |
| --- | --- |
| Read a document | Files app or terminal `cat`. |
| Show web-style intel | Browser app. |
| Show messages | Mail app. |
| Show dates/events | Calendar app. |
| Show image/audio/video | Media registration and Files app. |
| Show camera feed | CCTV app/camera registration. |
| Run commands | Terminal/TUI. |

## Eden Editor Workflow

Eden cannot define a brand-new desktop app without addon/script support. It can configure which existing interface and content players see:

1. Place/select the laptop.
2. Set Interface Mode to GUI or Both.
3. Add users.
4. Add files, emails, webpages, browser history, media, locked files, or calendar events.
5. Put important files under `/home/<user>/Desktop` if players should see them quickly.

If an addon already registered a desktop app, Eden can expose it indirectly by giving the right user a launcher file or by using the addon's documented module.

## Zeus Workflow

Zeus cannot safely create arbitrary new desktop application code during live play. Use live content instead:

- Add File.
- Add Email.
- Add Intel/Webpage.
- Add Media.
- Add Calendar Event.
- Add/repair user access.

If an addon provides a Zeus module for its app, follow that addon's workflow.

## API Runtime App Workflow

Register runtime apps on every client that should see them.

```sqf
if (hasInterface) then {
    ["myMission_tools", "Tools", "myMission_fnc_toolsApp", [0.55, 0.5], true, true] call AE3_desktop_fnc_registerApp;
};
```

App entry function:

```sqf
myMission_fnc_toolsApp = {
    params ["_winId", "_ctrlGroup", "_computer", "_args"];

    private _text = _ctrlGroup ctrlCreate ["RscText", -1];
    _text ctrlSetPosition [0.02, 0.02, 0.5, 0.05];
    _text ctrlSetText "Tools ready.";
    _text ctrlCommit 0;

    createHashMap
};
```

Because this is client-local, put registration in a client init path. A server script alone will not register the app for every player.

## Addon Config App Workflow

For reusable addon apps, define `CfgAE3Apps`.

```cpp
class CfgAE3Apps
{
    class myMod_tools
    {
        displayName = "Tools";
        entry = "myMod_fnc_toolsApp";
        icon = "";
        defaultSize[] = {0.55, 0.5};
        showOnDesktop = 1;
        singleton = 1;
        requiresFilesystem = 1;
    };
};
```

Then implement the entry function in your addon and compile it normally.

## Web Desktop Extension Workflow

For web desktop integrations, register an external app and command handlers on clients:

```sqf
if (hasInterface) then {
    private _extra = createHashMapFromArray [["deviceType", "doorRelay"]];
    ["myMod_doors", "Door Relays", "D", "deviceList", _extra] call AE3_desktop_fnc_registerExtApp;

    ["myMod_listDoors", {
        params ["_computer", "_user", "_data", "_rid"];
        ["myMod_listDoors", _rid, []] call AE3_desktop_fnc_jsReply;
    }] call AE3_desktop_fnc_registerCmd;
};
```

## Testing

1. App appears for the intended user.
2. App does not appear where it should not.
3. App opens and closes cleanly.
4. App works after JIP.
5. App works on a dedicated server with two clients.
6. App cleans up handlers/cameras/timers on close.

## Common Mistakes

| Problem | Fix |
| --- | --- |
| App appears only for host | Register on every client. |
| App icon missing | Check launcher/Desktop setup and `showOnDesktop`. |
| App state changes only locally | Route state-changing actions to the server. |
| App crashes when laptop has no filesystem | Require or wait for filesystem state. |
| No-code mission does not need an app | Use built-in content apps instead. |

## Related Pages

- [Desktop Apps](../Reference/Desktop-Apps.md)
- [Desktop API](../Reference/Desktop-API.md)
- [Extending Desktop GUI](../Developer/Extending-Desktop-GUI.md)
