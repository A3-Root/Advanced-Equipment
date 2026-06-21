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
    id: "files", title: "Files", glyph: Icons.files, width: 660, height: 440,
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

      var loadTries = 0;
      function load() {
        pathInput.value = cwd; sel = null;
        A3.request("fs_list", { path: cwd }).then(function (res) {
          // Filesystem still syncing from the server (MP): the backend kicked an authoritative
          // pull - show a spinner and retry a few times before giving up.
          if (res.loading) {
            if (loadTries < 6) { loadTries++; entries.innerHTML = '<li class="muted pad">Loading&hellip;</li>'; setTimeout(load, 500); }
            else { entries.innerHTML = '<li class="muted pad">Filesystem unavailable</li>'; }
            return;
          }
          loadTries = 0;
          entries.innerHTML = "";
          if (res.error && res.error !== "") {
            entries.innerHTML = '<li class="muted pad">' + (res.error === "denied" ? "Permission denied" : "Unavailable") + "</li>";
            return;
          }
          var items = res.entries || [];
          if (!items.length) { entries.innerHTML = '<li class="muted pad">Empty</li>'; return; }
          items.forEach(function (it) {
            var li = h('<li><span class="ico">' + (it.dir ? Icons.folder : Icons.file) + '</span><span>' + esc(it.name) + "</span></li>");
            li.addEventListener("click", function () {
              entries.querySelectorAll("li").forEach(function (n) { n.classList.remove("sel"); });
              li.classList.add("sel"); sel = it;
            });
            li.addEventListener("dblclick", function () {
              if (it.dir) { cwd = joinPath(cwd, it.name); load(); }
              else { openFile(joinPath(cwd, it.name)); }
            });
            li.addEventListener("contextmenu", function (e) {
              e.preventDefault(); e.stopPropagation();
              entries.querySelectorAll("li").forEach(function (n) { n.classList.remove("sel"); });
              li.classList.add("sel"); sel = it;
              fileMenu(e.clientX, e.clientY, it);
            });
            entries.appendChild(li);
          });
        }).catch(function () { entries.innerHTML = '<li class="muted pad">Filesystem unavailable</li>'; });
      }

      function openFile(path) {
        A3.request("fs_read", { path: path }).then(function (res) {
          if (res.error && res.error !== "") { Modal.alert("Open", res.error === "not_text" ? "Not a text file." : "Cannot open file."); return; }
          // Password-protected file (#7): the backend reports only "locked" (never the password or
          // payload). Prompt, verify server-side via fs_unlock, then open the decrypted content.
          if (res.locked) { unlockAndOpen(path); return; }
          Apps.launch("notepad", { path: path, content: res.content || "" });
        });
      }

      function unlockAndOpen(path) {
        Modal.prompt("This file is password protected. Enter password:", "").then(function (pass) {
          if (pass == null) return;
          A3.request("fs_unlock", { path: path, pass: pass }).then(function (res) {
            if (res.error === "bad_pass") { Modal.alert("Locked", "Wrong password."); return; }
            if (res.error && res.error !== "") { Modal.alert("Open", "Cannot open file."); return; }
            Apps.launch("notepad", { path: path, content: res.content || "" });
          });
        });
      }

      // Right-click context menu (#16): per-item (open/cut/copy/delete/rename) and empty-area
      // (new folder/file, paste, refresh). Cut/copy stash to window.AE3_clipboard; paste moves/copies
      // via the fs_move / fs_copy backend ops.
      function paste() {
        var cb = window.AE3_clipboard; if (!cb) return;
        var dest = joinPath(cwd, cb.name);
        A3.request(cb.op === "cut" ? "fs_move" : "fs_copy", { path: cb.path, dest: dest }).then(function (r) {
          if (r.error && r.error !== "") { Modal.alert("Paste", "Could not paste here."); return; }
          if (cb.op === "cut") window.AE3_clipboard = null;
          load();
        });
      }
      function fileMenu(x, y, it) {
        var full = joinPath(cwd, it.name);
        window.AE3_ctxMenu(x, y, [
          { label: it.dir ? "Open" : "Open", action: function () { if (it.dir) { cwd = full; load(); } else openFile(full); } },
          { sep: true },
          { label: "Cut", action: function () { window.AE3_clipboard = { path: full, name: it.name, op: "cut" }; } },
          { label: "Copy", action: function () { window.AE3_clipboard = { path: full, name: it.name, op: "copy" }; } },
          { label: "Paste", disabled: !window.AE3_clipboard, action: paste },
          { sep: true },
          { label: "Rename", action: function () {
            Modal.prompt("Rename to", it.name).then(function (nn) {
              if (!nn || nn === it.name) return;
              A3.request("fs_move", { path: full, dest: joinPath(cwd, nn) }).then(function (r) {
                if (r.error && r.error !== "") Modal.alert("Rename", "Could not rename."); else load();
              });
            });
          } },
          { label: "Delete", action: function () {
            A3.request("fs_delete", { path: full }).then(function (r) {
              if (r.error && r.error !== "") Modal.alert("Delete", "Permission denied."); else load();
            });
          } }
        ]);
      }
      function emptyMenu(x, y) {
        window.AE3_ctxMenu(x, y, [
          { label: "New Folder…", action: function () {
            Modal.prompt("New folder name", "untitled").then(function (name) {
              if (!name) return;
              A3.request("fs_mkdir", { path: joinPath(cwd, name) }).then(function (r) { if (r.error && r.error !== "") Modal.alert("New Folder", "Permission denied."); else load(); });
            });
          } },
          { label: "New File…", action: function () {
            Modal.prompt("New file name", "untitled.txt").then(function (name) {
              if (!name) return;
              A3.request("fs_save", { path: joinPath(cwd, name), content: "" }).then(function (r) { if (r.error && r.error !== "") Modal.alert("New File", "Permission denied."); else load(); });
            });
          } },
          { label: "Paste", disabled: !window.AE3_clipboard, action: paste },
          { sep: true },
          { label: "Refresh", action: load }
        ]);
      }
      entries.addEventListener("contextmenu", function (e) {
        if (e.target !== entries) return; // item menus handle their own; this is the empty area
        e.preventDefault(); emptyMenu(e.clientX, e.clientY);
      });

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
    id: "notepad", title: "Text Editor", glyph: Icons.notepad, width: 620, height: 460,
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
      function setName() { fname.textContent = path || "(unsaved)"; win.el.querySelector(".title").textContent = "Text Editor - " + (path ? path.split("/").pop() : "Untitled"); }
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
          function openInto(res) { ta.value = res.content || ""; path = p; setName(); }
          A3.request("fs_read", { path: p }).then(function (res) {
            if (res.error && res.error !== "") { Modal.alert("Open", "Cannot open file."); return; }
            if (res.locked) { // password-protected (#7): verify before showing content
              Modal.prompt("This file is password protected. Enter password:", "").then(function (pass) {
                if (pass == null) return;
                A3.request("fs_unlock", { path: p, pass: pass }).then(function (r2) {
                  if (r2.error === "bad_pass") { Modal.alert("Locked", "Wrong password."); return; }
                  if (r2.error && r2.error !== "") { Modal.alert("Open", "Cannot open file."); return; }
                  openInto(r2);
                });
              });
              return;
            }
            openInto(res);
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
    id: "settings", title: "Settings", glyph: Icons.settings, width: 560, height: 400,
    showOnDesktop: true, showInDock: true, singleton: true,
    render: function (body) {
      body.innerHTML =
        '<div class="pad">' +
          '<h3>System</h3><div id="sysinfo" class="muted">Reading&hellip;</div>' +
          '<h3 style="margin-top:14px">Personalisation</h3>' +
          '<div style="display:flex;flex-direction:column;gap:8px;max-width:420px">' +
            '<label class="muted">System name (hostname)</label>' +
            '<input class="input shost" placeholder="ae3-os">' +
            '<label class="muted">Wallpaper (CSS colour/gradient or image path, blank = default)</label>' +
            '<input class="input swall" placeholder="#1d1d1d or linear-gradient(...) or \\\\z\\\\...\\\\bg.jpg">' +
            '<div><button class="btn accent ssave">Apply</button> <span class="muted sst"></span></div>' +
          '</div>' +
        '</div>';
      var box = body.querySelector("#sysinfo");
      var hostEl = body.querySelector(".shost");
      var wallEl = body.querySelector(".swall");
      A3.request("sysinfo", {}).then(function (s) {
        s = s || {};
        box.innerHTML =
          "Hostname: " + esc(s.hostname || "?") + "<br>" +
          "IP: " + esc(s.ip || "?") + " &nbsp; Gateway: " + esc(s.gateway || "?") + "<br>" +
          "Power: " + esc(s.power || "?") + " &nbsp; Battery: " + (s.battery != null ? s.battery + "%" : "?") + "<br>" +
          "Uptime: " + esc(s.uptime || "?");
        if (hostEl) hostEl.value = s.hostname || "";
        if (wallEl) wallEl.value = s.wallpaper || "";
      }).catch(function () { box.textContent = "Unavailable"; });

      body.querySelector(".ssave").addEventListener("click", function () {
        var host = hostEl.value.trim(), wall = wallEl.value.trim();
        var st = body.querySelector(".sst");
        A3.request("sys_set", { hostname: host, wallpaper: wall }).then(function (r) {
          if (r && r.error && r.error !== "") { st.textContent = "Failed."; return; }
          st.textContent = "Applied.";
          if (host) Desktop.setHostname(host);          // reflect immediately on this client (#15)
          Desktop.setWallpaper(wall);
        });
      });
    }
  });

  // ---------------- Network (#11) ----------------
  Apps.register({
    id: "network", title: "Network", glyph: Icons.network, width: 560, height: 380,
    showInDock: true,
    render: function (body) {
      body.innerHTML = '<div class="pad"><div style="display:flex;align-items:center"><h3 style="flex:1">Wireless networks</h3><span class="muted nstat" style="margin-right:8px"></span><button class="btn rescan">Rescan</button></div><ul class="list nets"><li class="muted">Scanning&hellip;</li></ul></div>';
      var nets = body.querySelector(".nets");
      var statEl = body.querySelector(".nstat");
      // Password-protected routers (#14): prompt before connecting, then send the password.
      function connect(n) {
        if (n.locked) {
          Modal.prompt("Network '" + n.ssid + "' is password protected:", "").then(function (pw) {
            if (pw == null) return;
            A3.send("net_connect", { netId: n.netId, password: pw });
            setTimeout(scan, 900);
          });
        } else {
          A3.send("net_connect", { netId: n.netId });
          setTimeout(scan, 900);
        }
      }
      function scan() {
        nets.innerHTML = '<li class="muted">Scanning&hellip;</li>';
        A3.request("net_scan", {}).then(function (list) {
          nets.innerHTML = "";
          (list || []).forEach(function (n) {
            var lock = n.locked ? ' <span class="muted" title="Password protected">&#128274;</span>' : "";
            var li = h('<li><span class="ico">' + Icons.wifi + '</span><span>' + esc(n.ssid) + lock + (n.current ? " <span class=\"muted\">(connected)</span>" : "") +
              "</span><span class=\"muted\" style=\"margin-left:auto\">" + esc(n.ip || "") + "</span></li>");
            var btn = document.createElement("button");
            btn.className = "btn"; btn.style.marginLeft = "6px";
            btn.textContent = n.current ? "Disconnect" : "Connect";
            btn.addEventListener("click", function (e) {
              e.stopPropagation();
              if (n.current) { A3.send("net_disconnect", {}); setTimeout(scan, 800); } else connect(n);
            });
            li.appendChild(btn);
            li.addEventListener("dblclick", function () { if (!n.current) connect(n); });
            nets.appendChild(li);
          });
          if (!list || !list.length) nets.innerHTML = '<li class="muted">No networks in range</li>';
        }).catch(function () { nets.innerHTML = '<li class="muted">Network stack unavailable</li>'; });
      }
      // Server connect verdict (range/password) (#14).
      A3.on("net_result", function (r) {
        if (!statEl) return;
        statEl.textContent = (r && r.msg) || "";
        statEl.style.color = (r && r.ok) ? "var(--good)" : "#ff8a6a";
        setTimeout(scan, 300);
      });
      body.querySelector(".rescan").addEventListener("click", scan);
      scan();
    }
  });

  // ---------------- Calendar (#12: month/year nav + go-to-date + intel events) ----------------
  // Events are intel/lore entries (meetings, sightings) attached to a date. The full set is fetched
  // ONCE on open and cached, so month/year navigation is instant (the old per-nav request made
  // navigation feel frozen). Clicking a day shows its events and an add/delete form.
  Apps.register({
    id: "calendar", title: "Calendar", glyph: Icons.calendar, width: 560, height: 560,
    showInDock: true, singleton: true,
    render: function (body) {
      var months = ["January","February","March","April","May","June","July","August","September","October","November","December"];
      var view = new Date(); view.setDate(1);
      var events = {};       // iso -> [{date,title,location,body,index}]
      var selIso = null;
      // Full-height layout (#3): toolbars + grid keep their size, the day/event panel grows to fill
      // the rest of the window instead of being capped to a small inner-scroll box.
      body.style.display = "flex"; body.style.flexDirection = "column";
      body.innerHTML =
        '<div class="toolbar">' +
          '<button class="btn py" title="Previous year">&#171;</button>' +
          '<button class="btn pm" title="Previous month">&#8249;</button>' +
          '<span class="hdr" style="flex:1;text-align:center;font-weight:600"></span>' +
          '<button class="btn nm" title="Next month">&#8250;</button>' +
          '<button class="btn ny" title="Next year">&#187;</button>' +
        '</div>' +
        '<div class="toolbar"><input class="input goto" type="date" style="flex:1"><button class="btn accent go">Go</button><button class="btn today">Today</button><button class="btn refresh" title="Refresh">&#8635;</button></div>' +
        '<div class="grid" style="display:grid;grid-template-columns:repeat(7,1fr);gap:2px;padding:8px"></div>' +
        '<div class="detail pad" style="border-top:1px solid var(--line);flex:1;min-height:0;overflow:auto"><p class="muted">Select a day to view or add events.</p></div>';
      var hdr = body.querySelector(".hdr");
      var grid = body.querySelector(".grid");
      var detail = body.querySelector(".detail");

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
          var cell = h('<div data-iso="' + iso + '" style="text-align:center;padding:8px 0;border-radius:6px;cursor:pointer;' +
            (iso === selIso ? "outline:2px solid var(--accent);" : "") +
            (isToday ? "background:var(--accent);color:#fff;" : "background:var(--surface-2);") + '">' + d +
            (has ? '<div style="font-size:9px;color:#ffd2c2">&#9679;</div>' : "") + "</div>");
          cell.addEventListener("click", function () { showDay(this.getAttribute("data-iso")); });
          grid.appendChild(cell);
        }
      }

      function showDay(iso) {
        selIso = iso; draw();
        var list = events[iso] || [];
        var html = '<div style="display:flex;align-items:center"><h3 style="flex:1;margin:0">' + esc(iso) + '</h3></div>';
        if (!list.length) html += '<p class="muted">No events.</p>';
        list.forEach(function (e) {
          html += '<div class="ev" data-idx="' + e.index + '" style="margin:8px 0;padding:8px;background:var(--surface-2);border-radius:6px">' +
            '<div style="display:flex;align-items:center"><b style="flex:1">' + esc(e.title) + '</b><button class="btn evdel" data-idx="' + e.index + '">&#215;</button></div>' +
            (e.location ? '<div class="muted" style="font-size:12px">@ ' + esc(e.location) + '</div>' : "") +
            (e.body ? '<div style="margin-top:4px;white-space:pre-wrap">' + esc(e.body) + '</div>' : "") +
            '</div>';
        });
        html += '<hr style="border-color:var(--line)"><div style="display:flex;flex-direction:column;gap:6px">' +
          '<input class="input ntitle" placeholder="New event title">' +
          '<input class="input nloc" placeholder="Location (optional)">' +
          '<textarea class="input nbody" rows="3" placeholder="Details (optional)"></textarea>' +
          '<div><button class="btn accent nadd">Add event</button> <span class="muted nst"></span></div></div>';
        detail.innerHTML = html;
        detail.querySelectorAll(".evdel").forEach(function (b) {
          b.addEventListener("click", function () {
            A3.request("cal_delete", { index: +this.getAttribute("data-idx") }).then(function () { setTimeout(function () { fetchAll(iso); }, 350); });
          });
        });
        detail.querySelector(".nadd").addEventListener("click", function () {
          var title = detail.querySelector(".ntitle").value.trim();
          var st = detail.querySelector(".nst");
          if (!title) { st.textContent = "Title required."; return; }
          A3.request("cal_add", { date: iso, title: title, location: detail.querySelector(".nloc").value, body: detail.querySelector(".nbody").value }).then(function (r) {
            st.textContent = (r && r.error && r.error !== "") ? ("Failed: " + r.error) : "Added.";
            if (!r || !r.error || r.error === "") setTimeout(function () { fetchAll(iso); }, 350);
          });
        });
      }

      function fetchAll(reopenIso) {
        A3.request("cal_list", {}).then(function (list) {
          events = {};
          (list || []).forEach(function (e) { events[e.date] = (events[e.date] || []).concat(e); });
          draw();
          if (reopenIso) showDay(reopenIso);
        }).catch(draw);
      }

      body.querySelector(".pm").addEventListener("click", function () { view.setMonth(view.getMonth() - 1); draw(); });
      body.querySelector(".nm").addEventListener("click", function () { view.setMonth(view.getMonth() + 1); draw(); });
      body.querySelector(".py").addEventListener("click", function () { view.setFullYear(view.getFullYear() - 1); draw(); });
      body.querySelector(".ny").addEventListener("click", function () { view.setFullYear(view.getFullYear() + 1); draw(); });
      body.querySelector(".today").addEventListener("click", function () { view = new Date(); view.setDate(1); draw(); });
      body.querySelector(".refresh").addEventListener("click", function () { fetchAll(selIso); });
      // Live update when the store changes server-side (Zeus/Eden module add, #4).
      A3.on("cal_changed", function () { fetchAll(selIso); });
      body.querySelector(".go").addEventListener("click", function () {
        var v = body.querySelector(".goto").value; if (!v) return;
        var p = v.split("-"); view = new Date(+p[0], +p[1] - 1, 1); draw(); showDay(v);
      });
      fetchAll();
    }
  });

  // ---------------- Browser (#18: real pages incl. the wiki rendered from markdown) ----------------
  // CEF cannot resolve relative <iframe src> from a PBO file, so pages are fetched through
  // A3.loadFile and shown via iframe.srcdoc (self-contained). The wiki's *.md (vendored from the
  // repo wiki/) are rendered client-side with MD.render. Links inside the iframe are intercepted
  // and routed back to the address bar via window.AE3_browserNav.
  Apps.register({
    id: "browser", title: "Browser", glyph: Icons.browser, width: 820, height: 560,
    showOnDesktop: true, showInDock: true,
    render: function (body, win) {
      // Friendly names -> bundled pages. Addresses may also be explicit paths: an absolute VFS path
      // into any loaded mod (\z\othermod\...\page.html) or a mission-relative path
      // (sites/intel/report.md), both resolved through A3.loadFile's root search.
      var sites = {
        "home":    { type: "html", path: "sites/portal/index.html", label: "home" },
        "rootnet": { type: "html", path: "sites/portal/index.html", label: "rootnet" },
        "wiki":    { type: "md",   path: "wiki/Home.md",            label: "wiki" }
      };

      // Injected into every page so in-page links drive the address bar instead of dead relative nav.
      // Arma's CEF renders iframe srcdoc with an opaque origin, so a direct parent.AE3_browserNav()
      // call throws a cross-origin SecurityError (the old dead-link bug, #5). postMessage is
      // origin-agnostic and always reaches the host window, where a single listener routes it.
      var HOOK = '<script>document.addEventListener("click",function(e){' +
        'var a=e.target&&e.target.closest?e.target.closest("a"):null;if(!a)return;' +
        'var href=a.getAttribute("href")||"";' +
        'if(href&&href.charAt(0)!=="#"){e.preventDefault();try{parent.postMessage({__ae3nav:href},"*");}catch(_){}}});<\/script>';

      // One host-side listener (added once) forwards in-page link clicks to whichever browser
      // window is currently active (window.AE3_browserNav is rebound on nav/focus below).
      if (!window.AE3_navListener) {
        window.AE3_navListener = true;
        window.addEventListener("message", function (e) {
          var d = e && e.data;
          if (d && typeof d.__ae3nav === "string" && typeof window.AE3_browserNav === "function") {
            window.AE3_browserNav(d.__ae3nav);
          }
        });
      }

      function wikiDoc(htmlBody) {
        return '<!DOCTYPE html><html><head><meta charset="utf-8"><style>' +
          'body{margin:0;font-family:"Ubuntu","Noto Sans",sans-serif;color:#222;background:#fff;line-height:1.55}' +
          '.wrap{max-width:860px;margin:0 auto;padding:26px 34px}' +
          'h1,h2,h3{color:#c7411f;margin:1.1em 0 .4em}h1{border-bottom:2px solid #eee;padding-bottom:.2em}' +
          'a{color:#e95420;text-decoration:none}a:hover{text-decoration:underline}' +
          'code{background:#f0f0f0;padding:1px 5px;border-radius:4px;font-family:monospace;font-size:.92em}' +
          'pre{background:#2b2b2b;color:#eee;padding:12px 14px;border-radius:8px;overflow:auto}pre code{background:none;color:inherit;padding:0}' +
          'blockquote{border-left:3px solid #e95420;margin:.6em 0;padding:.2em 12px;color:#555;background:#faf3f0}' +
          'ul,ol{padding-left:22px}hr{border:none;border-top:1px solid #e2e2e2;margin:1.2em 0}' +
          '</style></head><body><div class="wrap">' + htmlBody + '</div>' + HOOK + '</body></html>';
      }

      body.innerHTML =
        '<div class="toolbar">' +
          '<button class="btn back" title="Back">&#8592;</button><button class="btn fwd" title="Forward">&#8594;</button>' +
          '<button class="btn home" title="Home">&#8962;</button>' +
          '<input class="input addr" style="flex:1" value="home">' +
          '<button class="btn accent go">Go</button>' +
        '</div>' +
        '<iframe class="page" style="width:100%;height:calc(100% - 50px);border:none;background:#fff"></iframe>';
      var frame = body.querySelector(".page");
      var addrEl = body.querySelector(".addr");
      var history = [], hi = -1;
      var curDir = ""; // directory of the page currently shown, so relative in-page links resolve

      function setDoc(htmlText) { frame.srcdoc = htmlText + HOOK; }

      // Directory portion of a path ("sites/portal/index.html" -> "sites/portal/"). "" for bare names.
      function dirOf(p) {
        var s = String(p).replace(/\\/g, "/");
        var i = s.lastIndexOf("/");
        return i < 0 ? "" : s.slice(0, i + 1);
      }
      // True for an absolute VFS path (\z\mod\...) or a drive path - these are NOT page-relative.
      function isAbsolute(addr) { return addr.charAt(0) === "\\" || addr.charAt(0) === "/" || /^[a-z]:/i.test(addr); }

      function resolve(addrRaw) {
        var addr = String(addrRaw == null ? "home" : addrRaw).trim();
        var hasPath = addr.charAt(0) === "\\" || /^[a-z]:/i.test(addr) || addr.indexOf("/") >= 0 || addr.indexOf("\\") >= 0;
        var mdName = addr.match(/([^\/\\]+\.md)(?:[#?].*)?$/i); // keep original case for the VFS lookup

        // Explicit .md: a bare filename is a wiki page; a pathed .md (mod/mission) loads as given.
        if (/\.md($|[#?])/i.test(addr)) {
          if (mdName && !hasPath) return { type: "md", path: "wiki/" + mdName[1], label: mdName[1] };
          return { type: "md", path: addr, label: addr };
        }
        // Explicit .html / any pathed address: load through the root search (mod or mission). A
        // page-relative href (e.g. portal's "../wiki/index.html") is joined to the current page's
        // directory; bridge.loadFile then collapses the ".." so A3API gets a clean path (#1).
        if (/\.html?($|[#?])/i.test(addr) || hasPath) {
          var p = (hasPath && !isAbsolute(addr)) ? (curDir + addr) : addr;
          return { type: "html", path: p, label: addr };
        }

        var lower = addr.toLowerCase().replace(/^https?:\/\//, "").replace(/\/+$/, "");
        if (sites[lower]) return sites[lower];
        if (lower.indexOf("wiki") >= 0) return sites.wiki;
        return sites.home;
      }

      function load(t) {
        addrEl.value = t.label;
        curDir = dirOf(t.path); // base for any relative links on the page we are about to show
        if (t.type === "md") {
          A3.loadFile(t.path).then(function (mdText) {
            setDoc(wikiDoc(MD.render(mdText || "")));
          }).catch(function (e) { console.error("[AE3] browser md load failed:", t.path, e); setDoc(wikiDoc("<h1>Page not found</h1><p><a href=\"Home.md\">Back to wiki home</a></p>")); });
        } else {
          A3.loadFile(t.path).then(function (htmlText) {
            setDoc(htmlText || "<p>Empty page.</p>");
          }).catch(function (e) { console.error("[AE3] browser html load failed:", t.path, e); setDoc("<p style='font-family:sans-serif;padding:20px'>Page unavailable.</p>"); });
        }
      }

      function nav(addrRaw, fromHistory) {
        var t = resolve(addrRaw);
        if (!fromHistory) { history = history.slice(0, hi + 1); history.push(t.label); hi = history.length - 1; }
        window.AE3_browserNav = function (href) { nav(href); }; // active browser drives in-page links
        load(t);
      }

      body.querySelector(".go").addEventListener("click", function () { nav(addrEl.value); });
      body.querySelector(".home").addEventListener("click", function () { nav("home"); });
      body.querySelector(".back").addEventListener("click", function () { if (hi > 0) { hi--; nav(history[hi], true); } });
      body.querySelector(".fwd").addEventListener("click", function () { if (hi < history.length - 1) { hi++; nav(history[hi], true); } });
      addrEl.addEventListener("keydown", function (e) { if (e.key === "Enter") nav(addrEl.value); });

      // Re-bind the in-page link hook to this window whenever it gains focus.
      win.el.addEventListener("mousedown", function () { window.AE3_browserNav = function (href) { nav(href); }; });

      nav("home");
    }
  });

  // ---------------- Map (#6/#13/#20: in-window minimap, terrain image + blips) ----------------
  // Renders a player-centred minimap from map_data (self/router/device blips). A static terrain
  // image is drawn underneath when one is registered for the world (window.AE3_MAP_IMAGES[world] =
  // url, populated by mission/asset content); otherwise a styled terrain backdrop + grid is used so
  // the map is always informative (the old version could show a blank olive panel).
  Apps.register({
    id: "map", title: "Map", glyph: Icons.map, width: 540, height: 560,
    showInDock: true, singleton: true,
    render: function (body, win) {
      body.innerHTML =
        '<div class="toolbar"><span class="muted world" style="flex:1"></span>' +
          '<button class="btn fullmap accent" title="Open the real in-game map">Full Map</button>' +
          '<button class="btn zin" title="Zoom in">+</button><button class="btn zout" title="Zoom out">&#8211;</button></div>' +
        '<div class="mapwrap" style="position:relative;height:calc(100% - 50px)">' +
          '<canvas class="map" style="display:block;width:100%;height:100%;background:#1b2a1b"></canvas>' +
          '<div class="legend muted" style="position:absolute;left:8px;bottom:6px;font-size:11px">' +
            '<span style="color:#e95420">&#9679;</span> you &nbsp;<span style="color:#5da8e8">&#9679;</span> router &nbsp;<span style="color:#8ce10b">&#9679;</span> device</div>' +
        '</div>';
      var cv = body.querySelector(".map");
      var wrap = body.querySelector(".mapwrap");
      var worldEl = body.querySelector(".world");
      var range = 250;
      var bgImg = null, bgWorld = null;

      function ensureImage(world) {
        if (world === bgWorld) return;
        bgWorld = world; bgImg = null;
        var src = (window.AE3_MAP_IMAGES || {})[world];
        if (src) { var im = new Image(); im.onload = function () { bgImg = im; }; im.src = src; }
      }

      function draw(d) {
        var world = d && d.world ? d.world : "";
        ensureImage(world);
        worldEl.textContent = (world || "(unknown)") + " - " + Math.round(range) + "m";
        // Measure from the wrapper (robust if the canvas hasn't been laid out yet).
        var w = cv.clientWidth || wrap.clientWidth || 480;
        var hh = cv.clientHeight || (wrap.clientHeight - 0) || 440;
        cv.width = w; cv.height = hh;
        var ctx = cv.getContext("2d");
        if (!ctx) return;
        var cx = w / 2, cy = hh / 2, scale = (Math.min(w, hh) / 2) / range;

        // Backdrop: terrain image if available, else a tinted gradient.
        if (bgImg) {
          ctx.drawImage(bgImg, 0, 0, w, hh);
          ctx.fillStyle = "rgba(10,20,10,0.25)"; ctx.fillRect(0, 0, w, hh);
        } else {
          var grd = ctx.createRadialGradient(cx, cy, 10, cx, cy, Math.max(w, hh) / 1.4);
          grd.addColorStop(0, "#243524"); grd.addColorStop(1, "#141f14");
          ctx.fillStyle = grd; ctx.fillRect(0, 0, w, hh);
        }

        // Range grid + rings.
        ctx.strokeStyle = "rgba(255,255,255,0.08)";
        for (var g = -range; g <= range; g += 50) {
          ctx.beginPath(); ctx.moveTo(cx + g * scale, 0); ctx.lineTo(cx + g * scale, hh); ctx.stroke();
          ctx.beginPath(); ctx.moveTo(0, cy + g * scale); ctx.lineTo(w, cy + g * scale); ctx.stroke();
        }
        ctx.strokeStyle = "rgba(255,255,255,0.15)";
        [range / 2, range].forEach(function (r) {
          ctx.beginPath(); ctx.arc(cx, cy, r * scale, 0, 2 * Math.PI); ctx.stroke();
        });
        // North marker.
        ctx.fillStyle = "rgba(255,255,255,0.6)"; ctx.font = "11px sans-serif"; ctx.textAlign = "center";
        ctx.fillText("N", cx, 12); ctx.textAlign = "start";

        (d && d.blips ? d.blips : []).forEach(function (b) {
          if (b.kind === "self") return; // player drawn at centre below
          var x = cx + b.dx * scale, y = cy - b.dy * scale;
          var color = b.kind === "router" ? "#5da8e8" : "#8ce10b";
          ctx.fillStyle = color; ctx.beginPath(); ctx.arc(x, y, 5, 0, 2 * Math.PI); ctx.fill();
          if (b.label) { ctx.fillStyle = "#ddd"; ctx.font = "11px sans-serif"; ctx.fillText(b.label, x + 7, y + 3); }
        });

        // Player at centre as a heading triangle.
        var dir = (d && typeof d.dir === "number" ? d.dir : 0) * Math.PI / 180;
        ctx.save(); ctx.translate(cx, cy); ctx.rotate(dir);
        ctx.fillStyle = "#e95420"; ctx.beginPath();
        ctx.moveTo(0, -8); ctx.lineTo(5, 6); ctx.lineTo(0, 3); ctx.lineTo(-5, 6); ctx.closePath(); ctx.fill();
        ctx.restore();
      }

      function refresh() { A3.request("map_data", { range: range }).then(draw).catch(function (e) { console.error("[AE3] map_data failed:", e); draw(null); }); }
      body.querySelector(".fullmap").addEventListener("click", function () { A3.send("map_open", {}); });
      body.querySelector(".zin").addEventListener("click", function () { range = Math.max(50, range / 1.5); refresh(); });
      body.querySelector(".zout").addEventListener("click", function () { range = Math.min(2000, range * 1.5); refresh(); });
      win.timer = setInterval(refresh, 2000);
      win.app.onClose = function (w) { if (w.timer) clearInterval(w.timer); };
      refresh();
    }
  });

  // ---------------- Cryptography: Crypto (#9) ----------------
  Apps.register({
    id: "crypto", title: "Crypto", glyph: Icons.crypto, width: 520, height: 440, showInDock: false,
    render: function (body) {
      body.innerHTML =
        '<div class="pad" style="display:flex;flex-direction:column;gap:8px;height:100%">' +
          '<div style="display:flex;gap:8px">' +
            '<select class="input cmode" style="flex:1"><option value="encrypt">Encrypt</option><option value="decrypt">Decrypt</option></select>' +
            '<select class="input calgo" style="flex:1"><option value="caesar">Caesar</option><option value="columnar">Columnar</option></select>' +
          '</div>' +
          '<input class="input ckey" placeholder="Key (caesar: number, columnar: word)">' +
          '<textarea class="input ctext" rows="4" placeholder="Text to process"></textarea>' +
          '<div><button class="btn accent crun">Run</button></div>' +
          '<textarea class="input cout" rows="4" readonly placeholder="Result"></textarea>' +
        '</div>';
      function err(e) { return ({ no_input: "Enter some text.", bad_key: "Invalid key.", bad_mode: "Pick a mode.", len_mismatch: "Key/message length mismatch.", bad_algo: "Bad algorithm." })[e] || e; }
      body.querySelector(".crun").addEventListener("click", function () {
        A3.request("crypto_run", {
          mode: body.querySelector(".cmode").value, algorithm: body.querySelector(".calgo").value,
          key: body.querySelector(".ckey").value, text: body.querySelector(".ctext").value
        }).then(function (r) {
          body.querySelector(".cout").value = (r && r.error && r.error !== "") ? ("Error: " + err(r.error)) : ((r && r.result) || "");
        });
      });
    }
  });

  // ---------------- Cryptography: Crack (#9) ----------------
  Apps.register({
    id: "crack", title: "Crack", glyph: Icons.crack, width: 560, height: 480, showInDock: false,
    render: function (body) {
      body.innerHTML =
        '<div class="pad" style="display:flex;flex-direction:column;gap:8px;height:100%">' +
          '<div style="display:flex;gap:8px">' +
            '<select class="input kmode" style="flex:1"><option value="bruteforce">Bruteforce</option><option value="statistics">Statistics</option><option value="key">Key length</option></select>' +
            '<select class="input kalgo" style="flex:1"><option value="caesar">Caesar</option><option value="columnar">Columnar</option></select>' +
          '</div>' +
          '<textarea class="input ktext" rows="3" placeholder="Ciphertext"></textarea>' +
          '<div><button class="btn accent krun">Analyse</button></div>' +
          '<pre class="kout" style="flex:1;overflow:auto;background:#1e1e1e;padding:10px;border-radius:6px;margin:0;white-space:pre-wrap;font-family:monospace;font-size:12px"></pre>' +
        '</div>';
      function err(e) { return ({ no_input: "Enter ciphertext.", unsupported: "Not available for this cipher.", prime_length: "Message length is prime - no columns.", bad_algo: "Bad algorithm." })[e] || e; }
      body.querySelector(".krun").addEventListener("click", function () {
        A3.request("crack_run", {
          mode: body.querySelector(".kmode").value, algorithm: body.querySelector(".kalgo").value,
          text: body.querySelector(".ktext").value
        }).then(function (r) {
          var out = body.querySelector(".kout");
          if (r && r.error && r.error !== "") { out.textContent = "Error: " + err(r.error); return; }
          out.textContent = ((r && r.lines) || []).join("\n");
        });
      });
    }
  });

  // ---------------- Games: Snake (#9) ----------------
  Apps.register({
    id: "snake", title: "Snake", glyph: Icons.snake, width: 420, height: 460, showInDock: false,
    render: function (body, win) {
      body.innerHTML =
        '<div class="pad" style="display:flex;flex-direction:column;gap:8px;height:100%;align-items:center">' +
          '<div class="muted sstat">Score: 0 — arrow keys / WASD</div>' +
          '<canvas class="sgame" width="360" height="360" style="background:#10160f;border-radius:6px"></canvas>' +
          '<div><button class="btn accent sgo">New game</button></div>' +
        '</div>';
      var cv = body.querySelector(".sgame"), ctx = cv.getContext("2d");
      var stat = body.querySelector(".sstat");
      var N = 18, cell = cv.width / N;
      var snake, dir, food, score, over, timer = null;
      function place() { food = { x: Math.floor(Math.random() * N), y: Math.floor(Math.random() * N) }; }
      function reset() {
        snake = [{ x: 9, y: 9 }]; dir = { x: 1, y: 0 }; score = 0; over = false; place();
        stat.textContent = "Score: 0";
        if (timer) clearInterval(timer); timer = setInterval(step, 130);
      }
      function step() {
        if (over) return;
        var head = { x: (snake[0].x + dir.x + N) % N, y: (snake[0].y + dir.y + N) % N };
        if (snake.some(function (s) { return s.x === head.x && s.y === head.y; })) { over = true; stat.textContent = "Game over — score " + score; return; }
        snake.unshift(head);
        if (head.x === food.x && head.y === food.y) { score++; stat.textContent = "Score: " + score; place(); } else { snake.pop(); }
        draw();
      }
      function draw() {
        ctx.fillStyle = "#10160f"; ctx.fillRect(0, 0, cv.width, cv.height);
        ctx.fillStyle = "#e95420"; ctx.fillRect(food.x * cell, food.y * cell, cell - 1, cell - 1);
        ctx.fillStyle = "#8ce10b";
        snake.forEach(function (s) { ctx.fillRect(s.x * cell, s.y * cell, cell - 1, cell - 1); });
      }
      function key(e) {
        var k = e.key.toLowerCase();
        if ((k === "arrowup" || k === "w") && dir.y === 0) dir = { x: 0, y: -1 };
        else if ((k === "arrowdown" || k === "s") && dir.y === 0) dir = { x: 0, y: 1 };
        else if ((k === "arrowleft" || k === "a") && dir.x === 0) dir = { x: -1, y: 0 };
        else if ((k === "arrowright" || k === "d") && dir.x === 0) dir = { x: 1, y: 0 };
        else return;
        e.preventDefault();
      }
      document.addEventListener("keydown", key);
      body.querySelector(".sgo").addEventListener("click", reset);
      win.app.onClose = function () { if (timer) clearInterval(timer); document.removeEventListener("keydown", key); };
      reset();
    }
  });

  // ---------------- Recycle Bin (#17) ----------------
  Apps.register({
    id: "recyclebin", title: "Recycle Bin", glyph: Icons.trash, width: 560, height: 420, showInDock: false, singleton: true,
    render: function (body) {
      body.innerHTML =
        '<div class="toolbar"><button class="btn refresh">&#8635;</button><button class="btn restore">Restore</button><button class="btn empty">Empty Bin</button></div>' +
        '<ul class="list trash"><li class="muted pad">Loading…</li></ul>';
      var listEl = body.querySelector(".trash");
      var sel = null;
      function load() {
        sel = null;
        A3.request("fs_list", { path: "/.trash" }).then(function (res) {
          listEl.innerHTML = "";
          if (res.error && res.error !== "") { listEl.innerHTML = '<li class="muted pad">Recycle Bin is empty.</li>'; return; }
          var items = res.entries || [];
          if (!items.length) { listEl.innerHTML = '<li class="muted pad">Recycle Bin is empty.</li>'; return; }
          items.forEach(function (it) {
            var li = h('<li><span class="ico">' + (it.dir ? Icons.folder : Icons.file) + '</span><span>' + esc(it.name) + "</span></li>");
            li.addEventListener("click", function () {
              listEl.querySelectorAll("li").forEach(function (n) { n.classList.remove("sel"); });
              li.classList.add("sel"); sel = it.name;
            });
            listEl.appendChild(li);
          });
        }).catch(function () { listEl.innerHTML = '<li class="muted pad">Recycle Bin is empty.</li>'; });
      }
      body.querySelector(".refresh").addEventListener("click", load);
      body.querySelector(".restore").addEventListener("click", function () {
        if (!sel) return;
        A3.request("fs_restore", { name: sel }).then(function (r) {
          if (r.error && r.error !== "") Modal.alert("Restore", "Could not restore."); else load();
        });
      });
      body.querySelector(".empty").addEventListener("click", function () {
        Modal.confirm("Empty Bin", "Permanently delete all items?").then(function (ok) {
          if (!ok) return;
          A3.request("fs_empty_trash", {}).then(load);
        });
      });
      load();
    }
  });

  // ---------------- Mail (#18) ----------------
  Apps.register({
    id: "mail", title: "Mail", glyph: Icons.mail, width: 760, height: 480,
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
    id: "messenger", title: "Messenger", glyph: Icons.messenger, width: 600, height: 480,
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
    id: "about", title: "About OS", glyph: Icons.about, width: 420, height: 260, singleton: true,
    render: function (body) {
      body.innerHTML =
        '<div class="pad" style="text-align:center">' +
          '<div style="font-size:48px;color:var(--accent)">' + Icons.terminal + '</div><h2>armaOS</h2>' +
          '<p class="muted">Advanced Equipment Revamped</p>' +
          '<p class="muted">Powered by SHITE Technologies</p></div>';
    }
  });
})();
