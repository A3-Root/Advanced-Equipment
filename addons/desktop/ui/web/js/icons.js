/*
 * AE3 desktop inline SVG icon set (Ubuntu/Yaru-flavoured line icons). No .paa assets: icons are
 * SVG strings sized in `em` so they inherit the font-size set by CSS and `currentColor` so the
 * theme controls their colour. Apps reference these via their `glyph` field; the shell injects
 * them as innerHTML. window.Icons is global (loaded before desktop.js/apps.js).
 */
(function () {
  function svg(inner, opts) {
    opts = opts || {};
    var fill = opts.fill || "none";
    var sw = opts.sw || 1.8;
    return '<svg viewBox="0 0 24 24" width="1em" height="1em" fill="' + fill +
      '" stroke="currentColor" stroke-width="' + sw +
      '" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + inner + '</svg>';
  }

  var Icons = {
    files:    svg('<path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>'),
    folder:   svg('<path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>'),
    file:     svg('<path d="M7 3h7l5 5v13a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1z"/><path d="M14 3v5h5"/>'),
    notepad:  svg('<path d="M5 4h11l3 3v13a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1z"/><path d="M8 9h8M8 13h8M8 17h5"/>'),
    settings: svg('<circle cx="12" cy="12" r="3"/><path d="M19 12a7 7 0 0 0-.1-1l2-1.6-2-3.4-2.3 1a7 7 0 0 0-1.7-1l-.3-2.5h-4l-.3 2.5a7 7 0 0 0-1.7 1l-2.3-1-2 3.4 2 1.6a7 7 0 0 0 0 2l-2 1.6 2 3.4 2.3-1a7 7 0 0 0 1.7 1l.3 2.5h4l.3-2.5a7 7 0 0 0 1.7-1l2.3 1 2-3.4-2-1.6a7 7 0 0 0 .1-1z"/>'),
    network:  svg('<path d="M2 8.5a16 16 0 0 1 20 0M5 12a11 11 0 0 1 14 0M8.5 15.5a6 6 0 0 1 7 0"/><circle cx="12" cy="19" r="1" fill="currentColor" stroke="none"/>'),
    calendar: svg('<rect x="3.5" y="5" width="17" height="15" rx="2"/><path d="M3.5 9.5h17M8 3v4M16 3v4"/>'),
    browser:  svg('<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c2.6 2.4 4 5.6 4 9s-1.4 6.6-4 9c-2.6-2.4-4-5.6-4-9s1.4-6.6 4-9z"/>'),
    map:      svg('<path d="M9 4 3.5 6v14L9 18l6 2 5.5-2V4L15 6 9 4z"/><path d="M9 4v14M15 6v14"/>'),
    mail:     svg('<rect x="3" y="5.5" width="18" height="13" rx="2"/><path d="m4 7 8 6 8-6"/>'),
    messenger:svg('<path d="M4 5h16a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H9l-4 4v-4H4a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1z"/>'),
    about:    svg('<circle cx="12" cy="12" r="9"/><path d="M12 11v5"/><circle cx="12" cy="8" r="1" fill="currentColor" stroke="none"/>'),
    terminal: svg('<rect x="3" y="4.5" width="18" height="15" rx="2"/><path d="m7 9 3 3-3 3M13 15h4"/>'),
    user:     svg('<circle cx="12" cy="8" r="4"/><path d="M4 20a8 8 0 0 1 16 0"/>'),
    power:    svg('<path d="M12 3v9" /><path d="M7.5 6.5a7 7 0 1 0 9 0"/>'),
    battery:  svg('<rect x="2.5" y="8" width="16" height="8" rx="1.5"/><path d="M20.5 11v2"/><rect x="4.5" y="10" width="9" height="4" fill="currentColor" stroke="none"/>'),
    wifi:     svg('<path d="M2 8.5a16 16 0 0 1 20 0M5 12a11 11 0 0 1 14 0M8.5 15.5a6 6 0 0 1 7 0"/><circle cx="12" cy="19" r="1" fill="currentColor" stroke="none"/>'),
    device:   svg('<rect x="3" y="4" width="18" height="12" rx="2"/><path d="M8 20h8M12 16v4"/>'),
    door:     svg('<rect x="5" y="3" width="14" height="18" rx="1"/><circle cx="15.5" cy="12" r="1" fill="currentColor" stroke="none"/>'),
    light:    svg('<path d="M9 18h6M10 21h4"/><path d="M12 3a6 6 0 0 1 4 10.5c-.7.7-1 1.2-1 2.5H9c0-1.3-.3-1.8-1-2.5A6 6 0 0 1 12 3z"/>'),
    drone:    svg('<circle cx="6" cy="6" r="2"/><circle cx="18" cy="6" r="2"/><circle cx="6" cy="18" r="2"/><circle cx="18" cy="18" r="2"/><rect x="9.5" y="9.5" width="5" height="5" rx="1"/><path d="M7.5 7.5 10 10M16.5 7.5 14 10M7.5 16.5 10 14M16.5 16.5 14 14"/>'),
    vehicle:  svg('<path d="M3 13l2-5h11l3 5M3 13h17v4H3z"/><circle cx="7" cy="17" r="1.6"/><circle cx="16" cy="17" r="1.6"/>'),
    gps:      svg('<path d="M12 21s7-6.3 7-11a7 7 0 1 0-14 0c0 4.7 7 11 7 11z"/><circle cx="12" cy="10" r="2.5"/>'),
    database: svg('<ellipse cx="12" cy="5.5" rx="7" ry="2.5"/><path d="M5 5.5v6c0 1.4 3.1 2.5 7 2.5s7-1.1 7-2.5v-6M5 11.5v6c0 1.4 3.1 2.5 7 2.5s7-1.1 7-2.5v-6"/>')
  };

  // Convenience: return a named icon, or a fallback dot, never undefined.
  Icons.get = function (name) { return (name && Icons[name]) || Icons.about; };

  window.Icons = Icons;
})();
