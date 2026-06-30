# Getting Started

Load Advanced Equipment with CBA_A3 and ACE3. In the editor, place AE3 laptop, router, power, light, and flash drive classes from the editor/Zeus categories, or use the provided modules to add users, files, connections, webpages, emails, media, and interface access.

## Basic Laptop Flow

1. Place an AE3 laptop.
2. Set its interface mode in 3DEN: terminal only, desktop only, or both.
3. Add at least one user, either through 3DEN/Zeus modules or script.
4. Add files, webpages, media, mail, or custom commands.
5. Connect power and network devices if the scenario needs them.

## Script Example

```sqf
[_laptop, "both"] call AE3_desktop_fnc_setInterfaceMode;
[_laptop, "admin", "password1"] call AE3_armaos_fnc_computer_addUser;
[_laptop, "intel.root/briefing", "Briefing", "Check the airfield at 0400."] call AE3_desktop_fnc_registerWebpage;
[_laptop, "intel.root/briefing", "03:12"] call AE3_desktop_fnc_addHistoryEntry;
```

Run setup that edits laptop state on the server unless the function documents client routing.
