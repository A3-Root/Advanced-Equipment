/* Desktop core */
PREP(desktop_open);
PREP(desktop_onUnload);
PREP(setInterfaceMode);
PREP(setInterfaceAccess);
PREP(canAccessInterface);

/* Window manager */
PREP(wm_createWindow);
PREP(wm_closeWindow);
PREP(wm_getTheme);

/* App framework */
PREP(app_list);
PREP(registerApp);
PREP(openFile);

/* Built-in apps */
PREP(app_terminal);
PREP(app_files);
PREP(app_settings);
PREP(app_notepad);
PREP(app_mail);
PREP(app_chat);
PREP(app_browser);
PREP(app_calendar);
PREP(app_map);
PREP(app_cctv);
PREP(app_music);
PREP(app_sysinfo);

/* Media + intel registries */
PREP(registerMedia);
PREP(registerWebpage);
PREP(addEmail);
PREP(addHistoryEntry);
PREP(addCalendarEvent);
PREP(registerCamera);
PREP(intel_dispatch);
PREP(addLockedFile);
PREP(promptUnlock);

/* Zeus/3DEN modules */
PREP(zeus_module_addIntel);
PREP(module_addIntel);
