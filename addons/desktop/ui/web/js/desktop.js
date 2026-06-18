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

  function startClock() {
    function tick() {
      var d = new Date();
      var t = d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
      document.getElementById("clock").textContent = t;
    }
    setInterval(tick, 1000); tick();
  }

  var Desktop = {
    init: function () {
      WM.onTaskbarChange = refreshDockRunning;
      var tray = document.querySelector("#topbar .tray");
      if (tray && window.Icons) tray.innerHTML = Icons.power + " " + Icons.wifi;
      buildDock();
      buildDesktopIcons();
      startClock();
      var act = document.querySelector("#topbar .activities");
      if (act) act.addEventListener("click", function () {
        document.getElementById("desktop").classList.toggle("show-all");
      });
    },
    setHostname: function (name) {
      var h = document.getElementById("hostname");
      if (h) h.textContent = name || "ae3-os";
    },
    refresh: function () { buildDock(); buildDesktopIcons(); refreshDockRunning(); }
  };

  window.Apps = Apps;
  window.Desktop = Desktop;
})();
