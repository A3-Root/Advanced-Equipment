/*
 * Author: Root, Wasserstoff
 * Description: Writes output to the terminal display. Accepts string or array of strings/formatted text. This is the standard output function for all commands.
 *
 * Arguments:
 * 0: _computer <OBJECT> - The computer object
 * 1: _input <STRING or ARRAY> - The text to output
 *
 * Return Value:
 * None
 *
 * Example:
 * [_computer, "Hello World"] call AE3_armaos_fnc_shell_stdout;
 *
 * Public: Yes
 */
params['_computer', '_input'];

// Optional output redirect (e.g. SSH sessions route remote command output into the local
// terminal). Additive and backward compatible: unset means normal local output.
private _redirect = _computer getVariable ["AE3_stdoutRedirect", objNull];
if (!isNull _redirect) then
{
	_computer = _redirect;
};

if (!(_input isEqualType [])) then
{
	_input = [_input];
};

private _terminal = _computer getVariable "AE3_terminal";

// No-op when the terminal is not initialized (e.g. a GUI/desktop-only or headless server laptop that
// never opened a CLI shell). Without this, backend code that emits status text - such as Root
// Cyberwarfare's power-cost output during a GUI door action - drives the render pipeline against a
// non-array buffer and throws "count <Number>" in terminal_updateBufferVisible (Root_CW issue #2).
if (isNil "_terminal" || {!(_terminal isEqualType createHashMap)}) exitWith {};
if !((_terminal getOrDefault ["AE3_terminalBuffer", 0]) isEqualType []) exitWith {};

[_computer, _input] call AE3_armaos_fnc_terminal_addLines;
[_computer, _terminal get "AE3_terminalOutput"] call AE3_armaos_fnc_terminal_updateOutput;
