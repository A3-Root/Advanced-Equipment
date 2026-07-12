// File: fnc_computer_endSession.sqf
#include "..\script_component.hpp"
/*
 * Author: Root
 * Description: Ends this client's laptop session: closes the terminal or desktop it has open and hands
 * the laptop back to everyone else. Used when the operator can no longer be at the machine - they went
 * unconscious, died, respawned into a new unit - so the screen does not keep running for a player who is
 * not there and the laptop does not stay claimed by a unit that no longer exists.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call AE3_armaos_fnc_computer_endSession;
 *
 * Public: No
 */

if (!hasInterface) exitWith {};

private _computer = missionNamespace getVariable ["AE3_computer_session", objNull];
if (isNull _computer) exitWith {};

missionNamespace setVariable ["AE3_computer_session", objNull];

// The terminal and the desktop leave different running screens behind, so the one that is open decides
// which idle screen the laptop goes back to.
private _terminal = !isNull (findDisplay 15984);
private _texture = ["\z\ae3\addons\armaos\textures\Laptop_PowerOn.paa", "\z\ae3\addons\armaos\textures\Laptop_4_to_3_On.paa"] select _terminal;

// Closing the display runs its unload handler, which persists the filesystem and terminal state before
// the laptop is let go.
["ae3_armaos_forceCloseTerminal", [_computer]] call CBA_fnc_localEvent;
["ae3_desktop_forceCloseDesktop", [_computer]] call CBA_fnc_localEvent;

// The unload handlers release the laptop themselves, but a session can also be ended from outside a live
// display - a laptop being used from the inventory has no display of its own. Releasing again on the
// server is harmless and guarantees the claim never outlives the user who took it.
[_computer, _texture] remoteExecCall ["AE3_armaos_fnc_computer_release", 2];
