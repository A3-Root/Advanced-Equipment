// File: fnc_ipInSubnet.sqf
/**
 * Author: Root
 * Tests whether an IP belongs to a gateway's /24 subnet by comparing the first three octets. Used to
 * decide whether a configured default static address may be applied on a given router, or whether the
 * device should fall back to a DHCP lease from that router instead.
 *
 * Arguments:
 * 0: IP List <[INT]> - Candidate address (as returned by AE3_network_fnc_str2ip)
 * 1: Gateway List <[INT]> - Router's own address / gateway (its subnet)
 *
 * Returns:
 * 0: In subnet <BOOL> - true when both have at least three octets and octets 0..2 match
 */

params [["_ip", [], [[]]], ["_gateway", [], [[]]]];

if (count _ip < 3 || {count _gateway < 3}) exitWith { false };

(_ip select [0, 3]) isEqualTo (_gateway select [0, 3])
