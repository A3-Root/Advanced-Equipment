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

  function makeDeviceApp(desc) {
    var extra = desc.extra || {};
    var actions = extra.actions || [];
    return {
      id: desc.id, title: desc.title, glyph: desc.glyph || "🔌",
      kind: "deviceList", width: 620, height: 440,
      showOnDesktop: true, showInDock: true, singleton: true,
      render: function (body, win) {
        body.innerHTML =
          '<div class="toolbar"><span class="muted" style="flex:1">' + esc(desc.title) + '</span><button class="btn refresh">&#8635;</button></div>' +
          '<ul class="list devs"><li class="muted pad">Loading…</li></ul>' +
          '<div class="toolbar status muted" style="min-height:18px"></div>';
        var devs = body.querySelector(".devs");
        var status = body.querySelector(".status");

        function render(items) {
          devs.innerHTML = "";
          if (!items.length) { devs.innerHTML = '<li class="muted pad">No devices</li>'; return; }
          items.forEach(function (d) {
            var li = document.createElement("li");
            li.innerHTML = '<span>' + (desc.glyph || "🔌") + '</span><span style="flex:1">' + esc(d.label || d.name || ("#" + d.id)) + "</span>";
            actions.forEach(function (a) {
              var b = document.createElement("button");
              b.className = "btn"; b.textContent = a.label;
              b.style.marginLeft = "6px";
              b.addEventListener("click", function () {
                A3.send("dev_action", { app: desc.id, type: extra.type, id: d.id, action: a.id, path: d.path || "" });
                status.textContent = a.label + "…";
              });
              li.appendChild(b);
            });
            devs.appendChild(li);
          });
        }
        listSubs[extra.type] = render;
        resultSubs[extra.type] = function (r) {
          status.textContent = r.msg || (r.ok ? "OK" : "Failed");
          if (r.ok) setTimeout(request, 300);
        };
        function request() { devs.innerHTML = '<li class="muted pad">Loading…</li>'; A3.send("dev_request", { type: extra.type }); }
        body.querySelector(".refresh").addEventListener("click", request);
        win.app.onClose = function () { delete listSubs[extra.type]; delete resultSubs[extra.type]; };
        request();
      }
    };
  }

  A3.on("ext_apps", function (list) {
    (list || []).forEach(function (desc) {
      if (Apps.get(desc.id)) return;
      if (desc.kind === "deviceList") Apps.register(makeDeviceApp(desc));
    });
    if (window.Desktop) Desktop.refresh();
  });
})();
