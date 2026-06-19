/*
 * AE3 desktop shell: top bar, left dock, desktop icon grid, clock, app registry.
 * Apps register via Apps.register({id, title, glyph, render, ...}); the shell renders dock +
 * desktop entries and routes launches through the window manager.
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

  function el(tag, cls, html) {
    var e = document.createElement(tag);
    if (cls) e.className = cls;
    if (html != null) e.innerHTML = html;
    return e;
  }

  function buildDock() {
    var dock = document.getElementById("dock");
    dock.innerHTML = "";
    registry.filter(function (a) { return a.showInDock !== false; }).forEach(function (app) {
      var item = el("div", "dock-item", '<span>' + (app.glyph || "") + '</span><span class="tip">' + app.title + "</span>");
      item.dataset.app = app.id;
      item.addEventListener("click", function () { Apps.launch(app.id); });
      dock.appendChild(item);
    });
  }

  function buildDesktopIcons() {
    var desk = document.getElementById("desktop");
    desk.innerHTML = "";
    registry.filter(function (a) { return a.showOnDesktop; }).forEach(function (app) {
      var icon = el("div", "desktop-icon",
        '<div class="glyph">' + (app.glyph || "") + '</div><div class="label">' + app.title + "</div>");
      icon.addEventListener("dblclick", function () { Apps.launch(app.id); });
      icon.addEventListener("click", function () {
        desk.querySelectorAll(".desktop-icon").forEach(function (n) { n.classList.remove("sel"); });
        icon.classList.add("sel");
      });
      desk.appendChild(icon);
    });
    desk.addEventListener("mousedown", function (e) {
      if (e.target === desk) desk.querySelectorAll(".desktop-icon").forEach(function (n) { n.classList.remove("sel"); });
    });
  }

  function refreshDockRunning() {
    var running = WM.running();
    document.querySelectorAll("#dock .dock-item").forEach(function (n) {
      n.classList.toggle("running", running.indexOf(n.dataset.app) >= 0);
    });
  }

  var clockTimer = null, batteryTimer = null;

  function startClock() {
    function tick() {
      var d = new Date();
      var t = d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
      var c = document.getElementById("clock");
      if (c) c.textContent = t;
    }
    if (clockTimer) clearInterval(clockTimer);
    clockTimer = setInterval(tick, 1000); tick();
  }

  // Top-bar battery widget (#7): polls sysinfo on a slow cadence (the SQF battery level is synced
  // at ~1% granularity, so 5s is plenty) and reflects charge + power state.
  function buildTray() {
    var tray = document.querySelector("#topbar .tray");
    if (!tray || !window.Icons) return;
    tray.innerHTML =
      '<span class="battery" title="Battery" style="margin-right:8px">' + Icons.battery + ' <span class="batpct">--</span></span>' +
      '<span class="wifi" style="margin-right:8px">' + Icons.wifi + '</span>' +
      '<span class="powerbtn" title="Power" style="cursor:pointer">' + Icons.power + '</span>';

    var pct = tray.querySelector(".batpct");
    function poll() {
      A3.request("sysinfo", {}).then(function (s) {
        s = s || {};
        if (pct) pct.textContent = (s.battery != null && s.battery >= 0) ? (s.battery + "%") : "--";
        var bat = tray.querySelector(".battery");
        if (bat) {
          var low = (s.battery != null && s.battery >= 0 && s.battery <= 15);
          bat.style.color = low ? "#e9542d" : "";
          bat.title = "Battery " + ((s.battery != null && s.battery >= 0) ? s.battery + "%" : "?") +
            (s.power ? " - " + s.power : "");
        }
      }).catch(function () {});
    }
    if (batteryTimer) clearInterval(batteryTimer);
    batteryTimer = setInterval(poll, 5000); poll();

    // Power menu (#8): Sign out -> login; Shut down -> power off the laptop.
    var btn = tray.querySelector(".powerbtn");
    if (btn) btn.addEventListener("click", function (e) {
      e.stopPropagation();
      var existing = document.getElementById("powermenu");
      if (existing) { existing.remove(); return; }
      var m = el("div", null,
        '<div class="pm-item signout">Sign out</div><div class="pm-item shutdown">Shut down</div>');
      m.id = "powermenu";
      m.style.cssText = "position:fixed;top:30px;right:6px;z-index:300;background:var(--panel,#2b2b2b);" +
        "border:1px solid var(--line,#000);border-radius:6px;overflow:hidden;min-width:130px;box-shadow:0 4px 14px rgba(0,0,0,.4)";
      m.querySelectorAll(".pm-item").forEach(function (it) {
        it.style.cssText = "padding:8px 14px;cursor:pointer;color:var(--text,#eee)";
        it.addEventListener("mouseenter", function () { it.style.background = "var(--accent,#e95420)"; });
        it.addEventListener("mouseleave", function () { it.style.background = ""; });
      });
      m.querySelector(".signout").addEventListener("click", function () { m.remove(); Desktop.signOut(); });
      m.querySelector(".shutdown").addEventListener("click", function () { m.remove(); A3.send("shutdown", {}); });
      document.body.appendChild(m);
      setTimeout(function () {
        document.addEventListener("mousedown", function close(ev) {
          if (!m.contains(ev.target)) { m.remove(); document.removeEventListener("mousedown", close); }
        });
      }, 0);
    });
  }

  var Desktop = {
    init: function () {
      WM.onTaskbarChange = refreshDockRunning;
      buildTray();
      buildDock();
      buildDesktopIcons();
      startClock();
      var act = document.querySelector("#topbar .activities");
      if (act && !act.dataset.bound) {
        act.dataset.bound = "1";
        act.addEventListener("click", function () {
          document.getElementById("desktop").classList.toggle("show-all");
        });
      }
    },
    setHostname: function (name) {
      var h = document.getElementById("hostname");
      if (h) h.textContent = name || "ae3-os";
    },
    signOut: function () {
      if (window.WM && WM.closeAll) WM.closeAll();
      A3.send("signout", {});
      if (typeof window.AE3_showLogin === "function") window.AE3_showLogin();
    },
    refresh: function () { buildDock(); buildDesktopIcons(); refreshDockRunning(); }
  };

  window.Apps = Apps;
  window.Desktop = Desktop;
})();
