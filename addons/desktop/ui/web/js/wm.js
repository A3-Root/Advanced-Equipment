/*
 * AE3 window manager. Smooth, in-sync dragging (document-level mousemove with start-offset,
 * mirrors os-master window.js but reskinned), focus/z-order, minimize/maximize/close, and
 * dock running-state integration. Windows are always bounds-clamped so they can never be lost
 * off-screen (fixes the old native-GUI drag desync / off-screen bug, issues #6 and #17).
 */
(function () {
  var Z = 200;
  var openWindows = [];   // {id, el, app}
  var seq = 1;
  var TOPBAR = 28, DOCK = 64;

  function clamp(win) {
    var maxX = window.innerWidth - 80;
    var maxY = window.innerHeight - 40;
    var minX = DOCK - win.el.offsetWidth + 80;
    var x = Math.min(maxX, Math.max(minX, win.el.offsetLeft));
    var y = Math.min(maxY, Math.max(TOPBAR, win.el.offsetTop));
    win.el.style.left = x + "px";
    win.el.style.top = y + "px";
  }

  function focus(win) {
    openWindows.forEach(function (w) { w.el.classList.remove("active"); });
    win.el.classList.add("active");
    win.el.style.zIndex = ++Z;
    WM.onTaskbarChange();
  }

  function initDrag(win, handle) {
    var dragging = false, sx = 0, sy = 0, ox = 0, oy = 0;
    handle.addEventListener("mousedown", function (e) {
      if (e.target.classList.contains("ctrl")) return;
      if (win.maximized) return;
      dragging = true; sx = e.clientX; sy = e.clientY;
      ox = win.el.offsetLeft; oy = win.el.offsetTop;
      handle.classList.add("dragging");
      focus(win);
      e.preventDefault();
    });
    document.addEventListener("mousemove", function (e) {
      if (!dragging) return;
      win.el.style.left = (ox + (e.clientX - sx)) + "px";
      win.el.style.top = (oy + (e.clientY - sy)) + "px";
    });
    document.addEventListener("mouseup", function () {
      if (!dragging) return;
      dragging = false; handle.classList.remove("dragging"); clamp(win);
    });
  }

  function makeWindow(app, args) {
    var id = "win" + (seq++);
    var el = document.createElement("div");
    el.className = "window";
    var w = app.width || 560, h = app.height || 380;
    el.style.width = w + "px"; el.style.height = h + "px";
    el.style.left = Math.max(DOCK + 20, (window.innerWidth - w) / 2 + (openWindows.length * 26) % 160) + "px";
    el.style.top = Math.max(TOPBAR + 20, (window.innerHeight - h) / 3 + (openWindows.length * 26) % 120) + "px";

    el.innerHTML =
      '<div class="titlebar">' +
        '<span class="glyph" style="margin-right:8px">' + (app.glyph || "") + '</span>' +
        '<span class="title">' + (app.title || "App") + '</span>' +
        '<span class="ctrls">' +
          '<button class="ctrl min" title="Minimize">&#8211;</button>' +
          '<button class="ctrl max" title="Maximize">&#9633;</button>' +
          '<button class="ctrl close" title="Close">&#10005;</button>' +
        '</span>' +
      '</div>' +
      '<div class="window-body"></div>';

    var win = { id: id, el: el, app: app, maximized: false, prev: null };
    var tb = el.querySelector(".titlebar");
    var body = el.querySelector(".window-body");

    el.addEventListener("mousedown", function () { focus(win); });
    tb.querySelector(".close").addEventListener("click", function () { WM.close(win); });
    tb.querySelector(".min").addEventListener("click", function (e) {
      e.stopPropagation(); el.classList.add("minimized"); WM.onTaskbarChange();
    });
    tb.querySelector(".max").addEventListener("click", function (e) {
      e.stopPropagation(); toggleMax(win);
    });

    initDrag(win, tb);
    document.getElementById("screen").appendChild(el);
    openWindows.push(win);

    win.body = body;
    if (typeof app.render === "function") app.render(body, win, args);
    focus(win);
    WM.onTaskbarChange();
    return win;
  }

  function toggleMax(win) {
    if (win.maximized) {
      Object.assign(win.el.style, win.prev);
      win.maximized = false;
    } else {
      win.prev = { left: win.el.style.left, top: win.el.style.top, width: win.el.style.width, height: win.el.style.height };
      win.el.style.left = DOCK + "px"; win.el.style.top = TOPBAR + "px";
      win.el.style.width = (window.innerWidth - DOCK) + "px";
      win.el.style.height = (window.innerHeight - TOPBAR) + "px";
      win.maximized = true;
    }
  }

  var WM = {
    open: function (app, args) {
      if (app.singleton) {
        var ex = openWindows.filter(function (w) { return w.app.id === app.id; })[0];
        if (ex) { ex.el.classList.remove("minimized"); focus(ex); return ex; }
      }
      return makeWindow(app, args);
    },
    close: function (win) {
      var i = openWindows.indexOf(win);
      if (i >= 0) openWindows.splice(i, 1);
      if (win.app && typeof win.app.onClose === "function") win.app.onClose(win);
      win.el.remove();
      WM.onTaskbarChange();
    },
    closeAll: function () {
      openWindows.slice().forEach(function (w) { WM.close(w); });
    },
    restoreOrFocus: function (appId) {
      var ex = openWindows.filter(function (w) { return w.app.id === appId; })[0];
      if (ex) { ex.el.classList.remove("minimized"); focus(ex); return true; }
      return false;
    },
    running: function () { return openWindows.map(function (w) { return w.app.id; }); },

    // Per-window descriptors for the taskbar (#11). Title is read live from the titlebar so apps
    // that rename their window (browser, notepad) show the current document.
    list: function () {
      return openWindows.map(function (w) {
        var t = w.el.querySelector(".title");
        return {
          id: w.id, appId: w.app.id, glyph: w.app.glyph || "",
          title: (t && t.textContent) || w.app.title || "App",
          minimized: w.el.classList.contains("minimized"),
          active: w.el.classList.contains("active") && !w.el.classList.contains("minimized")
        };
      });
    },
    byId: function (id) { return openWindows.filter(function (w) { return w.id === id; })[0]; },
    // Taskbar click: restore+focus if minimized, minimize if already active, else just focus.
    toggle: function (id) {
      var w = WM.byId(id); if (!w) return;
      if (w.el.classList.contains("minimized")) { w.el.classList.remove("minimized"); focus(w); return; }
      if (w.el.classList.contains("active")) { w.el.classList.add("minimized"); WM.onTaskbarChange(); return; }
      focus(w);
    },
    onTaskbarChange: function () {}   // wired by desktop.js
  };

  window.addEventListener("resize", function () { openWindows.forEach(clamp); });
  window.WM = WM;
})();
