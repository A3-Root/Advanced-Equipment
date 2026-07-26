// File: XEH_postInit.sqf
#include "script_component.hpp"

/* ================================================================================ */
/* Client: end a laptop session the operator can no longer be in                    */
/*                                                                                  */
/* A terminal or desktop is opened by a player standing at the machine, and the      */
/* claim on it is held by that player object. Nothing used to end the session when   */
/* the player stopped being able to use the machine, so the screen kept running      */
/* through unconsciousness and death, and a respawn left the laptop claimed by a     */
/* unit that no longer exists - hiding every interaction on it from everyone.        */

if (!hasInterface) exitWith {};

// ACE medical: the operator is put under (or brought back). Going under ends the session; waking does
// not reopen it, the laptop has to be picked back up like any other.
["ace_unconscious", {
	params ["_unit", ["_state", false]];
	if (_unit isNotEqualTo player || {!_state}) exitWith {};

	call AE3_armaos_fnc_computer_endSession;
}] call CBA_fnc_addEventHandler;

// A respawn hands this client a different unit, so whatever the last one was using is now unattended and
// the claim it left behind belongs to a body.
["unit", {
	call AE3_armaos_fnc_computer_endSession;
}] call CBA_fnc_addPlayerEventHandler;

// Death and the vanilla revive state raise no event of their own, so an open session is watched: it costs
// nothing while no laptop is in use, and it also catches an ACE-less mission where the medical event above
// never fires.
[{
	private _computer = missionNamespace getVariable ["AE3_computer_session", objNull];
	if (isNull _computer) exitWith {};

	if (!alive player
		|| {(lifeState player) isEqualTo "INCAPACITATED"}
		|| {player getVariable ["ACE_isUnconscious", false]}
	) then {
		call AE3_armaos_fnc_computer_endSession;
	};
}, 1, []] call CBA_fnc_addPerFrameHandler;
