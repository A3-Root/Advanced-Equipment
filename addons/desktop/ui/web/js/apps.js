/*
 * AE3 built-in apps on the Ubuntu shell. Each app registers a descriptor whose render(body, win,
 * args) populates the window. Filesystem apps talk to the SQF backend (AE3_desktop_fnc_fsHandle)
 * via A3.request; permissions and per-user scoping (#9) are enforced server-side in SQF.
 */
(function () {
  function h(html) { var d = document.createElement("div"); d.innerHTML = html.trim(); return d.firstElementChild; }
  function esc(s) { return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;"); }
  function joinPath(dir, name) { return (dir.replace(/\/+$/, "") + "/" + name).replace(/\/+/g, "/"); }

  // ---------------- Files ----------------
  Apps.register({
    id: "files", title: "Files", glyph: "📁", width: 660, height: 440,
    showOnDesktop: true, showInDock: true,
    render: function (body, win, args) {
      body.innerHTML =
        '<div class="toolbar">' +
          '<button class="btn up" title="Up">&#8593;</button>' +
          '<input class="input path" style="flex:1" readonly>' +
          '<button class="btn mkdir">New Folder</button>' +
          '<button class="btn del">Delete</button>' +
          '<button class="btn refresh">&#8635;</button>' +
        '</div>' +
        '<ul class="list entries"><li class="muted pad">Loading&hellip;</li></ul>';
      var cwd = (args && args.path) || "/";
      var sel = null;
      var entries = body.querySelector(".entries");
      var pathInput = body.querySelector(".path");

      function load() {
        pathInput.value = cwd; sel = null;
        A3.request("fs_list", { path: cwd }).then(function (res) {
          entries.innerHTML = "";
          if (res.error && res.error !== "") {
            entries.innerHTML = '<li class="muted pad">' + (res.error === "denied" ? "Permission denied" : "Unavailable") + "</li>";
            return;
          }
          var items = res.entries || [];
          if (!items.length) { entries.innerHTML = '<li class="muted pad">Empty</li>'; return; }
          items.forEach(function (it) {
            var li = h('<li><span>' + (it.dir ? "📁" : "📄") + '</span><span>' + esc(it.name) + "</span></li>");
            li.addEventListener("click", function () {
              entries.querySelectorAll("li").forEach(function (n) { n.classList.remove("sel"); });
              li.classList.add("sel"); sel = it;
            });
            li.addEventListener("dblclick", function () {
              if (it.dir) { cwd = joinPath(cwd, it.name); load(); }
              else { openFile(joinPath(cwd, it.name)); }
            });
            entries.appendChild(li);
          });
        }).catch(function () { entries.innerHTML = '<li class="muted pad">Filesystem unavailable</li>'; });
      }

      function openFile(path) {
        A3.request("fs_read", { path: path }).then(function (res) {
          if (res.error && res.error !== "") { Modal.alert("Open", res.error === "not_text" ? "Not a text file." : "Cannot open file."); return; }
          Apps.launch("notepad", { path: path, content: res.content || "" });
        });
      }

      body.querySelector(".up").addEventListener("click", function () {
        if (cwd !== "/") { cwd = cwd.replace(/\/+$/, "").split("/").slice(0, -1).join("/") || "/"; load(); }
      });
      body.querySelector(".refresh").addEventListener("click", load);
      body.querySelector(".mkdir").addEventListener("click", function () {
        Modal.prompt("New folder name", "untitled").then(function (name) {
          if (!name) return;
          A3.request("fs_mkdir", { path: joinPath(cwd, name) }).then(function (r) {
            if (r.error && r.error !== "") Modal.alert("New Folder", "Permission denied."); else load();
          });
        });
      });
      body.querySelector(".del").addEventListener("click", function () {
        if (!sel) return;
        Modal.confirm("Delete", "Delete '" + sel.name + "'?").then(function (ok) {
          if (!ok) return;
          A3.request("fs_delete", { path: joinPath(cwd, sel.name) }).then(function (r) {
            if (r.error && r.error !== "") Modal.alert("Delete", "Permission denied."); else load();
          });
        });
      });
      load();
    }
  });

  // ---------------- Notepad ----------------
  Apps.register({
    id: "notepad", title: "Text Editor", glyph: "📝", width: 620, height: 460,
    showInDock: true,
    render: function (body, win, args) {
      var path = (args && args.path) || null;
      body.innerHTML =
        '<div class="toolbar">' +
          '<button class="btn n">New</button>' +
          '<button class="btn o">Open</button>' +
          '<button class="btn s">Save</button>' +
          '<button class="btn sa">Save As</button>' +
          '<span class="muted fname" style="margin-left:auto"></span>' +
        '</div>' +
        '<textarea class="editor" style="width:100%;height:calc(100% - 50px);border:none;outline:none;resize:none;background:#262626;color:#eee;padding:12px;font-family:monospace;font-size:13px"></textarea>';
      var ta = body.querySelector(".editor");
      var fname = body.querySelector(".fname");
      if (args && args.content != null) ta.value = args.content;
      function setName() { fname.textContent = path || "(unsaved)"; win.el.querySelector(".title").textContent = "Text Editor — " + (path ? path.split("/").pop() : "Untitled"); }
      setName();

      function save(toPath) {
        A3.request("fs_save", { path: toPath, content: ta.value }).then(function (r) {
          if (r.error && r.error !== "") { Modal.alert("Save", "Permission denied."); return; }
          path = toPath; setName();
        });
      }
      body.querySelector(".n").addEventListener("click", function () { ta.value = ""; path = null; setName(); });
      body.querySelector(".o").addEventListener("click", function () {
        Modal.prompt("Open file (full path)", path || "/home/").then(function (p) {
          if (!p) return;
          A3.request("fs_read", { path: p }).then(function (res) {
            if (res.error && res.error !== "") { Modal.alert("Open", "Cannot open file."); return; }
            ta.value = res.content || ""; path = p; setName();
          });
        });
      });
      body.querySelector(".s").addEventListener("click", function () {
        if (path) save(path); else body.querySelector(".sa").click();
      });
      body.querySelector(".sa").addEventListener("click", function () {
        Modal.prompt("Save As (full path)", path || "/home/untitled.txt").then(function (p) { if (p) save(p); });
      });
    }
  });

  // ---------------- Settings (absorbs System Monitor, #14) ----------------
  Apps.register({
    id: "settings", title: "Settings", glyph: "⚙", width: 560, height: 400,
    showOnDesktop: true, showInDock: true, singleton: true,
    render: function (body) {
      body.innerHTML = '<div class="pad"><h3>System</h3><div id="sysinfo" class="muted">Reading&hellip;</div></div>';
      var box = body.querySelector("#sysinfo");
      A3.request("sysinfo", {}).then(function (s) {
        s = s || {};
        box.innerHTML =
          "Hostname: " + esc(s.hostname || "?") + "<br>" +
          "IP: " + esc(s.ip || "?") + " &nbsp; Gateway: " + esc(s.gateway || "?") + "<br>" +
          "Power: " + esc(s.power || "?") + " &nbsp; Battery: " + (s.battery != null ? s.battery + "%" : "?") + "<br>" +
          "Uptime: " + esc(s.uptime || "?");
      }).catch(function () { box.textContent = "Unavailable"; });
    }
  });

  // ---------------- Network (#11) ----------------
  Apps.register({
    id: "network", title: "Network", glyph: "📶", width: 560, height: 380,
    showInDock: true,
    render: function (body) {
      body.innerHTML = '<div class="pad"><div style="display:flex;align-items:center"><h3 style="flex:1">Wireless networks</h3><button class="btn rescan">Rescan</button></div><ul class="list nets"><li class="muted">Scanning&hellip;</li></ul></div>';
      var nets = body.querySelector(".nets");
      function scan() {
        nets.innerHTML = '<li class="muted">Scanning&hellip;</li>';
        A3.request("net_scan", {}).then(function (list) {
          nets.innerHTML = "";
          (list || []).forEach(function (n) {
            var li = h('<li><span>📶</span><span>' + esc(n.ssid) + (n.current ? " <span class=\"muted\">(connected)</span>" : "") +
              "</span><span class=\"muted\" style=\"margin-left:auto\">" + esc(n.ip || "") + "</span></li>");
            li.addEventListener("dblclick", function () {
              A3.send("net_connect", { netId: n.netId });
              setTimeout(scan, 800);
            });
            nets.appendChild(li);
          });
          if (!list || !list.length) nets.innerHTML = '<li class="muted">No networks in range</li>';
        }).catch(function () { nets.innerHTML = '<li class="muted">Network stack unavailable</li>'; });
      }
      body.querySelector(".rescan").addEventListener("click", scan);
      scan();
    }
  });

  // ---------------- Calendar (#12: month/year nav + go-to-date) ----------------
  Apps.register({
    id: "calendar", title: "Calendar", glyph: "📅", width: 520, height: 460,
    showInDock: true, singleton: true,
    render: function (body) {
      var months = ["January","February","March","April","May","June","July","August","September","October","November","December"];
      var view = new Date(); view.setDate(1);
      var events = {};
      body.innerHTML =
        '<div class="toolbar">' +
          '<button class="btn py" title="Previous year">&#171;</button>' +
          '<button class="btn pm" title="Previous month">&#8249;</button>' +
          '<span class="hdr" style="flex:1;text-align:center;font-weight:600"></span>' +
          '<button class="btn nm" title="Next month">&#8250;</button>' +
          '<button class="btn ny" title="Next year">&#187;</button>' +
        '</div>' +
        '<div class="toolbar"><input class="input goto" type="date" style="flex:1"><button class="btn accent go">Go</button><button class="btn today">Today</button></div>' +
        '<div class="grid" style="display:grid;grid-template-columns:repeat(7,1fr);gap:2px;padding:8px"></div>';
      var hdr = body.querySelector(".hdr");
      var grid = body.querySelector(".grid");

      function draw() {
        hdr.textContent = months[view.getMonth()] + " " + view.getFullYear();
        grid.innerHTML = "";
        ["Su","Mo","Tu","We","Th","Fr","Sa"].forEach(function (d) {
          grid.appendChild(h('<div class="muted" style="text-align:center;font-size:12px;padding:4px">' + d + "</div>"));
        });
        var first = new Date(view.getFullYear(), view.getMonth(), 1).getDay();
        var days = new Date(view.getFullYear(), view.getMonth() + 1, 0).getDate();
        for (var i = 0; i < first; i++) grid.appendChild(h('<div></div>'));
        var today = new Date();
        for (var d = 1; d <= days; d++) {
          var iso = view.getFullYear() + "-" + String(view.getMonth() + 1).padStart(2, "0") + "-" + String(d).padStart(2, "0");
          var isToday = (today.getFullYear() === view.getFullYear() && today.getMonth() === view.getMonth() && today.getDate() === d);
          var has = events[iso];
          var cell = h('<div style="text-align:center;padding:8px 0;border-radius:6px;cursor:pointer;' +
            (isToday ? "background:var(--accent);color:#fff;" : "background:var(--surface-2);") + '">' + d +
            (has ? '<div style="font-size:9px;color:#ffd2c2">●</div>' : "") + "</div>");
          grid.appendChild(cell);
        }
      }
      function loadEvents() {
        A3.request("cal_list", { year: view.getFullYear(), month: view.getMonth() + 1 }).then(function (list) {
          events = {};
          (list || []).forEach(function (e) { events[e.date] = (events[e.date] || []).concat(e); });
          draw();
        }).catch(draw);
      }
      body.querySelector(".pm").addEventListener("click", function () { view.setMonth(view.getMonth() - 1); loadEvents(); });
      body.querySelector(".nm").addEventListener("click", function () { view.setMonth(view.getMonth() + 1); loadEvents(); });
      body.querySelector(".py").addEventListener("click", function () { view.setFullYear(view.getFullYear() - 1); loadEvents(); });
      body.querySelector(".ny").addEventListener("click", function () { view.setFullYear(view.getFullYear() + 1); loadEvents(); });
      body.querySelector(".today").addEventListener("click", function () { view = new Date(); view.setDate(1); loadEvents(); });
      body.querySelector(".go").addEventListener("click", function () {
        var v = body.querySelector(".goto").value; if (!v) return;
        var p = v.split("-"); view = new Date(+p[0], +p[1] - 1, 1); loadEvents();
      });
      loadEvents();
    }
  });

  // ---------------- Browser (#18: real pages incl. wiki site) ----------------
  Apps.register({
    id: "browser", title: "Browser", glyph: "🌐", width: 820, height: 560,
    showOnDesktop: true, showInDock: true,
    render: function (body) {
      // Friendly names resolve to bundled local sites under ui/web/sites/.
      var sites = {
        "home": "sites/portal/index.html",
        "rootnet": "sites/portal/index.html",
        "wiki": "sites/wiki/index.html"
      };
      function resolve(addr) {
        addr = (addr || "home").trim().toLowerCase().replace(/^https?:\/\//, "").replace(/\/$/, "");
        if (sites[addr]) return sites[addr];
        if (addr.indexOf("sites/") === 0 || addr.indexOf(".html") >= 0) return addr;
        return sites.home;
      }
      body.innerHTML =
        '<div class="toolbar">' +
          '<button class="btn back">&#8592;</button><button class="btn fwd">&#8594;</button>' +
          '<button class="btn home">&#8962;</button>' +
          '<input class="input addr" style="flex:1" value="home">' +
          '<button class="btn accent go">Go</button>' +
        '</div>' +
        '<iframe class="page" style="width:100%;height:calc(100% - 50px);border:none;background:#fff"></iframe>';
      var frame = body.querySelector(".page");
      var addr = body.querySelector(".addr");
      function nav(a) { addr.value = a; frame.src = resolve(a); }
      body.querySelector(".go").addEventListener("click", function () { nav(addr.value); });
      body.querySelector(".home").addEventListener("click", function () { nav("home"); });
      body.querySelector(".back").addEventListener("click", function () { try { frame.contentWindow.history.back(); } catch (e) {} });
      body.querySelector(".fwd").addEventListener("click", function () { try { frame.contentWindow.history.forward(); } catch (e) {} });
      addr.addEventListener("keydown", function (e) { if (e.key === "Enter") nav(addr.value); });
      nav("home");
    }
  });

  // ---------------- Map (#13/#20: in-window canvas minimap) ----------------
  Apps.register({
    id: "map", title: "Map", glyph: "🗺", width: 520, height: 540,
    showInDock: true, singleton: true,
    render: function (body, win) {
      body.innerHTML =
        '<div class="toolbar"><span class="muted world" style="flex:1"></span>' +
          '<button class="btn zin">+</button><button class="btn zout">&#8211;</button></div>' +
        '<canvas class="map" style="display:block;background:#1b2a1b;width:100%;height:calc(100% - 50px)"></canvas>';
      var cv = body.querySelector(".map");
      var worldEl = body.querySelector(".world");
      var range = 250;
      function draw(d) {
        worldEl.textContent = (d && d.world ? d.world : "") + " — " + Math.round(range) + "m";
        var w = cv.clientWidth, hh = cv.clientHeight;
        cv.width = w; cv.height = hh;
        var ctx = cv.getContext("2d");
        ctx.clearRect(0, 0, w, hh);
        var cx = w / 2, cy = hh / 2, scale = (Math.min(w, hh) / 2) / range;
        // grid
        ctx.strokeStyle = "rgba(255,255,255,0.08)";
        for (var g = -range; g <= range; g += 50) {
          ctx.beginPath(); ctx.moveTo(cx + g * scale, 0); ctx.lineTo(cx + g * scale, hh); ctx.stroke();
          ctx.beginPath(); ctx.moveTo(0, cy + g * scale); ctx.lineTo(w, cy + g * scale); ctx.stroke();
        }
        (d && d.blips ? d.blips : []).forEach(function (b) {
          var x = cx + b.dx * scale, y = cy - b.dy * scale;
          var color = b.kind === "self" ? "#e95420" : (b.kind === "router" ? "#5da8e8" : "#8ce10b");
          ctx.fillStyle = color; ctx.beginPath(); ctx.arc(x, y, 5, 0, 7); ctx.fill();
          if (b.label) { ctx.fillStyle = "#ddd"; ctx.font = "11px sans-serif"; ctx.fillText(b.label, x + 7, y + 3); }
        });
        // player at centre
        ctx.fillStyle = "#fff"; ctx.beginPath(); ctx.arc(cx, cy, 4, 0, 7); ctx.fill();
      }
      function refresh() { A3.request("map_data", { range: range }).then(draw).catch(function () { draw(null); }); }
      body.querySelector(".zin").addEventListener("click", function () { range = Math.max(50, range / 1.5); refresh(); });
      body.querySelector(".zout").addEventListener("click", function () { range = Math.min(2000, range * 1.5); refresh(); });
      win.timer = setInterval(refresh, 1000);
      win.app.onClose = function (w) { if (w.timer) clearInterval(w.timer); };
      refresh();
    }
  });

  // ---------------- Mail (#18) ----------------
  Apps.register({
    id: "mail", title: "Mail", glyph: "✉", width: 760, height: 480,
    showOnDesktop: true, showInDock: true,
    render: function (body) {
      body.innerHTML =
        '<div class="toolbar"><button class="btn refresh">&#8635;</button><button class="btn compose accent">Compose</button></div>' +
        '<div style="display:flex;height:calc(100% - 50px)">' +
          '<ul class="list mails" style="width:38%;border-right:1px solid var(--line);overflow:auto"></ul>' +
          '<div class="reader pad" style="flex:1;overflow:auto"><p class="muted">Select a message.</p></div>' +
        '</div>';
      var mails = body.querySelector(".mails");
      var reader = body.querySelector(".reader");

      function list() {
        mails.innerHTML = '<li class="muted pad">Loading…</li>';
        A3.request("mail_list", {}).then(function (res) {
          mails.innerHTML = "";
          var items = (res && res.mails) || [];
          if (!items.length) { mails.innerHTML = '<li class="muted pad">No mail</li>'; return; }
          items.forEach(function (m) {
            var li = h('<li style="flex-direction:column;align-items:flex-start"><span>' + esc(m.subject || "(no subject)") +
              '</span><span class="muted" style="font-size:12px">' + esc(m.from || "") + "</span></li>");
            li.addEventListener("click", function () { open(m.file); });
            mails.appendChild(li);
          });
        }).catch(function () { mails.innerHTML = '<li class="muted pad">Unavailable</li>'; });
      }
      function open(file) {
        A3.request("mail_read", { file: file }).then(function (m) {
          if (m.error && m.error !== "") { reader.innerHTML = '<p class="muted">Cannot open.</p>'; return; }
          reader.innerHTML = '<h2>' + esc(m.subject || "") + '</h2><p class="muted">From: ' + esc(m.from || "") +
            '</p><hr style="border-color:var(--line)"><pre style="white-space:pre-wrap;font-family:inherit">' + esc(m.body || "") + "</pre>";
        });
      }
      function compose() {
        reader.innerHTML =
          '<h3>New message</h3>' +
          '<div style="display:flex;flex-direction:column;gap:8px;max-width:480px">' +
            '<input class="input to" placeholder="To (IP, e.g. 192.168.0.2)" value="192.168.0.">' +
            '<input class="input subj" placeholder="Subject">' +
            '<textarea class="input bd" rows="8" placeholder="Message"></textarea>' +
            '<div><button class="btn accent send">Send</button> <span class="muted st"></span></div>' +
          '</div>';
        reader.querySelector(".send").addEventListener("click", function () {
          var st = reader.querySelector(".st");
          A3.request("mail_send", {
            to: reader.querySelector(".to").value,
            subject: reader.querySelector(".subj").value,
            body: reader.querySelector(".bd").value
          }).then(function (r) {
            st.textContent = (r.error && r.error !== "") ? ("Failed: " + r.error) : "Sent.";
            if (!r.error || r.error === "") setTimeout(list, 400);
          });
        });
      }
      body.querySelector(".refresh").addEventListener("click", list);
      body.querySelector(".compose").addEventListener("click", compose);
      list();
    }
  });

  // ---------------- Messenger (#18) ----------------
  Apps.register({
    id: "messenger", title: "Messenger", glyph: "💬", width: 600, height: 480,
    showInDock: true, singleton: true,
    render: function (body, win) {
      body.innerHTML =
        '<div class="msgs" style="flex:1;overflow:auto;padding:12px;height:calc(100% - 96px);background:#262626"></div>' +
        '<div class="toolbar"><input class="input to" placeholder="To (IP)" value="192.168.0." style="width:160px"></div>' +
        '<div class="toolbar"><input class="input text" placeholder="Message" style="flex:1"><button class="btn accent send">Send</button></div>';
      var msgs = body.querySelector(".msgs");
      var toEl = body.querySelector(".to");
      var textEl = body.querySelector(".text");

      function render(text) {
        msgs.innerHTML = "";
        (text || "").split("\n").forEach(function (line) {
          if (line.trim() === "") return;
          msgs.appendChild(h('<div style="margin:4px 0">' + esc(line) + "</div>"));
        });
        msgs.scrollTop = msgs.scrollHeight;
      }
      var onData = function (d) { render(d && d.text); };
      A3.on("chat_data", onData);

      function send() {
        if (textEl.value.trim() === "") return;
        A3.request("chat_send", { to: toEl.value, text: textEl.value }).then(function (r) {
          if (r.error && r.error !== "") { Modal.alert("Messenger", "Could not send: " + r.error); return; }
          textEl.value = "";
          setTimeout(function () { A3.send("chat_pull", {}); }, 300);
        });
      }
      body.querySelector(".send").addEventListener("click", send);
      textEl.addEventListener("keydown", function (e) { if (e.key === "Enter") send(); });

      A3.send("chat_pull", {});
      win.timer = setInterval(function () { A3.send("chat_pull", {}); }, 3000);
      win.app.onClose = function (w) { if (w.timer) clearInterval(w.timer); };
    }
  });

  // ---------------- About ----------------
  Apps.register({
    id: "about", title: "About AE3 OS", glyph: "ℹ", width: 420, height: 260, singleton: true,
    render: function (body) {
      body.innerHTML =
        '<div class="pad" style="text-align:center">' +
          '<div style="font-size:48px">💻</div><h2>AE3 OS</h2>' +
          '<p class="muted">Advanced Equipment Revamped — Ubuntu edition</p>' +
          '<p class="muted">Web desktop on Arma 3 CEF</p></div>';
    }
  });
})();
