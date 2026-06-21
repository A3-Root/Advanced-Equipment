/*
 * AE3 desktop shell: top bar (Applications menu, taskbar, centred clock, tray), left dock, fixed
 * desktop icons, app registry. Apps register via Apps.register({id, title, glyph, render, ...}); the
 * shell renders the launcher menu + taskbar + desktop and routes launches through the window manager.
 */
(function () {
  var registry = [];

  var Apps = {
    register: function (app) { registry.push(app); },
    all: function () { return registry; },
    get: function (id) { return registry.filter(function (a) { return a.id === id; })[0]; },
    launch: function (id, args) {
      var app = Apps.get(id);
      if (app) return WM.open(app, args);
    }
  };

  // Applications-menu category for built-in apps (#8). Ext apps (Root Cyberwarfare) carry their own
  // app.menu (a "Parent/Child" path). "/" nests submenus. Apps absent here fall back to "Other".
  var CATEGORY = {
    files: "System", settings: "System", network: "System",
    notepad: "Accessories", recyclebin: "System",
    calendar: "Office", mail: "Office",
    browser: "Internet", map: "Internet",
    messenger: "Communication",
    crack: "Cryptography", crypto: "Cryptography",
    snake: "Games"
  };

  // The desktop surface holds only these three icons (#18); everything else lives in the
  // Applications menu. "My Computer" and "File Explorer" are two entry points into the Files app.
  var DESKTOP_ICONS = [
    { label: "My Computer", glyph: function () { return Icons.files; }, app: "files", args: { path: "/" } },
    { label: "File Explorer", glyph: function () { return Icons.files; }, app: "files", args: { path: "/home" } },
    { label: "Recycle Bin", glyph: function () { return Icons.trash || Icons.files; }, app: "recyclebin" }
  ];

  function el(tag, cls, html) {
    var e = document.createElement(tag);
    if (cls) e.className = cls;
    if (html != null) e.innerHTML = html;
    return e;
  }

  // ---------------- Reusable right-click context menu (#16) ----------------
  // items: array of { label, action, disabled } or { sep:true }. Shared by the desktop surface and
  // the Files app. window.AE3_clipboard holds the pending cut/copy ({ path, name, op }).
  window.AE3_clipboard = null;
  window.AE3_ctxMenu = function (x, y, items) {
    var ex = document.getElementById("ctxmenu"); if (ex) ex.remove();
    var m = el("div", "ctx-menu"); m.id = "ctxmenu";
    items.forEach(function (it) {
      if (it.sep) { m.appendChild(el("div", "ctx-sep")); return; }
      var row = el("div", "ctx-item" + (it.disabled ? " disabled" : ""), it.label);
      if (!it.disabled) row.addEventListener("click", function () { m.remove(); it.action(); });
      m.appendChild(row);
    });
    document.body.appendChild(m);
    // Keep the menu on-screen.
    var r = m.getBoundingClientRect();
    m.style.left = Math.min(x, window.innerWidth - r.width - 4) + "px";
    m.style.top = Math.min(y, window.innerHeight - r.height - 4) + "px";
    setTimeout(function () {
      document.addEventListener("mousedown", function close(ev) {
        if (!m.contains(ev.target)) { m.remove(); document.removeEventListener("mousedown", close); }
      });
    }, 0);
  };

  // ---------------- Left dock (quick launch) ----------------
  function buildDock() {
    var dock = document.getElementById("dock");
    dock.innerHTML = "";
    registry.filter(function (a) { return a.showInDock; }).forEach(function (app) {
      var item = el("div", "dock-item", '<span>' + (app.glyph || "") + '</span><span class="tip">' + app.title + "</span>");
      item.dataset.app = app.id;
      item.addEventListener("click", function () { Apps.launch(app.id); });
      dock.appendChild(item);
    });
  }

  // ---------------- Desktop icons (fixed three) ----------------
  function buildDesktopIcons() {
    var desk = document.getElementById("desktop");
    desk.innerHTML = "";
    DESKTOP_ICONS.forEach(function (d) {
      if (!Apps.get(d.app)) return; // skip if the backing app is not present (e.g. recyclebin disabled)
      var glyph = (typeof d.glyph === "function") ? d.glyph() : d.glyph;
      var icon = el("div", "desktop-icon", '<div class="glyph">' + (glyph || "") + '</div><div class="label">' + d.label + "</div>");
      icon.addEventListener("dblclick", function () { Apps.launch(d.app, d.args); });
      icon.addEventListener("click", function () {
        desk.querySelectorAll(".desktop-icon").forEach(function (n) { n.classList.remove("sel"); });
        icon.classList.add("sel");
      });
      desk.appendChild(icon);
    });
    desk.addEventListener("mousedown", function (e) {
      if (e.target === desk) desk.querySelectorAll(".desktop-icon").forEach(function (n) { n.classList.remove("sel"); });
    });
    // Desktop right-click (#16): file actions live in the Files app, which has a real working dir,
    // so the desktop menu opens it (optionally creating an item first) plus quick shortcuts.
    if (!desk.dataset.ctx) {
      desk.dataset.ctx = "1";
      desk.addEventListener("contextmenu", function (e) {
        e.preventDefault();
        window.AE3_ctxMenu(e.clientX, e.clientY, [
          { label: "New Folder…", action: function () {
            Modal.prompt("New folder name", "untitled").then(function (name) {
              if (!name) return;
              A3.request("fs_mkdir", { path: "/home/" + name }).then(function () { Apps.launch("files", { path: "/home" }); });
            });
          } },
          { label: "New File…", action: function () {
            Modal.prompt("New file name", "untitled.txt").then(function (name) {
              if (!name) return;
              A3.request("fs_save", { path: "/home/" + name, content: "" }).then(function () { Apps.launch("files", { path: "/home" }); });
            });
          } },
          { sep: true },
          { label: "Open File Explorer", action: function () { Apps.launch("files", { path: "/home" }); } },
          { label: "Open Recycle Bin", action: function () { Apps.launch("recyclebin"); } },
          { label: "Refresh", action: function () { Desktop.refresh(); } }
        ]);
      });
    }
  }

  // ---------------- Applications menu (#8) ----------------
  function menuTree() {
    // Build {category -> {sub -> [apps]} | [apps]} from the registry. app.menu overrides CATEGORY.
    var tree = {};
    registry.filter(function (a) { return a.showInMenu !== false; }).forEach(function (app) {
      var path = String(app.menu || CATEGORY[app.id] || "Other").split("/");
      var cat = path[0], sub = path[1];
      tree[cat] = tree[cat] || { _apps: [], _subs: {} };
      if (sub) { (tree[cat]._subs[sub] = tree[cat]._subs[sub] || []).push(app); }
      else { tree[cat]._apps.push(app); }
    });
    return tree;
  }

  function closeAppsMenu() {
    var m = document.getElementById("appsmenu");
    if (m) m.classList.remove("show");
    var b = document.querySelector("#topbar .appsbtn");
    if (b) b.classList.remove("active");
  }

  function itemRow(app) {
    var row = el("div", "am-item", '<span class="am-ico">' + (app.glyph || "") + '</span><span>' + app.title + "</span>");
    row.addEventListener("click", function (e) { e.stopPropagation(); closeAppsMenu(); Apps.launch(app.id); });
    return row;
  }

  function buildAppsMenu() {
    var menu = document.getElementById("appsmenu");
    if (!menu) return;
    menu.innerHTML = "";
    var tree = menuTree();
    Object.keys(tree).sort().forEach(function (cat) {
      var node = tree[cat];
      var subNames = Object.keys(node._subs);
      // Leaf category: a single app and no submenus -> show the app directly (e.g. "Notepad").
      if (node._apps.length === 1 && subNames.length === 0) { menu.appendChild(itemRow(node._apps[0])); return; }
      // Category with one app and no subs already handled; otherwise render a submenu fly-out.
      var catRow = el("div", "am-item am-cat", '<span class="am-ico">&#128193;</span><span style="flex:1">' + cat + '</span><span class="am-arrow">&#9656;</span>');
      var fly = el("div", "am-fly");
      subNames.sort().forEach(function (sub) {
        var subRow = el("div", "am-item am-cat", '<span class="am-ico">&#128193;</span><span style="flex:1">' + sub + '</span><span class="am-arrow">&#9656;</span>');
        var subFly = el("div", "am-fly");
        node._subs[sub].forEach(function (app) { subFly.appendChild(itemRow(app)); });
        subRow.appendChild(subFly);
        fly.appendChild(subRow);
      });
      node._apps.forEach(function (app) { fly.appendChild(itemRow(app)); });
      catRow.appendChild(fly);
      menu.appendChild(catRow);
    });
  }

  function bindAppsButton() {
    var btn = document.querySelector("#topbar .appsbtn");
    if (!btn || btn.dataset.bound) return;
    btn.dataset.bound = "1";
    btn.addEventListener("click", function (e) {
      e.stopPropagation();
      var menu = document.getElementById("appsmenu");
      var open = menu.classList.toggle("show");
      btn.classList.toggle("active", open);
      if (open) {
        buildAppsMenu();
        setTimeout(function () {
          document.addEventListener("mousedown", function close(ev) {
            if (!menu.contains(ev.target) && ev.target !== btn) { closeAppsMenu(); document.removeEventListener("mousedown", close); }
          });
        }, 0);
      }
    });
  }

  // ---------------- Taskbar (#11) ----------------
  function buildTaskbar() {
    var bar = document.getElementById("tasks");
    if (!bar) return;
    bar.innerHTML = "";
    WM.list().forEach(function (w) {
      var t = el("div", "task" + (w.active ? " active" : "") + (w.minimized ? " min" : ""),
        '<span class="task-ico">' + (w.glyph || "") + '</span><span class="task-label">' + w.title + "</span>");
      t.title = w.title;
      t.addEventListener("click", function () { WM.toggle(w.id); });
      bar.appendChild(t);
    });
  }

  function refreshDockRunning() {
    var running = WM.running();
    document.querySelectorAll("#dock .dock-item").forEach(function (n) {
      n.classList.toggle("running", running.indexOf(n.dataset.app) >= 0);
    });
  }

  function onTaskbarChange() { refreshDockRunning(); buildTaskbar(); }

  // ---------------- Clock (#10): centred, date + time, click opens Calendar ----------------
  var clockTimer = null, batteryTimer = null;
  function startClock() {
    function tick() {
      var d = new Date();
      var time = d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
      var date = d.toLocaleDateString([], { weekday: "short", month: "short", day: "numeric" });
      var c = document.getElementById("clock");
      if (c) c.textContent = date + "  " + time;
    }
    if (clockTimer) clearInterval(clockTimer);
    clockTimer = setInterval(tick, 1000); tick();
    var c = document.getElementById("clock");
    if (c && !c.dataset.bound) { c.dataset.bound = "1"; c.addEventListener("click", function () { Apps.launch("calendar"); }); }
  }

  // ---------------- Tray: battery (#12), wifi (#13), power (#8) ----------------
  function popover(id, anchorRight, html) {
    var ex = document.getElementById(id);
    if (ex) { ex.remove(); return null; }
    var m = el("div", "tray-pop", html); m.id = id;
    m.style.right = anchorRight + "px";
    document.body.appendChild(m);
    setTimeout(function () {
      document.addEventListener("mousedown", function close(ev) {
        if (!m.contains(ev.target)) { m.remove(); document.removeEventListener("mousedown", close); }
      });
    }, 0);
    return m;
  }

  var lastSys = {};
  function buildTray() {
    var tray = document.querySelector("#topbar .tray");
    if (!tray || !window.Icons) return;
    tray.innerHTML =
      '<span class="tray-ico wifi" title="Network">' + Icons.wifi + '</span>' +
      '<span class="tray-ico battery" title="Battery">' + Icons.battery + ' <span class="batpct">--</span></span>' +
      '<span class="tray-ico powerbtn" title="Power">' + Icons.power + '</span>';

    var pct = tray.querySelector(".batpct");
    function poll() {
      A3.request("sysinfo", {}).then(function (s) {
        s = s || {}; lastSys = s;
        if (pct) pct.textContent = (s.battery != null && s.battery >= 0) ? (s.battery + "%") : "--";
        var bat = tray.querySelector(".battery");
        if (bat) {
          var low = (s.battery != null && s.battery >= 0 && s.battery <= 15);
          bat.style.color = low ? "#e9542d" : "";
        }
      }).catch(function () {});
    }
    if (batteryTimer) clearInterval(batteryTimer);
    batteryTimer = setInterval(poll, 5000); poll();

    // Battery popover (#12): charge, power state, capacity.
    tray.querySelector(".battery").addEventListener("click", function (e) {
      e.stopPropagation();
      var s = lastSys || {};
      popover("batterypop", 64,
        '<div class="tp-h">Battery</div>' +
        '<div class="tp-r">Charge: <b>' + ((s.battery != null && s.battery >= 0) ? s.battery + "%" : "?") + '</b></div>' +
        '<div class="tp-r">Power: <b>' + (s.power || "?") + '</b></div>' +
        '<div class="tp-r">Uptime: ' + (s.uptime || "?") + '</div>');
    });

    // Wifi opens the Network app (#13).
    tray.querySelector(".wifi").addEventListener("click", function (e) { e.stopPropagation(); Apps.launch("network"); });

    // Power menu (#8): Sign out / Shut down.
    tray.querySelector(".powerbtn").addEventListener("click", function (e) {
      e.stopPropagation();
      var m = popover("powermenu", 6,
        '<div class="pm-item signout">Sign out</div><div class="pm-item shutdown">Shut down</div>');
      if (!m) return;
      m.querySelector(".signout").addEventListener("click", function () { m.remove(); Desktop.signOut(); });
      m.querySelector(".shutdown").addEventListener("click", function () { m.remove(); A3.send("shutdown", {}); });
    });
  }

  var Desktop = {
    init: function () {
      WM.onTaskbarChange = onTaskbarChange;
      buildTray();
      buildDock();
      buildDesktopIcons();
      bindAppsButton();
      startClock();
      buildTaskbar();
    },
    setHostname: function (name) {
      var h = document.getElementById("hostname");
      if (h) h.textContent = name || "ae3-os";
    },
    // Wallpaper (#15): CSS background applied to #wallpaper (url or gradient/colour string).
    setWallpaper: function (val) {
      var w = document.getElementById("wallpaper");
      if (!w || !val) return;
      w.style.background = (/^https?:|^data:|\\|\//.test(val)) ? ("center/cover no-repeat url('" + val + "')") : val;
    },
    signOut: function () {
      if (window.WM && WM.closeAll) WM.closeAll();
      A3.send("signout", {});
      if (typeof window.AE3_showLogin === "function") window.AE3_showLogin();
    },
    refresh: function () { buildDock(); buildDesktopIcons(); onTaskbarChange(); }
  };

  window.Apps = Apps;
  window.Desktop = Desktop;
})();
