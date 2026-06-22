/*
 * AE3 external apps - lets other addons (Root Cyberwarfare, ...) inject launcher apps over the
 * SQF bridge. On boot the SQF side pushes "ext_apps"; each descriptor becomes a generic
 * device-list app. The app requests its device list (dev_request), renders rows with per-device
 * action buttons, and triggers actions (dev_action). Results stream back via dev_list / dev_result.
 */
(function () {
  function esc(s) { return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;"); }

  // Route pushed results to the interested open windows, keyed by device type.
  var listSubs = {};   // type -> fn(items)
  var resultSubs = {};  // type -> fn(res)
  A3.on("dev_list", function (p) { if (p && listSubs[p.type] != null) listSubs[p.type](p.items || []); });
  A3.on("dev_result", function (p) { if (p && resultSubs[p.type] != null) resultSubs[p.type](p); });

  // Prefer a named SVG icon (desc.icon or desc.extra.icon), fall back to a glyph string, then a
  // default device icon. Lets ext apps opt into the SVG set without changing registerExtApp's API.
  function glyphFor(desc) {
    var iconName = desc.icon || (desc.extra && desc.extra.icon);
    if (window.Icons && iconName && Icons[iconName]) return Icons[iconName];
    if (desc.glyph) return desc.glyph;
    return window.Icons ? Icons.device : "🔌";
  }

  function makeDeviceApp(desc) {
    var extra = desc.extra || {};
    var actions = extra.actions || [];
    var glyph = glyphFor(desc);
    return {
      id: desc.id, title: desc.title, glyph: glyph,
      kind: "deviceList", width: 620, height: 440,
      // Ext apps live in the Applications menu (extra.menu, e.g. "Tools/Hack"), NOT the desktop or
      // dock (Root Cyberwarfare #1/#10). The desktop is fixed to My Computer / Recycle Bin / Files.
      showOnDesktop: false, showInDock: false, singleton: true,
      menu: extra.menu || "Tools",
      render: function (body, win) {
        body.innerHTML =
          '<div class="toolbar"><span class="muted" style="flex:1">' + esc(desc.title) + '</span>' +
            (extra.globalActions ? '<span class="globals"></span>' : '') +
            '<button class="btn refresh">&#8635;</button></div>' +
          '<ul class="list devs"><li class="muted pad">Loading...</li></ul>' +
          '<div class="dev-status" style="min-height:22px;padding:8px 12px;font-weight:600"></div>';
        var devs = body.querySelector(".devs");
        var status = body.querySelector(".dev-status");

        // Prominent, clearly-coloured result feedback (Root_CW general #2): success green, failure
        // orange-red, so low-battery / overload / not-allowed messages can't be missed.
        function setStatus(msg, ok) {
          status.textContent = msg || "";
          status.style.color = (ok === false) ? "#ff7a4d" : (ok === true ? "var(--good)" : "var(--muted)");
        }

        // Whole-app global actions (e.g. Lights: All On / All Off, Root_CW Lights #1).
        var glWrap = body.querySelector(".globals");
        if (glWrap && extra.globalActions) {
          extra.globalActions.forEach(function (a) {
            var b = document.createElement("button"); b.className = "btn"; b.textContent = a.label; b.style.marginLeft = "6px";
            b.addEventListener("click", function () {
              A3.send("dev_action", { app: desc.id, type: extra.type, id: "", action: a.id, path: "" });
              setStatus(a.label + "...");
            });
            glWrap.appendChild(b);
          });
        }

        // Perform a single action (confirm / slider / download / plain send). Shared by top-level
        // buttons and submenu children so every flow behaves identically (Drones/Vehicles #1).
        function runAction(d, a, sub) {
          // Optional confirmation (e.g. doors warn about battery power before locking, Doors #3).
          if (a.confirm && a.confirm !== "" && typeof Modal !== "undefined") {
            Modal.confirm(a.label, a.confirm).then(function (ok) {
              if (ok) A3.send("dev_action", { app: desc.id, type: extra.type, id: d.id, action: a.id, sub: sub || "", path: d.path || "" });
              if (ok) setStatus(a.label + "...");
            });
            return;
          }
          // Slider flow (Root_CW Vehicles #1): open a bounded slider, then send the action with the
          // chosen numeric value (fuel %, speed km/h, alarm seconds).
          if (a.slider && typeof Modal !== "undefined" && typeof Modal.slider === "function") {
            Modal.slider(a.label + (d.label ? (" - " + d.label) : ""), a.min, a.max, a.value, a.step, a.unit, a.options || {}).then(function (v) {
              if (v == null) return;
              var value = (typeof v === "object") ? v.value : v;
              var payload = { app: desc.id, type: extra.type, id: d.id, action: a.id, sub: sub || "", path: d.path || "", value: value };
              if (typeof v === "object" && v.lock !== undefined) payload.lock = !!v.lock;
              A3.send("dev_action", payload);
              setStatus(a.label + " → " + value + (a.unit || "") + "...");
            });
            return;
          }
          // Download flow (Databases #5): pick a save location, run a progress bar for the configured
          // download time, then perform the action with the chosen path.
          if (a.flow === "download" && typeof window.AE3_pickFile === "function") {
            window.AE3_pickFile("save", { title: "Save downloaded file", start: (window.AE3_HOME || "/root"), filename: (d.label || "download") }).then(function (savePath) {
              if (!savePath) return;
              runProgress(d.downloadTime || 0, function () {
                A3.send("dev_action", { app: desc.id, type: extra.type, id: d.id, action: a.id, sub: sub || "", path: d.path || "", savePath: savePath });
              });
            });
            return;
          }
          A3.send("dev_action", { app: desc.id, type: extra.type, id: d.id, action: a.id, sub: sub || "", path: d.path || "" });
          setStatus(a.label + "...");
        }

        function actionButton(d, a, sub) {
          var b = document.createElement("button");
          b.className = "btn" + (a.danger ? " accent" : ""); b.textContent = a.label; b.style.marginLeft = "6px";
          b.addEventListener("click", function () {
            // Submenu (Drones "Change Drone Side", grouped Vehicle controls #1): open a popup of child
            // actions; each child runs the normal confirm/slider/send flow via runAction.
            if (a.submenu && a.submenu.length && typeof window.AE3_ctxMenu === "function") {
              var r = b.getBoundingClientRect();
              window.AE3_ctxMenu(r.left, r.bottom, a.submenu.map(function (ca) {
                return { label: ca.label, action: function () { runAction(d, ca, sub); } };
              }));
              return;
            }
            runAction(d, a, sub);
          });
          return b;
        }

        // Animated progress bar in the status area over the given number of seconds.
        function runProgress(seconds, done) {
          var secs = Number(seconds) || 0;
          if (secs <= 0) { setStatus("Downloading..."); done(); return; }
          var start = Date.now(); var total = secs * 1000;
          status.innerHTML = '<div style="background:#2b2b2b;border-radius:6px;overflow:hidden;height:14px;width:200px;display:inline-block;vertical-align:middle"><div class="dlbar" style="height:100%;width:0;background:var(--accent)"></div></div> <span class="dlpct">0%</span>';
          var bar = status.querySelector(".dlbar"); var pct = status.querySelector(".dlpct");
          var iv = setInterval(function () {
            var p = Math.min(1, (Date.now() - start) / total);
            if (bar) bar.style.width = Math.round(p * 100) + "%";
            if (pct) pct.textContent = Math.round(p * 100) + "%";
            if (p >= 1) { clearInterval(iv); done(); }
          }, 100);
        }

        function render(items) {
          devs.innerHTML = "";
          if (!items.length) { devs.innerHTML = '<li class="muted pad">No devices</li>'; return; }
          items.forEach(function (d) {
            var li = document.createElement("li");
            li.style.flexDirection = "column"; li.style.alignItems = "stretch";
            var statusHtml = (d.status != null && d.status !== "") ? ' <span class="muted">[' + esc(d.status) + ']</span>' : "";
            // Grid + clickable map link (Root_CW shared #0f), shown only when the backend provides a
            // position (gated server-side by "Allow Location View"; GPS only when tracked).
            var gridHtml = (d.grid != null && d.grid !== "") ? ' <span class="muted" style="font-size:12px">&#128205; ' + esc(d.grid) + '</span>' : "";
            var top = document.createElement("div");
            top.style.display = "flex"; top.style.alignItems = "center"; top.style.width = "100%";
            top.innerHTML = '<span class="ico">' + glyph + '</span><span style="flex:1">' + esc(d.label || d.name || ("#" + d.id)) + statusHtml + gridHtml + "</span>";
            if (d.pos && d.pos.length >= 2) {
              var mb = document.createElement("button"); mb.className = "btn"; mb.textContent = "Map"; mb.style.marginLeft = "6px";
              mb.addEventListener("click", function () { window.AE3_openMap(d.pos, d.label || ("#" + d.id)); });
              top.appendChild(mb);
            }
            // Per-device action buttons (use d.actions override when non-empty, else the app default).
            ((d.actions && d.actions.length) ? d.actions : actions).forEach(function (a) { top.appendChild(actionButton(d, a)); });
            li.appendChild(top);

            // Optional key/value details (vehicle fuel/battery/engine/alarm/brake, Root_CW Vehicles #1).
            if (d.details && d.details.length) {
              var det = document.createElement("div");
              det.className = "muted"; det.style.cssText = "font-size:12px;margin:4px 0 2px 26px;display:flex;flex-wrap:wrap;gap:10px";
              d.details.forEach(function (kv) { det.innerHTML += '<span>' + esc(kv[0]) + ": <b style='color:var(--text)'>" + esc(String(kv[1])) + "</b></span>"; });
              li.appendChild(det);
            }
            // Optional sub-items with their own actions (per-door lock/unlock, Root_CW Doors #2).
            if (d.children && d.children.length) {
              var wrap = document.createElement("div");
              wrap.style.cssText = "margin:4px 0 2px 26px;display:none;flex-direction:column;gap:4px";
              d.children.forEach(function (c) {
                var row = document.createElement("div"); row.style.cssText = "display:flex;align-items:center;font-size:12px";
                row.innerHTML = '<span style="flex:1">' + esc(c.label) + (c.status ? ' <span class="muted">[' + esc(c.status) + ']</span>' : "") + "</span>";
                (c.actions || []).forEach(function (a) { row.appendChild(actionButton(d, a, c.id)); });
                wrap.appendChild(row);
              });
              var toggle = document.createElement("button");
              toggle.className = "btn"; toggle.textContent = "Doors (" + d.children.length + ")"; toggle.style.cssText = "margin:4px 0 0 26px;align-self:flex-start";
              toggle.addEventListener("click", function () { wrap.style.display = wrap.style.display === "none" ? "flex" : "none"; });
              li.appendChild(toggle); li.appendChild(wrap);
            }
            devs.appendChild(li);
          });
        }
        listSubs[extra.type] = render;
        resultSubs[extra.type] = function (r) {
          setStatus(r.msg || (r.ok ? "OK" : "Failed"), r.ok);
          // Also raise a prominent toast so blocked/failed actions (low battery, overload not allowed,
          // ...) can't be missed in the small inline status line (Root_CW general #1).
          if (typeof window.AE3_toast === "function") {
            window.AE3_toast(r.msg || (r.ok ? "Done" : "Action failed"), r.ok ? "ok" : "error");
          }
          // Downloaded file: offer to open/read it straight from the app (Databases #5).
          if (r.ok && r.path && r.path !== "") {
            var ob = document.createElement("button");
            ob.className = "btn"; ob.textContent = "Open downloaded file"; ob.style.marginLeft = "10px";
            ob.addEventListener("click", function () { Apps.launch("notepad", { path: r.path }); });
            status.appendChild(ob);
          }
          if (r.ok) setTimeout(request, 300);
        };
        function request() { devs.innerHTML = '<li class="muted pad">Loading...</li>'; A3.send("dev_request", { type: extra.type }); }
        body.querySelector(".refresh").addEventListener("click", request);
        win.app.onClose = function () { delete listSubs[extra.type]; delete resultSubs[extra.type]; };
        request();
      }
    };
  }

  A3.on("ext_apps", function (list) {
    console.log("[AE3] ext_apps received:", (list || []).length, "app(s)");
    (list || []).forEach(function (desc) {
      if (Apps.get(desc.id)) return;
      if (desc.kind === "deviceList") Apps.register(makeDeviceApp(desc));
    });
    if (window.Desktop) Desktop.refresh();
  });
})();
