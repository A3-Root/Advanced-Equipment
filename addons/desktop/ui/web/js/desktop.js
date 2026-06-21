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
  // app.menu (a "Parent/Child" path under "Tools"). "/" nests submenus. Apps absent here fall back to
  // "Other". CATEGORY_ORDER fixes the category sequence; APP_ORDER fixes the within-category order.
  var CATEGORY = {
    settings: "System & Core Utilities", network: "System & Core Utilities", about: "System & Core Utilities",
    mycomputer: "System & Core Utilities", ssh: "System & Core Utilities",
    notepad: "Productivity & Files", calculator: "Productivity & Files", calendar: "Productivity & Files",
    files: "Productivity & Files", recyclebin: "Productivity & Files",
    browser: "Communication & Web", mail: "Communication & Web", messenger: "Communication & Web", map: "Communication & Web",
    snake: "Games & Entertainment",
    crypto: "Security", crack: "Security"
  };
  var CATEGORY_ORDER = ["System & Core Utilities", "Productivity & Files", "Communication & Web", "Games & Entertainment", "Security", "Tools"];
  var APP_ORDER = ["settings", "network", "about", "mycomputer", "ssh",
    "notepad", "calculator", "calendar", "files", "recyclebin",
    "browser", "mail", "messenger", "map", "snake", "crypto", "crack"];
  function appRank(app) { var i = APP_ORDER.indexOf(app.id); return i < 0 ? 999 : i; }

  // Fixed system icons that always sit on the desktop (like Ubuntu's Home/Trash). "My Computer" is
  // the computer-management app (#11); "File Explorer" opens the plain Files browser; Recycle Bin
  // opens the trash. Everything else on the desktop is loaded dynamically from the user's
  // ~/Desktop folder (#9) by loadUserDesktop().
  var DESKTOP_ICONS = [
    { label: "My Computer", glyph: function () { return Icons.computer || Icons.files; }, app: "mycomputer" },
    { label: "File Explorer", glyph: function () { return Icons.files; }, app: "files", args: { path: "/home" } },
    { label: "Recycle Bin", glyph: function () { return Icons.trash || Icons.files; }, app: "recyclebin" }
  ];
  // Resolved on login from sysinfo (#9). The desktop surface mirrors this folder.
  window.AE3_HOME = null;

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

  // ---------------- Desktop icons (fixed system + dynamic ~/Desktop, #9) ----------------
  function makeIcon(desk, label, glyph, onOpen) {
    var icon = el("div", "desktop-icon", '<div class="glyph">' + (glyph || "") + '</div><div class="label">' + label + "</div>");
    icon.addEventListener("dblclick", onOpen);
    icon.addEventListener("click", function () {
      desk.querySelectorAll(".desktop-icon").forEach(function (n) { n.classList.remove("sel"); });
      icon.classList.add("sel");
    });
    desk.appendChild(icon);
    return icon;
  }

  // Load and render the logged-in user's ~/Desktop folder. Launchers (.app, holding "app=<id>")
  // launch the app; folders open Files there; files open in the default viewer; symlinks follow
  // their target. Mirrors a real Ubuntu/Debian desktop (#9).
  function loadUserDesktop(desk) {
    var home = window.AE3_HOME;
    if (!home) return;
    var path = home + "/Desktop";
    A3.request("fs_list", { path: path }).then(function (res) {
      if (!res || (res.error && res.error !== "")) return;
      (res.entries || []).forEach(function (it) {
        var full = (path + "/" + it.name).replace(/\/+/g, "/");
        var glyph = it.dir ? Icons.folder : (/\.app$/i.test(it.name) ? (Icons.app || Icons.terminal) : Icons.file);
        makeIcon(desk, it.name.replace(/\.app$/i, ""), glyph, function () { openDesktopEntry(it, full); });
      });
    }).catch(function () {});
  }

  function openDesktopEntry(it, full) {
    if (it.dir) { Apps.launch("files", { path: (it.link && it.link !== "") ? it.link : full }); return; }
    if (/\.app$/i.test(it.name)) {
      A3.request("fs_read", { path: full }).then(function (res) {
        var m = String((res && res.content) || "").match(/app\s*=\s*([\w-]+)/i);
        if (m) Apps.launch(m[1]); else Apps.launch("notepad", { path: full, content: (res && res.content) || "" });
      });
      return;
    }
    A3.request("fs_read", { path: (it.link && it.link !== "") ? it.link : full }).then(function (res) {
      if (res && !res.error) Apps.launch("notepad", { path: full, content: res.content || "" });
    });
  }

  function buildDesktopIcons() {
    var desk = document.getElementById("desktop");
    desk.innerHTML = "";
    DESKTOP_ICONS.forEach(function (d) {
      if (!Apps.get(d.app)) return; // skip if the backing app is not present (e.g. recyclebin disabled)
      var glyph = (typeof d.glyph === "function") ? d.glyph() : d.glyph;
      makeIcon(desk, d.label, glyph, function () { Apps.launch(d.app, d.args); });
    });
    loadUserDesktop(desk);
    desk.addEventListener("mousedown", function (e) {
      if (e.target === desk) desk.querySelectorAll(".desktop-icon").forEach(function (n) { n.classList.remove("sel"); });
    });
    // Desktop right-click (#9/#16): create items directly in the user's ~/Desktop folder so they
    // appear on the desktop surface, like a real Ubuntu/Debian desktop.
    if (!desk.dataset.ctx) {
      desk.dataset.ctx = "1";
      desk.addEventListener("contextmenu", function (e) {
        if (e.target !== desk && !e.target.closest("#desktop")) return;
        if (e.target.closest(".desktop-icon")) return; // icons would carry their own menu
        e.preventDefault();
        var deskPath = (window.AE3_HOME || "/root") + "/Desktop";
        window.AE3_ctxMenu(e.clientX, e.clientY, [
          { label: "New Folder…", action: function () {
            Modal.prompt("New folder name", "untitled").then(function (name) {
              if (!name) return;
              A3.request("fs_mkdir", { path: deskPath + "/" + name }).then(function () { Desktop.refresh(); });
            });
          } },
          { label: "New File…", action: function () {
            Modal.prompt("New file name", "untitled.txt").then(function (name) {
              if (!name) return;
              A3.request("fs_save", { path: deskPath + "/" + name, content: "" }).then(function () { Desktop.refresh(); });
            });
          } },
          { sep: true },
          { label: "Open File Explorer", action: function () { Apps.launch("files", { path: deskPath }); } },
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
    // Fixed category sequence (#8); any unexpected categories follow, alphabetically.
    var cats = CATEGORY_ORDER.filter(function (c) { return tree[c]; })
      .concat(Object.keys(tree).filter(function (c) { return CATEGORY_ORDER.indexOf(c) < 0; }).sort());
    cats.forEach(function (cat) {
      var node = tree[cat];
      var subNames = Object.keys(node._subs);
      node._apps.sort(function (a, b) { return appRank(a) - appRank(b); });
      // Leaf category: a single app and no submenus -> show the app directly.
      if (node._apps.length === 1 && subNames.length === 0) { menu.appendChild(itemRow(node._apps[0])); return; }
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

  // ---------------- Global search (#14) ----------------
  // Searches installed apps, files/folders (recursive fs_search from /), the Recycle Bin, and
  // wireless network names. Mail and Messenger are intentionally excluded (they have their own
  // in-app search). Debounced; results render in a dropdown under the search box.
  function bindGlobalSearch() {
    var input = document.getElementById("globalsearch");
    var box = document.getElementById("gsresults");
    if (!input || !box || input.dataset.bound) return;
    input.dataset.bound = "1";
    var timer = null;

    function hide() { box.classList.remove("show"); box.innerHTML = ""; }
    function addRow(icon, label, sub, action) {
      var r = el("div", "gs-row", '<span class="gs-ico">' + (icon || "") + '</span><span class="gs-l">' + label +
        (sub ? '<span class="gs-sub">' + sub + '</span>' : "") + "</span>");
      r.addEventListener("mousedown", function (e) { e.preventDefault(); hide(); input.value = ""; action(); });
      box.appendChild(r);
    }
    function esc(s) { return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;"); }

    function run(q) {
      box.innerHTML = ""; box.classList.add("show");
      var ql = q.toLowerCase();
      // Apps (registry).
      registry.filter(function (a) { return a.showInMenu !== false && a.title.toLowerCase().indexOf(ql) >= 0; })
        .slice(0, 6).forEach(function (a) {
          addRow(a.glyph || "", esc(a.title), "App", function () { Apps.launch(a.id); });
        });
      // Networks.
      A3.request("net_scan", {}).then(function (list) {
        (list || []).filter(function (n) { return (n.ssid || "").toLowerCase().indexOf(ql) >= 0; })
          .slice(0, 5).forEach(function (n) {
            addRow(Icons.wifi, esc(n.ssid), "Network", function () { Apps.launch("network"); });
          });
      }).catch(function () {});
      // Files/folders (recursive) + Recycle Bin.
      A3.request("fs_search", { query: q, root: "/" }).then(function (res) {
        var hits = (res && res.results) || [];
        hits.slice(0, 12).forEach(function (it) {
          var name = it.path.split("/").pop();
          var inTrash = it.path.indexOf("/.trash/") === 0;
          addRow(it.dir ? Icons.folder : Icons.file, esc(name), inTrash ? "Recycle Bin" : esc(it.path), function () {
            if (inTrash) { Apps.launch("recyclebin"); }
            else if (it.dir) { Apps.launch("files", { path: it.path }); }
            else { Apps.launch("files", { path: it.path.replace(/\/[^/]*$/, "") || "/" }); }
          });
        });
        if (!box.children.length) box.innerHTML = '<div class="gs-row muted">No results</div>';
      }).catch(function () {});
    }

    input.addEventListener("input", function () {
      var q = input.value.trim();
      if (timer) clearTimeout(timer);
      if (q === "") { hide(); return; }
      timer = setTimeout(function () { run(q); }, 250);
    });
    input.addEventListener("blur", function () { setTimeout(hide, 150); });
    input.addEventListener("keydown", function (e) { if (e.key === "Escape") { hide(); input.value = ""; } });
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

  // Open-window layout persistence (#17): debounce-save the WM snapshot to the laptop so reopening
  // resumes exactly where it was left. Suppressed while restoring to avoid feedback churn.
  var uiSaveTimer = null, uiRestoring = false;
  function bindUiPersist() {
    WM.onStateChange = function () {
      if (uiRestoring) return;
      if (uiSaveTimer) clearTimeout(uiSaveTimer);
      uiSaveTimer = setTimeout(function () { A3.send("ui_save", { state: WM.snapshot() }); }, 600);
    };
  }

  var Desktop = {
    init: function () {
      WM.onTaskbarChange = onTaskbarChange;
      bindUiPersist();
      buildTray();
      buildDock();
      buildDesktopIcons();
      bindAppsButton();
      bindGlobalSearch();
      startClock();
      buildTaskbar();
    },
    setHostname: function (name) {
      var h = document.getElementById("hostname");
      if (h) h.textContent = name || "armaOS";
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
    refresh: function () { buildDock(); buildDesktopIcons(); onTaskbarChange(); },
    // Reopen the windows saved from the previous session (#17).
    restoreUi: function (list) {
      uiRestoring = true;
      if (window.WM && WM.restoreState) WM.restoreState(list);
      setTimeout(function () { uiRestoring = false; }, 200);
    }
  };

  // Shared device map-link (#0f): open the full in-game map centred on a grid position, with a
  // labelled marker. Used by Root Cyberwarfare device apps' [Map] buttons. pos = [x,y].
  window.AE3_openMap = function (pos, label) {
    if (!pos || pos.length < 2) { A3.send("map_open", {}); return; }
    A3.send("map_open", { pos: pos, label: label || "" });
  };

  window.Apps = Apps;
  window.Desktop = Desktop;
})();
