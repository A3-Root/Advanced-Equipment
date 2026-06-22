/*
 * AE3 window manager. Smooth, in-sync dragging (document-level mousemove with start-offset,
 * mirrors os-master window.js but reskinned), focus/z-order, minimize/maximize/close, and
 * dock running-state integration. Windows are always bounds-clamped so they can never be lost
 * off-screen.
 */
(function () {
  var Z = 200;
  var openWindows = [];   // {id, el, app}
  var seq = 1;
  // Must match CSS --topbar-h / --dock-w (css/ubuntu.css). Read them from the CSS custom properties so
  // there is a single source of truth; fall back to the known defaults. Previously TOPBAR was 28 while
  // the CSS bar is 40px tall, so maximized windows were clipped under the top bar.
  function cssPx(name, dflt) {
    try {
      var v = parseInt(getComputedStyle(document.documentElement).getPropertyValue(name), 10);
      return (isFinite(v) && v > 0) ? v : dflt;
    } catch (e) { return dflt; }
  }
  var TOPBAR = cssPx("--topbar-h", 40), DOCK = cssPx("--dock-w", 64);
  var MIN_W = 240, MIN_H = 160;

  function clamp(win) {
    var maxX = window.innerWidth - 80;
    var maxY = window.innerHeight - 40;
    var minX = DOCK - win.el.offsetWidth + 80;
    var x = Math.min(maxX, Math.max(minX, win.el.offsetLeft));
    var y = Math.min(maxY, Math.max(TOPBAR, win.el.offsetTop));
    win.el.style.left = x + "px";
    win.el.style.top = y + "px";
  }

  function clampSize(win) {
    var maxW = Math.max(MIN_W, window.innerWidth - DOCK);
    var maxH = Math.max(MIN_H, window.innerHeight - TOPBAR);
    win.el.style.width = Math.min(maxW, Math.max(MIN_W, win.el.offsetWidth)) + "px";
    win.el.style.height = Math.min(maxH, Math.max(MIN_H, win.el.offsetHeight)) + "px";
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
      WM.onStateChange();
    });
  }

  function initResize(win, grip) {
    var resizing = false, sx = 0, sy = 0, ow = 0, oh = 0;
    grip.addEventListener("mousedown", function (e) {
      if (win.maximized) return;
      resizing = true; sx = e.clientX; sy = e.clientY;
      ow = win.el.offsetWidth; oh = win.el.offsetHeight;
      focus(win);
      e.preventDefault();
      e.stopPropagation();
    });
    document.addEventListener("mousemove", function (e) {
      if (!resizing) return;
      var maxW = window.innerWidth - win.el.offsetLeft;
      var maxH = window.innerHeight - win.el.offsetTop;
      win.el.style.width = Math.min(maxW, Math.max(MIN_W, ow + (e.clientX - sx))) + "px";
      win.el.style.height = Math.min(maxH, Math.max(MIN_H, oh + (e.clientY - sy))) + "px";
    });
    document.addEventListener("mouseup", function () {
      if (!resizing) return;
      resizing = false;
      clampSize(win);
      WM.onStateChange();
    });
  }

  function makeWindow(app, args) {
    var id = "win" + (seq++);
    var el = document.createElement("div");
    el.className = "window";
    // Never open larger than the viewport, so apps with generous defaults
    // can't spill past the screen edge and clip their toolbars.
    var w = Math.min(app.width || 560, window.innerWidth - DOCK - 8);
    var h = Math.min(app.height || 380, window.innerHeight - TOPBAR - 8);
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
      '<div class="window-body"></div>' +
      '<div class="resize-grip" title="Resize"></div>';

    var win = { id: id, el: el, app: app, args: args, maximized: false, prev: null };
    var tb = el.querySelector(".titlebar");
    var body = el.querySelector(".window-body");

    el.addEventListener("mousedown", function () { focus(win); });
    tb.querySelector(".close").addEventListener("click", function () { WM.close(win); });
    tb.querySelector(".min").addEventListener("click", function (e) {
      e.stopPropagation(); el.classList.add("minimized"); WM.onTaskbarChange(); WM.onStateChange();
    });
    tb.querySelector(".max").addEventListener("click", function (e) {
      e.stopPropagation(); toggleMax(win); WM.onStateChange();
    });

    initDrag(win, tb);
    initResize(win, el.querySelector(".resize-grip"));
    document.getElementById("screen").appendChild(el);
    openWindows.push(win);

    win.body = body;
    if (typeof app.render === "function") app.render(body, win, args);
    focus(win);
    WM.onTaskbarChange();
    WM.onStateChange();
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
      WM.onStateChange();
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

    // Per-window descriptors for the taskbar. Title is read live from the titlebar so apps
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
    onTaskbarChange: function () {},  // wired by desktop.js
    onStateChange: function () {},    // wired by desktop.js to persist the open-window layout

    // Serialize the open windows so the desktop can be restored exactly as left on reopen.
    snapshot: function () {
      return openWindows.map(function (w) {
        return {
          app: w.app.id, args: (w.args == null ? null : w.args),
          x: w.el.offsetLeft, y: w.el.offsetTop, w: w.el.offsetWidth, h: w.el.offsetHeight,
          min: w.el.classList.contains("minimized")
        };
      });
    },
    // Reopen windows from a snapshot, restoring geometry and minimized state.
    restoreState: function (list) {
      if (!list || !list.length || !window.Apps) return;
      list.forEach(function (s) {
        var app = Apps.get(s.app); if (!app) return;
        var win = WM.open(app, s.args || undefined);
        if (!win) return;
        if (s.x != null) {
          win.el.style.left = s.x + "px"; win.el.style.top = s.y + "px";
          if (s.w != null) win.el.style.width = s.w + "px";
          if (s.h != null) win.el.style.height = s.h + "px";
          clampSize(win);
          clamp(win);
        }
        if (s.min) { win.el.classList.add("minimized"); }
      });
      WM.onTaskbarChange();
    }
  };

  window.addEventListener("resize", function () { openWindows.forEach(function (w) { clampSize(w); clamp(w); }); });
  window.WM = WM;
})();
