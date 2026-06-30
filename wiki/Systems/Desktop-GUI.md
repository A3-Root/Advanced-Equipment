# Desktop GUI

The Desktop GUI is the graphical operating system for AE3 laptops. It gives players windows, app icons, and familiar computer workflows.

## Built-In Apps

The desktop can include:

- Terminal: command line inside the desktop.
- Files: folder and file browsing.
- Settings: desktop and system settings.
- Notepad: text note workflow.
- Mail: inbox and message reading.
- Chat: network chat.
- Browser: mission webpages.
- Calendar: scheduled events.
- Map: map-focused information.
- CCTV: registered camera feeds.
- Music: audio playback.
- SysInfo: system and device information.

The exact apps available depend on the laptop configuration and mission setup.

## How Players Use It

Players open the laptop through ACE, choose the desktop action if available, log in if required, and use apps. The mission maker decides whether the desktop is the only interface or whether players can also use the terminal.

## Good GUI Mission Content

Use the GUI desktop for:

- Emails with sender/recipient context.
- Browser pages with readable clues.
- Browser history trails.
- Documents and folders.
- Images or audio/video evidence.
- Calendar schedules.
- CCTV feeds.

Avoid requiring terminal-only knowledge if a laptop is configured as GUI-only.

## Mission-Maker Setup

In 3DEN:

1. Set laptop Interface Mode to GUI or Both.
2. Add a user if login should be required.
3. Add desktop content modules such as Email, Webpage, Browser History, Media, Calendar Event, File, Directory, or Passworded File.
4. Sync each module to the laptop.
5. Preview and open the desktop as a player.

Script and addon app registration details are in [Desktop API](../Reference/Desktop-API.md) and [Extending Desktop GUI](../Developer/Extending-Desktop-GUI.md).
