/* Actions */


/* Init */
PREP(initNetworkDevice);
PREP(initRouter);
PREP(router_onTurnOff);
PREP(applyRouterConfig);
PREP(attr_router);
PREP(router_openConfig);
PREP(router_applyConfigDialog);

/* Backend */
PREP(connect_router2router);
PREP(connect_device2router);
PREP(connect_isCyclic);
PREP(disconnect);

PREP(ping);

PREP(dhcp_get);
PREP(dhcp_refresh);
PREP(dhcp_onTurnOn);

/* Generic */
PREP(ip2str);
PREP(str2ip);

/* Connections */
PREP(createNetworkConnection);
PREP(removeNetworkConnection);
