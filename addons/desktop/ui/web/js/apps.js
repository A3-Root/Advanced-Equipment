/*
 * AE3 built-in apps on the Ubuntu shell. Each app registers a descriptor whose render(body, win,
 * args) populates the window. Filesystem apps talk to the SQF backend (AE3_desktop_fnc_fsHandle)
 * via A3.request; permissions and per-user scoping are enforced server-side in SQF.
 */
(function () {
  function h(html) { var d = document.createElement("div"); d.innerHTML = html.trim(); return d.firstElementChild; }
  function esc(s) { return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;"); }
  function joinPath(dir, name) { return (dir.replace(/\/+$/, "") + "/" + name).replace(/\/+/g, "/"); }
  function seedIpPrefix(body, selector, currentPrefix) {
    A3.request("sysinfo", {}).then(function (s) {
      var gateway = String((s && s.gateway) || "");
      var ip = String((s && s.ip) || "");
      var source = (gateway && gateway !== "-" && gateway !== "127.0.0.1") ? gateway : ip;
      var parts = source.split(".");
      if (parts.length === 4 && source !== "127.0.0.1") currentPrefix.value = parts.slice(0, 3).join(".") + ".";
      var inp = body.querySelector(selector);
      // Replace an empty field or a still-untouched bare prefix (ends with "."), but never a target
      // the user has already typed in full.
      if (inp && (inp.value === "" || (/\.$/).test(inp.value))) inp.value = currentPrefix.value;
    }).catch(function () {});
  }

  // Shared file Properties dialog (owner + read/write/execute matrix for Owner and Everyone), used by
  // both the Files browser and the desktop surface so the two stay identical. `it` is { name, dir };
  // onSaved (optional) is called after a successful permission change so the caller can refresh.
  window.AE3_showProperties = function (full, it, onSaved) {
    A3.request("fs_stat", { path: full }).then(function (res) {
      if (!res || (res.error && res.error !== "")) { Modal.alert("Properties", "Cannot read properties."); return; }
      var perms = res.permissions || [[false, false, false], [false, false, false]];
      var ov = h('<div class="pk-overlay"><div class="pk-dialog" style="width:420px;height:auto;min-height:0">' +
        '<div class="pk-title">Properties</div>' +
        '<div class="pad" style="display:flex;flex-direction:column;gap:10px">' +
          '<div><b>' + esc(it.name) + '</b></div>' +
          '<div class="muted">Owner: ' + esc(res.owner || "") + '</div>' +
          '<table style="width:100%;border-collapse:collapse"><thead><tr><th></th><th>Read</th><th>Write</th><th>Execute</th></tr></thead>' +
            '<tbody><tr><td>Owner</td><td><input type="checkbox" class="or"></td><td><input type="checkbox" class="ow"></td><td><input type="checkbox" class="ox"></td></tr>' +
            '<tr><td>Everyone</td><td><input type="checkbox" class="er"></td><td><input type="checkbox" class="ew"></td><td><input type="checkbox" class="ex"></td></tr></tbody></table>' +
          '<label style="display:flex;gap:8px;align-items:center"><input type="checkbox" class="rec"> Apply to folder contents</label>' +
          '<div style="display:flex;gap:8px;justify-content:flex-end"><button class="btn cancel">Cancel</button><button class="btn accent save">Save</button></div>' +
        '</div></div></div>');
      document.body.appendChild(ov);
      [[".or", 0, 0], [".ow", 0, 1], [".ox", 0, 2], [".er", 1, 0], [".ew", 1, 1], [".ex", 1, 2]].forEach(function (m) {
        ov.querySelector(m[0]).checked = !!(perms[m[1]] && perms[m[1]][m[2]]);
      });
      ov.querySelector(".rec").disabled = !it.dir;
      ov.querySelector(".cancel").addEventListener("click", function () { ov.remove(); });
      ov.querySelector(".save").addEventListener("click", function () {
        var next = [
          [ov.querySelector(".or").checked, ov.querySelector(".ow").checked, ov.querySelector(".ox").checked],
          [ov.querySelector(".er").checked, ov.querySelector(".ew").checked, ov.querySelector(".ex").checked]
        ];
        A3.request("fs_chmod", { path: full, permissions: next, recursive: !!ov.querySelector(".rec").checked }).then(function (r) {
          if (r.error && r.error !== "") { Modal.alert("Properties", "Permission denied."); return; }
          ov.remove(); if (onSaved) onSaved();
        });
      });
    });
  };

  // ---------------- Files ----------------
  // Reusable file-browser core (also powers My Computer's embedded pane and the file picker).
  // opts: { extraTools (HTML), onReady(api) }. Returns nothing; drives the given body element.
  // Exposed on window.AE3_FileBrowser so other apps reuse the exact same browser.
  window.AE3_FileBrowser = function (body, win, args, opts) {
    opts = opts || {};
    // Make the host a flex column so the list fills the pane: the entries <ul> then spans the
    // whole empty area, so right-clicking blank space hits it (empty-area menu) and a long list scrolls
    // instead of overflowing behind a dialog footer.
    body.style.display = "flex"; body.style.flexDirection = "column"; body.style.minHeight = "0";
    body.innerHTML =
      '<div class="toolbar">' +
        '<button class="btn up" title="Up">&#8593;</button>' +
        '<input class="input path" style="flex:1.4">' +
        '<input class="input search" placeholder="Search (use * )" style="flex:1">' +
        '<button class="btn mkdir">New Folder</button>' +
        '<button class="btn del">Delete</button>' +
        '<button class="btn refresh">&#8635;</button>' +
        (opts.extraTools || "") +
      '</div>' +
      '<ul class="list entries" tabindex="0"><li class="muted pad">Loading&hellip;</li></ul>';
    var cwd = (args && args.path) || "/";
    var sel = null;
    var searching = false;
    var entries = body.querySelector(".entries");
    var pathInput = body.querySelector(".path");
    var searchInput = body.querySelector(".search");

    function go(path) { cwd = path; searching = false; searchInput.value = ""; load(); }
    function desktopDir() {
      return ((window.AE3_HOME || "/root") + "/Desktop").replace(/\/+/g, "/");
    }
    function maybeRefreshDesktop(path) {
      var desk = desktopDir();
      if (path && (path === desk || path.indexOf(desk + "/") === 0) && window.Desktop && Desktop.refresh) Desktop.refresh();
    }

    var loadTries = 0;
    function load() {
      pathInput.value = cwd; sel = null;
      A3.request("fs_list", { path: cwd }).then(function (res) {
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
        var items = (res.entries || []).slice();
        // Folders first, then files; each group A->Z by name, case-insensitive.
        items.sort(function (a, b) {
          if (!!a.dir !== !!b.dir) return a.dir ? -1 : 1;
          return String(a.name).toLowerCase().localeCompare(String(b.name).toLowerCase());
        });
        if (!items.length) { entries.innerHTML = '<li class="muted pad">Empty</li>'; return; }
        items.forEach(function (it) { entries.appendChild(rowFor(it, joinPath(cwd, it.name))); });
      }).catch(function () { entries.innerHTML = '<li class="muted pad">Filesystem unavailable</li>'; });
    }

    function rowFor(it, full) {
      var link = it.link ? ' <span class="muted" title="Link &#8594; ' + esc(it.link) + '">&#8631;</span>' : "";
      // Row class drives the CSS tint by type: folders, .app programs/executables, plain files.
      var isApp = /\.app$/i.test(it.name);
      var cls = it.dir ? "isdir" : (isApp ? "isapp" : "isfile");
      var glyph = it.dir ? Icons.folder : (isApp ? Icons.app : Icons.file);
      var li = h('<li class="' + cls + '"><span class="ico">' + glyph + '</span><span>' + esc(it.name) + link + "</span></li>");
      li.addEventListener("click", function () {
        entries.querySelectorAll("li").forEach(function (n) { n.classList.remove("sel"); });
        li.classList.add("sel"); sel = { name: it.name, dir: it.dir, link: it.link, path: full };
      });
      li.addEventListener("dblclick", function () { activate(it, full); });
      li.addEventListener("contextmenu", function (e) {
        e.preventDefault(); e.stopPropagation();
        entries.querySelectorAll("li").forEach(function (n) { n.classList.remove("sel"); });
        li.classList.add("sel"); sel = { name: it.name, dir: it.dir, link: it.link, path: full };
        fileMenu(e.clientX, e.clientY, it, full);
      });
      return li;
    }

    // Open behaviour. An app-launcher (a .app symlink/file holding "app=<id>") launches the app;
    // a directory (or link to one) navigates; anything else opens in the default viewer.
    function activate(it, full) {
      if (it.dir) {
        // A link to a directory: navigate to the link target so the browser shows the real path.
        go(it.link && it.link !== "" ? it.link : full);
        return;
      }
      // Picker mode: a file double-click resolves the picker instead of opening it.
      if (opts.onPick) { opts.onPick(it, full); return; }
      if (/\.app$/i.test(it.name)) { launchLauncher(full); return; }
      openFile(it.link && it.link !== "" ? it.link : full);
    }

    function launchLauncher(path) {
      A3.request("fs_read", { path: path }).then(function (res) {
        if (res.error && res.error !== "") { Modal.alert("Open", "Cannot open launcher."); return; }
        var m = String(res.content || "").match(/app\s*=\s*([\w-]+)/i);
        if (m) { Apps.launch(m[1]); } else { Apps.launch("notepad", { path: path, content: res.content || "" }); }
      });
    }

    // Delegates to the shared opener (desktop.js) so the locked-file/password flow stays identical
    // between the Files app and the desktop surface.
    function openFile(path) { window.AE3_openFile(path); }

    function paste(destDir) {
      var cb = window.AE3_clipboard; if (!cb) return;
      var dest = joinPath(destDir, cb.name);
      A3.request(cb.op === "cut" ? "fs_move" : "fs_copy", { path: cb.path, dest: dest }).then(function (r) {
        if (r.error && r.error !== "") { Modal.alert("Paste", "Could not paste here."); return; }
        if (cb.op === "cut") window.AE3_clipboard = null;
        if (!searching) load();
        maybeRefreshDesktop(destDir);
        maybeRefreshDesktop(cb.path);
      });
    }
    function doRename(full, name) {
      Modal.prompt("Rename to", name).then(function (nn) {
        if (!nn || nn === name) return;
        var dir = full.replace(/\/+$/, "").split("/").slice(0, -1).join("/") || "/";
        A3.request("fs_move", { path: full, dest: joinPath(dir, nn) }).then(function (r) {
          if (r.error && r.error !== "") Modal.alert("Rename", "Could not rename."); else { load(); maybeRefreshDesktop(full); maybeRefreshDesktop(joinPath(dir, nn)); }
        });
      });
    }
    function doDelete(full) {
      A3.request("fs_delete", { path: full }).then(function (r) {
        if (r.error && r.error !== "") Modal.alert("Delete", "Permission denied."); else { load(); maybeRefreshDesktop(full); }
      });
    }
    function showProperties(full, it) { window.AE3_showProperties(full, it, load); }
    function fileMenu(x, y, it, full) {
      window.AE3_ctxMenu(x, y, [
        { label: "Open", action: function () { activate(it, full); } },
        { sep: true },
        { label: "Cut", action: function () { window.AE3_clipboard = { path: full, name: it.name, op: "cut" }; } },
        { label: "Copy", action: function () { window.AE3_clipboard = { path: full, name: it.name, op: "copy" }; } },
        { label: "Paste", disabled: !window.AE3_clipboard, action: function () { paste(cwd); } },
        { sep: true },
        { label: "Rename", action: function () { doRename(full, it.name); } },
        { label: "Delete", action: function () { doDelete(full); } },
        { sep: true },
        { label: "Properties", action: function () { showProperties(full, it); } }
      ]);
    }
    function newFolder() {
      Modal.prompt("New folder name", "untitled").then(function (name) {
        if (!name) return;
        A3.request("fs_mkdir", { path: joinPath(cwd, name) }).then(function (r) { if (r.error && r.error !== "") Modal.alert("New Folder", "Permission denied."); else { load(); maybeRefreshDesktop(cwd); } });
      });
    }
    function newFile() {
      Modal.prompt("New file name", "untitled.txt").then(function (name) {
        if (!name) return;
        A3.request("fs_save", { path: joinPath(cwd, name), content: "" }).then(function (r) { if (r.error && r.error !== "") Modal.alert("New File", "Permission denied."); else { load(); maybeRefreshDesktop(cwd); } });
      });
    }
    function emptyMenu(x, y) {
      window.AE3_ctxMenu(x, y, [
        { label: "New Folder", action: newFolder },
        { label: "New File", action: newFile },
        { label: "Paste", disabled: !window.AE3_clipboard, action: function () { paste(cwd); } },
        { sep: true },
        { label: "Refresh", action: load }
      ]);
    }
    // Empty-area right-click. Bind on the <ul> AND its wrapper; the previous strict
    // "e.target === entries" check failed whenever the list was empty/short or the click landed on
    // padding, so the menu never appeared. Treat any click not on an <li> as the empty area.
    entries.addEventListener("contextmenu", function (e) {
      if (e.target.closest("li")) return; // item rows handle their own menu
      e.preventDefault(); e.stopPropagation();
      emptyMenu(e.clientX, e.clientY);
    });
    // Fallback: right-click anywhere in this browser's host that isn't a list row or the toolbar also
    // opens the empty-area menu, in case the list doesn't fully cover the pane.
    body.addEventListener("contextmenu", function (e) {
      if (e.target.closest("li") || e.target.closest(".toolbar")) return;
      e.preventDefault(); e.stopPropagation();
      emptyMenu(e.clientX, e.clientY);
    });

    // Ctrl+C / Ctrl+X / Ctrl+V on the focused list.
    entries.addEventListener("keydown", function (e) {
      if (!(e.ctrlKey || e.metaKey)) return;
      var k = e.key.toLowerCase();
      if (k === "c" && sel) { window.AE3_clipboard = { path: sel.path, name: sel.name, op: "copy" }; e.preventDefault(); }
      else if (k === "x" && sel) { window.AE3_clipboard = { path: sel.path, name: sel.name, op: "cut" }; e.preventDefault(); }
      else if (k === "v" && window.AE3_clipboard) { paste(cwd); e.preventDefault(); }
    });

    function runSearch(q) {
      if (!q || q.trim() === "") { searching = false; load(); return; }
      searching = true; sel = null;
      entries.innerHTML = '<li class="muted pad">Searching&hellip;</li>';
      A3.request("fs_search", { query: q, root: cwd }).then(function (res) {
        entries.innerHTML = "";
        var hits = (res && res.results) || [];
        if (!hits.length) { entries.innerHTML = '<li class="muted pad">No matches</li>'; return; }
        hits.forEach(function (it) {
          var name = it.path.split("/").pop();
          var isApp = /\.app$/i.test(name);
          var cls = it.dir ? "isdir" : (isApp ? "isapp" : "isfile");
          var glyph = it.dir ? Icons.folder : (isApp ? Icons.app : Icons.file);
          var li = h('<li class="' + cls + '"><span class="ico">' + glyph + '</span><span>' + esc(name) +
            ' <span class="muted" style="font-size:11px">' + esc(it.path) + '</span></span></li>');
          li.addEventListener("dblclick", function () {
            if (it.dir) { go(it.path); } else { openFile(it.path); }
          });
          li.addEventListener("click", function () {
            entries.querySelectorAll("li").forEach(function (n) { n.classList.remove("sel"); });
            li.classList.add("sel"); sel = { name: name, dir: it.dir, path: it.path };
          });
          entries.appendChild(li);
        });
      }).catch(function () { entries.innerHTML = '<li class="muted pad">Search failed</li>'; });
    }
    searchInput.addEventListener("keydown", function (e) { if (e.key === "Enter") runSearch(searchInput.value); });

    pathInput.addEventListener("keydown", function (e) { if (e.key === "Enter") go(pathInput.value.trim() || "/"); });
    body.querySelector(".up").addEventListener("click", function () {
      if (searching) { searching = false; searchInput.value = ""; load(); return; }
      if (cwd !== "/") { go(cwd.replace(/\/+$/, "").split("/").slice(0, -1).join("/") || "/"); }
    });
    body.querySelector(".refresh").addEventListener("click", function () { if (searching) runSearch(searchInput.value); else load(); });
    body.querySelector(".mkdir").addEventListener("click", newFolder);
    body.querySelector(".del").addEventListener("click", function () {
      if (!sel) return;
      Modal.confirm("Delete", "Delete '" + sel.name + "'?").then(function (ok) {
        if (!ok) return;
        doDelete(sel.path);
      });
    });
    if (opts.onReady) opts.onReady({ go: go, reload: load, getCwd: function () { return cwd; }, getSel: function () { return sel; } });
    load();
  };

  Apps.register({
    id: "files", title: "Files", glyph: Icons.files, width: 680, height: 460,
    showOnDesktop: true, showInDock: true,
    render: function (body, win, args) { window.AE3_FileBrowser(body, win, args, {}); }
  });

  // ---------------- File picker ----------------
  // window.AE3_pickFile("open"|"save", { start, filename, title }) -> Promise<path|null>.
  // "open": double-click a file (or select + Choose) resolves its path. "save": browse to a folder,
  // type a filename, Save resolves "<folder>/<filename>". Reuses the exact Files browser core.
  window.AE3_pickFile = function (mode, opts) {
    opts = opts || {};
    return new Promise(function (resolve) {
      var ov = h('<div class="pk-overlay"><div class="pk-dialog">' +
        '<div class="pk-title">' + esc(opts.title || (mode === "save" ? "Save As" : "Open")) + '</div>' +
        '<div class="pk-body"></div>' +
        '<div class="pk-foot">' +
          (mode === "save" ? '<input class="input pk-name" placeholder="filename.ext">' : '') +
          '<span style="flex:1"></span>' +
          '<button class="btn pk-cancel">Cancel</button>' +
          '<button class="btn accent pk-ok">' + (mode === "save" ? "Save" : "Choose") + '</button>' +
        '</div></div></div>');
      document.body.appendChild(ov);
      var bodyEl = ov.querySelector(".pk-body");
      var nameEl = ov.querySelector(".pk-name");
      // The dialog can be dragged by its title bar so it never traps the file list behind the footer
      // off-screen. Switch from flex-centred to absolute positioning on first grab.
      (function () {
        var dlg = ov.querySelector(".pk-dialog"), title = ov.querySelector(".pk-title");
        var dragging = false, sx = 0, sy = 0, ox = 0, oy = 0;
        title.style.cursor = "grab";
        title.addEventListener("mousedown", function (e) {
          var r = dlg.getBoundingClientRect();
          ov.style.display = "block"; dlg.style.position = "absolute";
          dlg.style.left = r.left + "px"; dlg.style.top = r.top + "px"; dlg.style.margin = "0";
          dragging = true; sx = e.clientX; sy = e.clientY; ox = r.left; oy = r.top;
          title.style.cursor = "grabbing"; e.preventDefault();
        });
        document.addEventListener("mousemove", function (e) {
          if (!dragging) return;
          var nx = Math.max(0, Math.min(window.innerWidth - 60, ox + (e.clientX - sx)));
          var ny = Math.max(0, Math.min(window.innerHeight - 30, oy + (e.clientY - sy)));
          dlg.style.left = nx + "px"; dlg.style.top = ny + "px";
        });
        document.addEventListener("mouseup", function () { dragging = false; title.style.cursor = "grab"; });
      })();
      if (nameEl && opts.filename) nameEl.value = opts.filename;
      var apiRef = null, lastFile = null;
      function close(val) { ov.remove(); resolve(val); }
      window.AE3_FileBrowser(bodyEl, null, { path: opts.start || "/home" }, {
        onReady: function (api) { apiRef = api; },
        onPick: function (it, full) {
          if (mode === "open") { close(full); }
          else { lastFile = full; if (nameEl) nameEl.value = it.name; }
        }
      });
      ov.querySelector(".pk-cancel").addEventListener("click", function () { close(null); });
      ov.querySelector(".pk-ok").addEventListener("click", function () {
        if (mode === "save") {
          var fn = (nameEl.value || "").trim(); if (!fn) { nameEl.focus(); return; }
          var dir = apiRef ? apiRef.getCwd() : (opts.start || "/home");
          close(joinPath(dir, fn));
        } else {
          if (lastFile) close(lastFile);
        }
      });
    });
  };

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

      // Launched with a path but no inline content; fetch the file so the editor is populated. Any
      // Apps.launch("notepad", { path })): fetch the file so the editor isn't blank. Handles
      // password-protected files the same way the Open flow does.
      if (path && (!args || args.content == null)) {
        A3.request("fs_read", { path: path }).then(function (res) {
          if (res.error && res.error !== "") { Modal.alert("Open", res.error === "not_text" ? "Not a text file." : "Cannot open file."); return; }
          if (res.locked) {
            Modal.prompt("This file is password protected. Enter password:", "").then(function (pass) {
              if (pass == null) return;
              A3.request("fs_unlock", { path: path, pass: pass }).then(function (r2) {
                if (r2.error === "bad_pass") { Modal.alert("Locked", "Wrong password."); return; }
                if (r2.error && r2.error !== "") { Modal.alert("Open", "Cannot open file."); return; }
                ta.value = r2.content || ""; setName();
              });
            });
            return;
          }
          ta.value = res.content || ""; setName();
        }).catch(function () {});
      }

      function save(toPath) {
        A3.request("fs_save", { path: toPath, content: ta.value }).then(function (r) {
          if (r.error && r.error !== "") { Modal.alert("Save", "Permission denied."); return; }
          path = toPath; setName();
        });
      }
      body.querySelector(".n").addEventListener("click", function () { ta.value = ""; path = null; setName(); });
      body.querySelector(".o").addEventListener("click", function () {
        AE3_pickFile("open", { title: "Open file", start: path ? path.replace(/\/[^/]*$/, "") || "/home" : "/home" }).then(function (p) {
          if (!p) return;
          function openInto(res) { ta.value = res.content || ""; path = p; setName(); }
          A3.request("fs_read", { path: p }).then(function (res) {
            if (res.error && res.error !== "") { Modal.alert("Open", "Cannot open file."); return; }
            if (res.locked) { // password-protected: verify before showing content
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
        AE3_pickFile("save", { title: "Save As", start: path ? path.replace(/\/[^/]*$/, "") || "/home" : "/home", filename: path ? path.split("/").pop() : "untitled.txt" }).then(function (p) { if (p) save(p); });
      });
    }
  });

  // ---------------- Image Viewer ----------------
  // The EXPERIMENTAL in-OS web image viewer for media registered via AE3_desktop_fnc_registerMedia.
  // Images open in the native viewer by default; this window is only used when the media was
  // registered with the "web" flag. It renders inside the webview via A3.loadTexture (base64 data
  // URL) where the CEF sampler supports it, and otherwise falls back to the native RscPicture viewer.
  Apps.register({
    id: "media", title: "Image Viewer", glyph: Icons.image, width: 720, height: 540,
    showInDock: true, singleton: false,
    render: function (body, win, args) {
      body.style.background = "#111";
      body.style.display = "flex";
      body.style.flexDirection = "column";
      body.innerHTML =
        '<div class="toolbar"><button class="btn mopen">Open image…</button>' +
          '<span class="muted mname" style="margin-left:10px;align-self:center"></span></div>' +
        '<div class="mstage" style="flex:1;min-height:0;display:flex;align-items:center;justify-content:center">' +
          '<div class="muted mload" style="padding:16px">No image open. Use "Open image…" to load one.</div>' +
          '<img class="mimg" style="display:none;max-width:100%;max-height:100%;object-fit:contain">' +
        '</div>';
      var img = body.querySelector(".mimg");
      var load = body.querySelector(".mload");
      var nameEl = body.querySelector(".mname");
      // Render a registered media source. It can be absolute (\myMod\img.paa), addon-relative, or
      // mission-relative (media\images\pic.jpg); try each form so any valid path resolves.
      function showImage(srcPath, name, opts) {
        opts = opts || {};
        nameEl.textContent = name || "";
        win.el.querySelector(".title").textContent = "Image Viewer" + (name ? " - " + name : "");
        if (!srcPath) { img.style.display = "none"; load.style.display = "block"; load.textContent = 'No image open. Use "Open image…" to load one.'; return; }

        // Any web-side failure funnels here and hands off to the native RscPicture viewer (which
        // renders through the engine texture loader and handles every image type). The CEF texture
        // sampler is unavailable in many setups - it can reject the path outright or "resolve" with an
        // unusable texture that then fails to decode or decodes to 0x0 - so reject, decode-error and
        // empty pixels all route here, and so does an up-front "native forced" request.
        var handed = false;
        function failToNative(reason) {
          if (handed) return;
          console.log("[AE3 media] handing to native viewer (" + reason + ") for", srcPath);
          if (opts.marker) {
            handed = true;
            img.style.display = "none"; load.style.display = "block"; load.textContent = "Opening in native viewer...";
            // Pass this window's footprint (as viewport fractions) so the native viewer can be sized
            // and positioned to overlay the in-OS Image Viewer window exactly.
            var rect = [];
            try {
              var r = win.el.getBoundingClientRect();
              var vw = window.innerWidth || document.documentElement.clientWidth || 1;
              var vh = window.innerHeight || document.documentElement.clientHeight || 1;
              if (r && r.width > 0 && r.height > 0) { rect = [r.left / vw, r.top / vh, r.width / vw, r.height / vh]; }
            } catch (e) {}
            A3.send("fs_open_media", { path: opts.vfsPath || srcPath, content: opts.marker, rect: rect });
          } else {
            img.style.display = "none"; load.style.display = "block"; load.textContent = "Cannot display this image.";
          }
        }

        img.onload = function () {
          if (!img.naturalWidth || !img.naturalHeight) { failToNative("empty texture"); return; }
          load.style.display = "none"; img.style.display = "block";
        };
        img.onerror = function () { failToNative("decode error"); };

        img.removeAttribute("src");
        img.style.display = "none"; load.style.display = "block"; load.textContent = "Loading image...";
        A3.loadImage(srcPath, undefined, undefined, opts.scope).then(function (dataUrl) {
          img.src = dataUrl;
        }).catch(function () { failToNative("loadImage rejected"); });
      }

      // Open another image: pick a VFS file, resolve its media marker to the underlying source path.
      body.querySelector(".mopen").addEventListener("click", function () {
        AE3_pickFile("open", { title: "Open image", start: (window.AE3_HOME || "/home") }).then(function (p) {
          if (!p) return;
          A3.request("fs_read", { path: p }).then(function (res) {
            var content = (res && res.content) || "";
            var media = A3.parseMedia(content);
            if (media && media.type === "image") {
              showImage(media.path, p.split("/").pop(), { scope: media.scope, web: media.web, vfsPath: p, marker: content });
              return;
            }
            Modal.alert("Open image", "That file is not an image.");
          });
        });
      });

      showImage((args && args.path) || "",
        (args && args.title) || ((args && args.path) ? String(args.path).split("\\").pop().split("/").pop() : ""),
        { scope: (args && args.scope), web: (args && args.web), vfsPath: (args && args.vfsPath), marker: (args && args.marker) });
    }
  });

  // ---------------- Settings ----------------
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
            '<input class="input shost" placeholder="armaOS">' +
            '<label class="muted">Wallpaper (CSS colour/gradient or image path, blank = default)</label>' +
            '<input class="input swall" placeholder="#1d1d1d or linear-gradient(...) or \\\\z\\\\...\\\\bg.jpg">' +
            '<div><button class="btn accent ssave">Apply</button> <span class="muted sst"></span></div>' +
          '</div>' +
          '<h3 style="margin-top:14px">Access</h3>' +
          '<label class="muted" style="display:flex;align-items:center;gap:8px"><input type="checkbox" class="ssh"> Allow SSH access to this device</label>' +
          '<h3 style="margin-top:14px">Network</h3>' +
          '<div style="display:flex;flex-direction:column;gap:8px;max-width:420px">' +
            '<label class="muted">IP address (changes immediately)</label>' +
            '<div style="display:flex;gap:8px"><input class="input sipval" placeholder="192.168.x.x" style="flex:1"><button class="btn accent sipapply">Apply</button></div>' +
            '<span class="muted sipst"></span>' +
          '</div>' +
        '</div>';
      var box = body.querySelector("#sysinfo");
      var hostEl = body.querySelector(".shost");
      var wallEl = body.querySelector(".swall");
      var sshEl = body.querySelector(".ssh");
      var sipEl = body.querySelector(".sipval");
      var sipSt = body.querySelector(".sipst");
      sshEl.addEventListener("change", function () {
        A3.request("ssh_config", { enabled: sshEl.checked });
      });
      A3.request("sysinfo", {}).then(function (s) {
        s = s || {};
        if (sshEl) sshEl.checked = !!s.sshEnabled;
        box.innerHTML =
          "Hostname: " + esc(s.hostname || "?") + "<br>" +
          "IP: " + esc(s.ip || "?") + " &nbsp; Gateway: " + esc(s.gateway || "?") + "<br>" +
          "Power: " + esc(s.power || "?") + " &nbsp; Battery: " + (s.battery != null ? s.battery + "%" : "?") + "<br>" +
          "Uptime: " + esc(s.uptime || "?");
        if (hostEl) hostEl.value = s.hostname || "";
        if (wallEl) wallEl.value = s.wallpaper || "";
        if (sipEl) sipEl.value = s.ip || "";
      }).catch(function () { box.textContent = "Unavailable"; });
      body.querySelector(".sipapply").addEventListener("click", function () {
        var ip = sipEl.value.trim();
        A3.request("net_setip", { ip: ip }).then(function (r) {
          if (r && r.error && r.error !== "") {
            sipSt.textContent = r.error === "ip_in_use" ? "Address already in use." : "Invalid address.";
            return;
          }
          sipSt.textContent = "Applied.";
        }).catch(function () { sipSt.textContent = "Failed."; });
      });

      body.querySelector(".ssave").addEventListener("click", function () {
        var host = hostEl.value.trim(), wall = wallEl.value.trim();
        var st = body.querySelector(".sst");
        A3.request("sys_set", { hostname: host, wallpaper: wall }).then(function (r) {
          if (r && r.error && r.error !== "") { st.textContent = "Failed."; return; }
          st.textContent = "Applied.";
          if (host) Desktop.setHostname(host);          // reflect immediately on this client
          Desktop.setWallpaper(wall);
        });
      });
    }
  });

  // ---------------- Network ----------------
  Apps.register({
    id: "network", title: "Network", glyph: Icons.network, width: 560, height: 380,
    showInDock: true,
    render: function (body) {
      body.innerHTML = '<div class="pad"><div style="display:flex;align-items:center"><h3 style="flex:1">Wireless networks</h3><span class="muted nstat" style="margin-right:8px"></span><button class="btn rescan">Rescan</button></div><ul class="list nets"><li class="muted">Scanning&hellip;</li></ul></div>';
      var nets = body.querySelector(".nets");
      var statEl = body.querySelector(".nstat");
      // Password-protected routers: prompt before connecting, then send the password.
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
      // Server connect verdict (range/password).
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

  // ---------------- Calendar ----------------
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
      // Full-height layout: toolbars + grid keep their size, the day/event panel grows to fill
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
      // Live update when the store changes server-side.
      A3.on("cal_changed", function () { fetchAll(selIso); });
      body.querySelector(".go").addEventListener("click", function () {
        var v = body.querySelector(".goto").value; if (!v) return;
        var p = v.split("-"); view = new Date(+p[0], +p[1] - 1, 1); draw(); showDay(v);
      });
      fetchAll();
    }
  });

  // ---------------- Browser ----------------
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
      var intelPages = []; // intel pages registered via Zeus/API
      A3.request("web_pages", {}).then(function (res) { intelPages = (res && res.pages) || []; }).catch(function () {});

      // Injected into every page so in-page links drive the address bar instead of dead relative nav.
      // Arma's CEF renders iframe srcdoc with an opaque origin, so a direct parent.AE3_browserNav()
      // call throws a cross-origin SecurityError. postMessage is
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
          '<button class="btn hist" title="History" style="margin-left:4px">&#9776;</button>' +
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
      // A link is page-relative (resolved against the current page's directory) when it starts with
      // ./ or ../ OR is a bare filename with no slash (e.g. "getting-started.html"). An address that
      // contains a slash but no ./.. prefix (e.g. "sites/intel/report.md" typed in the bar) is treated
      // as root-relative. This fixes wiki links like "getting-started.html" and "../wiki/index.html"
      // that previously loaded bare and 404'd, losing the page's directory.
      function isPageRelative(addr) { return /^\.\.?\//.test(addr) || addr.indexOf("/") < 0; }

      function resolve(addrRaw) {
        var addr = String(addrRaw == null ? "home" : addrRaw).trim();
        if (isRouterAddr(addr)) return { router: true, label: "router" };
        var hasPath = addr.charAt(0) === "\\" || /^[a-z]:/i.test(addr) || addr.indexOf("/") >= 0 || addr.indexOf("\\") >= 0;
        var mdName = addr.match(/([^\/\\]+\.md)(?:[#?].*)?$/i); // keep original case for the VFS lookup

        // Explicit .md: a bare filename is a wiki page; a pathed .md (mod/mission) loads as given.
        if (/\.md($|[#?])/i.test(addr)) {
          if (mdName && !hasPath) return { type: "md", path: "wiki/" + mdName[1], label: mdName[1] };
          return { type: "md", path: addr, label: addr };
        }
        // Explicit .html / any pathed address: load through the root search (mod or mission). A
        // page-relative href (e.g. portal's "../wiki/index.html") is joined to the current page's
        // directory; bridge.loadFile then collapses the ".." so A3API gets a clean path.
        if (/\.html?($|[#?])/i.test(addr) || hasPath) {
          var p = (!isAbsolute(addr) && isPageRelative(addr)) ? (curDir + addr) : addr;
          return { type: "html", path: p, label: addr };
        }

        var lower = addr.toLowerCase().replace(/^https?:\/\//, "").replace(/\/+$/, "");
        if (sites[lower]) return sites[lower];
        for (var pi = 0; pi < intelPages.length; pi++) {
          if ((intelPages[pi].url || "").toLowerCase() === lower) {
            return { type: "intel", title: intelPages[pi].title, content: intelPages[pi].content, label: intelPages[pi].url };
          }
        }
        if (lower.indexOf("wiki") >= 0) return sites.wiki;
        return sites.home;
      }

      // Router admin page: browsing to the gateway IP or "router" opens a live settings
      // form backed by router_page / router_set instead of a static file.
      function routerPage() {
        addrEl.value = "router";
        A3.request("router_page", {}).then(function (r) {
          if (r && r.error === "not_connected") {
            setDoc("<div style='font-family:sans-serif;padding:24px'><h2>Not connected</h2><p>Connect to a wireless network first (Network app), then reload this page.</p></div>");
            return;
          }
          if (!r || (r.error && r.error !== "")) { setDoc("<p style='padding:20px;font-family:sans-serif'>Router unavailable.</p>"); return; }
          var doc = '<!DOCTYPE html><html><head><meta charset="utf-8"><style>' +
            'body{font-family:sans-serif;background:#f4f4f4;margin:0;padding:24px;color:#222}' +
            '.card{max-width:520px;margin:0 auto;background:#fff;border-radius:10px;padding:22px;box-shadow:0 2px 10px rgba(0,0,0,.12)}' +
            'h1{color:#c7411f;font-size:20px;margin:0 0 4px}.sub{color:#777;margin:0 0 18px;font-size:13px}' +
            'label{display:block;font-size:13px;margin:12px 0 4px;font-weight:600}' +
            'input{width:100%;padding:8px 10px;border:1px solid #ccc;border-radius:6px;font-size:14px;box-sizing:border-box}' +
            'button{margin-top:18px;background:#e95420;color:#fff;border:none;border-radius:6px;padding:10px 18px;font-size:14px;cursor:pointer}' +
            '.ok{color:#26a269;margin-left:10px;font-size:13px}</style></head><body><div class="card">' +
            '<h1>Router Settings</h1><p class="sub">Gateway ' + (r.gateway || "") + '</p>' +
            '<label>Network name (SSID)</label><input id="rn" value="' + esc(r.name || "") + '">' +
            '<label>Wifi Range (m)</label><input id="rr" type="number" value="' + esc(String(r.range || 100)) + '">' +
            '<label>Default Gateway</label><input id="rg" value="' + esc(String(r.gateway || "")) + '">' +
            '<label>Password (blank = open network)</label><input id="rp" value="' + esc(r.password || "") + '">' +
            '<label><input id="rx" type="checkbox" style="width:auto;margin-right:8px"' + (r.extSsh ? " checked" : "") + '>Allow External SSH (from other gateways)</label>' +
            '<label>Allowed Gateways (regex, blank = any)</label><input id="ra" value="' + esc(String(r.extAllow || "")) + '">' +
            '<div><button id="rs">Apply</button><span class="ok" id="rstat"></span></div></div>' +
            '<script>document.getElementById("rs").addEventListener("click",function(){' +
            'parent.postMessage({__ae3router:{name:document.getElementById("rn").value,range:document.getElementById("rr").value,password:document.getElementById("rp").value,gateway:document.getElementById("rg").value,extSsh:document.getElementById("rx").checked,extAllow:document.getElementById("ra").value}},"*");' +
            'document.getElementById("rstat").textContent="Applied.";});<\/script></body></html>';
          setDoc(doc);
        });
      }
      // Host-side listener for the router form submit (postMessage, like the nav hook).
      if (!window.AE3_routerListener) {
        window.AE3_routerListener = true;
        window.addEventListener("message", function (e) {
          var d = e && e.data;
          if (d && d.__ae3router) { A3.request("router_set", d.__ae3router); }
        });
      }
      function isRouterAddr(addr) {
        var a = String(addr || "").toLowerCase().replace(/^https?:\/\//, "").replace(/\/+$/, "");
        if (a === "router" || a === "gateway") return true;
        return /^192\.168\.\d+\.1$/.test(a) || /^10\.\d+\.\d+\.1$/.test(a);
      }

      function load(t) {
        if (t.router) { routerPage(); return; }
        addrEl.value = t.label;
        if (t.type === "intel") {
          setDoc(wikiDoc("<h1>" + (t.title || t.label) + "</h1><pre style='white-space:pre-wrap;font-family:inherit'>" + (t.content || "") + "</pre>"));
          return;
        }
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
        if (!fromHistory && t.label !== "home") { A3.send("web_log", { url: t.label }); }
        load(t);
      }

      body.querySelector(".go").addEventListener("click", function () { nav(addrEl.value); });
      body.querySelector(".home").addEventListener("click", function () { nav("home"); });
      body.querySelector(".back").addEventListener("click", function () { if (hi > 0) { hi--; nav(history[hi], true); } });
      body.querySelector(".fwd").addEventListener("click", function () { if (hi < history.length - 1) { hi++; nav(history[hi], true); } });
      addrEl.addEventListener("keydown", function (e) { if (e.key === "Enter") nav(addrEl.value); });
      body.querySelector(".hist").addEventListener("click", function () {
        A3.request("web_history", {}).then(function (res) {
          var text = (res && res.history) || "(no history)";
          setDoc(wikiDoc("<h1>Browser History</h1><pre style='white-space:pre-wrap;font-family:inherit'>" + text + "</pre>"));
          addrEl.value = "history";
        }).catch(function () { setDoc(wikiDoc("<h1>Browser History</h1><p>Unavailable.</p>")); });
      });

      // Re-bind the in-page link hook to this window whenever it gains focus.
      win.el.addEventListener("mousedown", function () { window.AE3_browserNav = function (href) { nav(href); }; });

      nav("home");
    }
  });

  // ---------------- Map ----------------
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

  // ---------------- Cryptography: Crypto ----------------
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

  // ---------------- Cryptography: Crack ----------------
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

  // ---------------- Games: Snake ----------------
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

  // ---------------- Recycle Bin ----------------
  Apps.register({
    id: "recyclebin", title: "Recycle Bin", glyph: Icons.trash, width: 560, height: 420, showInDock: false, singleton: true,
    render: function (body) {
      body.innerHTML =
        '<div class="toolbar"><button class="btn refresh">&#8635;</button><button class="btn restore">Restore</button><button class="btn empty">Empty Bin</button></div>' +
        '<ul class="list trash"><li class="muted pad">Loading</li></ul>';
      var listEl = body.querySelector(".trash");
      var sel = null;
      // Restore to the item's original location; if something is already there, confirm overwrite.
      function restore(name) {
        A3.request("fs_restore", { name: name }).then(function (r) {
          if (r.needsConfirm) {
            Modal.confirm("Restore", "'" + (r.dest || name) + "' already exists. Overwrite it?").then(function (ok) {
              if (!ok) return;
              A3.request("fs_restore", { name: name, overwrite: true }).then(function (r2) {
                if (r2.error && r2.error !== "") Modal.alert("Restore", "Could not restore."); else load();
              });
            });
            return;
          }
          if (r.error && r.error !== "") Modal.alert("Restore", "Could not restore."); else load();
        });
      }
      function purge(name) {
        A3.request("fs_purge", { name: name }).then(load);
      }
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
            li.addEventListener("dblclick", function () { restore(it.name); });
            li.addEventListener("contextmenu", function (e) {
              e.preventDefault(); e.stopPropagation();
              listEl.querySelectorAll("li").forEach(function (n) { n.classList.remove("sel"); });
              li.classList.add("sel"); sel = it.name;
              window.AE3_ctxMenu(e.clientX, e.clientY, [
                { label: "Restore", action: function () { restore(it.name); } },
                { sep: true },
                { label: "Delete permanently", action: function () {
                  Modal.confirm("Delete", "Permanently delete '" + it.name + "'?").then(function (ok) { if (ok) purge(it.name); });
                } }
              ]);
            });
            listEl.appendChild(li);
          });
        }).catch(function () { listEl.innerHTML = '<li class="muted pad">Recycle Bin is empty.</li>'; });
      }
      body.querySelector(".refresh").addEventListener("click", load);
      body.querySelector(".restore").addEventListener("click", function () {
        if (!sel) return;
        restore(sel);
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

  // ---------------- Mail ----------------
  Apps.register({
    id: "mail", title: "Email", glyph: Icons.mail, width: 760, height: 480,
    showOnDesktop: true, showInDock: true,
    render: function (body) {
      body.innerHTML =
        '<div class="toolbar"><button class="btn refresh">&#8635;</button>' +
          '<button class="btn tab-inbox accent" data-tab="inbox">Inbox</button>' +
          '<button class="btn tab-sent" data-tab="sent">Sent</button>' +
          '<button class="btn compose" style="margin-left:6px">Compose</button><button class="btn addresses">Addresses</button>' +
          '<input class="input msearch" placeholder="Search from / subject" style="flex:1;margin-left:8px"></div>' +
        '<div style="display:flex;height:calc(100% - 50px)">' +
          '<ul class="list mails" style="width:40%;border-right:1px solid var(--line);overflow:auto"></ul>' +
          '<div class="reader pad" style="flex:1;overflow:auto"><p class="muted">Select a message.</p></div>' +
        '</div>';
      var mails = body.querySelector(".mails");
      var reader = body.querySelector(".reader");
      var searchEl = body.querySelector(".msearch");
      var allMail = [];
      var addresses = [];
      var mailbox = "inbox";

      function setActiveTab(tab) {
        mailbox = tab;
        body.querySelector(".tab-inbox").className = "btn tab-inbox" + (tab === "inbox" ? " accent" : "");
        body.querySelector(".tab-sent").className = "btn tab-sent" + (tab === "sent" ? " accent" : "");
        list();
      }

      body.querySelector(".tab-inbox").addEventListener("click", function () { setActiveTab("inbox"); });
      body.querySelector(".tab-sent").addEventListener("click", function () { setActiveTab("sent"); });

      function render() {
        var q = (searchEl.value || "").toLowerCase();
        mails.innerHTML = "";
        var items = allMail.filter(function (m) {
          if (!q) return true;
          return (m.from || "").toLowerCase().indexOf(q) >= 0 || (m.subject || "").toLowerCase().indexOf(q) >= 0;
        });
        if (!items.length) { mails.innerHTML = '<li class="muted pad">No mail</li>'; return; }
        items.forEach(function (m) {
          var toMeta = m.to ? " &middot; To: " + esc(m.to || "") : "";
          var li = h('<li style="flex-direction:column;align-items:flex-start"><span>' + esc(m.subject || "(no subject)") +
            '</span><span class="muted" style="font-size:12px">From: ' + esc(m.from || "?") + toMeta + ' &middot; ' + esc(m.received || "") + "</span></li>");
          li.addEventListener("click", function () { open(m.file); });
          li.addEventListener("contextmenu", function (e) {
            e.preventDefault(); e.stopPropagation();
            window.AE3_ctxMenu(e.clientX, e.clientY, [
              { label: "Open", action: function () { open(m.file); } },
              { sep: true },
              { label: "Delete", action: function () { del(m.file); } }
            ]);
          });
          mails.appendChild(li);
        });
      }
      function list() {
        mails.innerHTML = '<li class="muted pad">Loading</li>';
        var op = mailbox === "sent" ? "mail_sent_list" : "mail_list";
        A3.request(op, {}).then(function (res) {
          allMail = (res && res.mails) || [];
          render();
        }).catch(function () { mails.innerHTML = '<li class="muted pad">Unavailable</li>'; });
      }
      function loadAddresses(cb) {
        A3.request("addr_list", {}).then(function (res) {
          addresses = (res && res.addresses) || [];
          if (cb) cb();
        }).catch(function () { addresses = []; if (cb) cb(); });
      }
      function del(file) {
        Modal.confirm("Delete", "Delete this email?").then(function (ok) {
          if (!ok) return;
          A3.request("mail_delete", { file: file }).then(function (r) {
            if (r.error && r.error !== "") { Modal.alert("Delete", "Could not delete."); return; }
            reader.innerHTML = '<p class="muted">Select a message.</p>';
            list();
          });
        });
      }
      function open(file) {
        var readOp = mailbox === "sent" ? "mail_read_sent" : "mail_read";
        A3.request(readOp, { file: file }).then(function (m) {
          if (m.error && m.error !== "") { reader.innerHTML = '<p class="muted">Cannot open.</p>'; return; }
          var toLine = m.to ? '<br>To: ' + esc(m.to || "") : "";
          var recLine = m.received ? '<br><span class="muted">' + esc(m.received) + '</span>' : "";
          reader.innerHTML = '<div style="display:flex;align-items:center"><h2 style="flex:1;margin:0">' + esc(m.subject || "") + '</h2>' +
            '<button class="btn mdel">Delete</button></div><p class="muted">From: ' + esc(m.from || "") +
            toLine + recLine + '</p><hr style="border-color:var(--line)"><pre style="white-space:pre-wrap;font-family:inherit">' + esc(m.body || "") + "</pre>";
          reader.querySelector(".mdel").addEventListener("click", function () { del(file); });
        });
      }
      searchEl.addEventListener("input", render);
      function compose() {
        loadAddresses(function () {
          var opts = addresses.map(function (a) { return '<option value="' + esc(a) + '">' + esc(a) + '</option>'; }).join("");
          reader.innerHTML =
            '<h3>New message</h3>' +
            '<div style="display:flex;flex-direction:column;gap:8px;max-width:480px">' +
              '<select class="input from">' + opts + '</select>' +
              '<input class="input to" placeholder="To (email address)">' +
              '<input class="input subj" placeholder="Subject">' +
              '<textarea class="input bd" rows="8" placeholder="Message"></textarea>' +
              '<div><button class="btn accent send">Send</button> <span class="muted st"></span></div>' +
            '</div>';
          if (!addresses.length) reader.querySelector(".st").textContent = "Create an address first.";
          reader.querySelector(".send").addEventListener("click", function () {
            var st = reader.querySelector(".st");
            A3.request("mail_send", {
              from: reader.querySelector(".from").value,
              to: reader.querySelector(".to").value,
              subject: reader.querySelector(".subj").value,
              body: reader.querySelector(".bd").value
            }).then(function (r) {
              var err = r && r.error;
              st.textContent = err && err !== "" ? ("Failed: " + (err === "unreachable" ? "recipient unreachable" : err)) : "Sent.";
              if (!err || err === "") setTimeout(list, 400);
            });
          });
        });
      }
      function manageAddresses() {
        loadAddresses(function () {
          reader.innerHTML =
            '<h3>My addresses</h3>' +
            '<div style="display:flex;gap:8px;margin-bottom:10px"><input class="input newaddr" placeholder="name@domain.local" style="flex:1"><button class="btn accent addaddr">Create</button></div>' +
            '<ul class="list addrlist"></ul>';
          var listEl = reader.querySelector(".addrlist");
          function draw() {
            listEl.innerHTML = "";
            if (!addresses.length) { listEl.innerHTML = '<li class="muted pad">No addresses</li>'; return; }
            addresses.forEach(function (a) {
              var li = h('<li><span style="flex:1">' + esc(a) + '</span><button class="btn deladdr">Delete</button></li>');
              li.querySelector(".deladdr").addEventListener("click", function () {
                A3.request("addr_delete", { address: a }).then(function () { loadAddresses(draw); });
              });
              listEl.appendChild(li);
            });
          }
          reader.querySelector(".addaddr").addEventListener("click", function () {
            var a = reader.querySelector(".newaddr").value;
            A3.request("addr_create", { address: a }).then(function (r) {
              if (r.error && r.error !== "") { Modal.alert("Addresses", r.error === "taken" ? "Address already exists." : "Invalid address."); return; }
              reader.querySelector(".newaddr").value = "";
              loadAddresses(draw);
            });
          });
          draw();
        });
      }
      body.querySelector(".refresh").addEventListener("click", list);
      body.querySelector(".compose").addEventListener("click", compose);
      body.querySelector(".addresses").addEventListener("click", manageAddresses);
      list();
    }
  });

  // ---------------- Messenger ----------------
  Apps.register({
    id: "messenger", title: "Messenger", glyph: Icons.messenger, width: 720, height: 500,
    showInDock: true, singleton: true,
    render: function (body, win) {
      body.innerHTML =
        '<div class="toolbar"><input class="input csearch" placeholder="Search conversations / messages" style="flex:1">' +
          '<button class="btn handles" title="My handles">Handles</button><button class="btn newchat accent" title="New conversation">New</button></div>' +
        '<div style="display:flex;height:calc(100% - 50px)">' +
          '<ul class="list peers" style="width:34%;border-right:1px solid var(--line);overflow:auto"></ul>' +
          '<div style="flex:1;display:flex;flex-direction:column">' +
            '<div class="msgs" style="flex:1;overflow:auto;padding:12px;background:#262626"></div>' +
            '<div class="toolbar"><input class="input text" placeholder="Message" style="flex:1"><button class="btn accent send">Send</button></div>' +
          '</div>' +
        '</div>';
      var peersEl = body.querySelector(".peers");
      var msgs = body.querySelector(".msgs");
      var textEl = body.querySelector(".text");
      var searchEl = body.querySelector(".csearch");
      var threads = [];      // [{peer, messages:[{dir,time,text}]}]
      var active = null;     // active peer handle
      var handles = [];

      function loadHandles(cb) {
        A3.request("handle_list", {}).then(function (res) {
          handles = (res && res.handles) || [];
          if (cb) cb();
        }).catch(function () { handles = []; if (cb) cb(); });
      }

      function renderPeers() {
        var q = (searchEl.value || "").toLowerCase();
        peersEl.innerHTML = "";
        var shown = threads.filter(function (t) {
          if (!q) return true;
          if (t.peer.toLowerCase().indexOf(q) >= 0) return true;
          return t.messages.some(function (m) { return (m.text || "").toLowerCase().indexOf(q) >= 0; });
        });
        if (!shown.length) { peersEl.innerHTML = '<li class="muted pad">No conversations</li>'; return; }
        shown.forEach(function (t) {
          var last = t.messages.length ? t.messages[t.messages.length - 1] : null;
          var li = h('<li style="flex-direction:column;align-items:flex-start' + (t.peer === active ? ';background:var(--surface-2)' : '') + '">' +
            '<span>' + esc(t.peer) + '</span>' +
            '<span class="muted" style="font-size:12px">' + esc(last ? (last.dir === "o" ? "You: " : "") + last.text : "") + '</span></li>');
          li.addEventListener("click", function () { active = t.peer; renderThread(); renderPeers(); });
          peersEl.appendChild(li);
        });
      }
      function renderThread() {
        msgs.innerHTML = "";
        var t = threads.filter(function (x) { return x.peer === active; })[0];
        if (!t) { msgs.innerHTML = '<p class="muted">Select or start a conversation.</p>'; return; }
        var q = (searchEl.value || "").toLowerCase();
        t.messages.forEach(function (m) {
          if (q && (m.text || "").toLowerCase().indexOf(q) < 0) return;
          var out = m.dir === "o";
          msgs.appendChild(h('<div style="margin:6px 0;display:flex;' + (out ? "justify-content:flex-end" : "") + '">' +
            '<div style="max-width:75%;padding:6px 10px;border-radius:10px;background:' + (out ? "var(--accent);color:#fff" : "#3a3a3a") + '">' +
            esc(m.text) + '<div style="font-size:10px;opacity:.7;text-align:right">' + esc(m.time) + '</div></div></div>'));
        });
        msgs.scrollTop = msgs.scrollHeight;
      }

      A3.on("chat_data", function (d) {
        var incoming = (d && d.threads) || [];
        // Preserve an active pending thread the server doesn't know about yet (new conversation,
        // no messages sent — server won't return it until first message is exchanged).
        var pending = active && !incoming.some(function (t) { return t.peer === active; })
          ? threads.find(function (t) { return t.peer === active; })
          : null;
        threads = incoming;
        if (pending) threads.push(pending);
        if (!active && threads.length) active = threads[0].peer;
        renderPeers(); renderThread();
      });

      function send() {
        var to = active;
        if (!to) { Modal.alert("Messenger", "Pick or start a conversation first."); return; }
        if (textEl.value.trim() === "") return;
        A3.request("chat_send", { to: to, text: textEl.value }).then(function (r) {
          if (r.error && r.error !== "") { Modal.alert("Messenger", r.error === "unreachable" ? "Recipient unreachable." : ("Could not send: " + r.error)); return; }
          textEl.value = "";
          setTimeout(function () { A3.send("chat_pull", {}); }, 300);
        });
      }
      body.querySelector(".send").addEventListener("click", send);
      textEl.addEventListener("keydown", function (e) { if (e.key === "Enter") send(); });
      searchEl.addEventListener("input", function () { renderPeers(); renderThread(); });
      body.querySelector(".newchat").addEventListener("click", function () {
        A3.request("handles_all", {}).then(function (res) {
          var knownHandles = (res && res.handles) || [];
          var ov = h('<div class="pk-overlay"><div class="pk-dialog" style="width:360px;height:auto;min-height:0">' +
            '<div class="pk-title">Start conversation</div>' +
            '<div class="pad" style="display:flex;flex-direction:column;gap:8px">' +
              '<ul class="list hpick" style="max-height:200px;overflow:auto"></ul>' +
              '<div style="display:flex;gap:8px"><input class="input hnew" placeholder="or type a handle" style="flex:1"><button class="btn accent hgo">Start</button></div>' +
              '<div style="text-align:right"><button class="btn hclose">Cancel</button></div>' +
            '</div></div></div>');
          document.body.appendChild(ov);
          var pickEl = ov.querySelector(".hpick");
          if (!knownHandles.length) {
            pickEl.innerHTML = '<li class="muted pad">No known handles</li>';
          }
          function startWith(handle) {
            if (!handle) return;
            if (handle.charAt(0) !== "@") handle = "@" + handle;
            if (!threads.some(function (t) { return t.peer === handle; })) threads.push({ peer: handle, messages: [] });
            active = handle; renderPeers(); renderThread(); ov.remove();
          }
          knownHandles.forEach(function (hnd) {
            var display = hnd.display || hnd.handle || hnd;
            var handle = hnd.handle || hnd;
            var li = h('<li><span style="flex:1">' + esc(display) + '</span><button class="btn pick">Chat</button></li>');
            li.querySelector(".pick").addEventListener("click", function () { startWith(handle); });
            pickEl.appendChild(li);
          });
          ov.querySelector(".hgo").addEventListener("click", function () { startWith(ov.querySelector(".hnew").value.trim()); });
          ov.querySelector(".hnew").addEventListener("keydown", function (e) { if (e.key === "Enter") startWith(ov.querySelector(".hnew").value.trim()); });
          ov.querySelector(".hclose").addEventListener("click", function () { ov.remove(); });
        }).catch(function () {
          Modal.prompt("Start conversation with handle", "@").then(function (handle) {
            if (!handle) return;
            if (handle.charAt(0) !== "@") handle = "@" + handle;
            if (!threads.some(function (t) { return t.peer === handle; })) threads.push({ peer: handle, messages: [] });
            active = handle; renderPeers(); renderThread();
          });
        });
      });
      body.querySelector(".handles").addEventListener("click", function () {
        loadHandles(function () {
          var ov = h('<div class="pk-overlay"><div class="pk-dialog" style="width:420px;height:auto;min-height:0">' +
            '<div class="pk-title">My handles</div><div class="pad" style="display:flex;flex-direction:column;gap:10px">' +
            '<div style="display:flex;gap:8px"><input class="input newhandle" placeholder="@handle" style="flex:1"><button class="btn accent addhandle">Create</button></div>' +
            '<ul class="list handlelist"></ul><div style="text-align:right"><button class="btn close">Close</button></div></div></div></div>');
          document.body.appendChild(ov);
          var listEl = ov.querySelector(".handlelist");
          function draw() {
            listEl.innerHTML = "";
            if (!handles.length) { listEl.innerHTML = '<li class="muted pad">No handles</li>'; return; }
            handles.forEach(function (hnd) {
              var li = h('<li><span style="flex:1">' + esc(hnd) + '</span><button class="btn delhandle">Delete</button></li>');
              li.querySelector(".delhandle").addEventListener("click", function () {
                A3.request("handle_delete", { handle: hnd }).then(function () { loadHandles(draw); });
              });
              listEl.appendChild(li);
            });
          }
          ov.querySelector(".addhandle").addEventListener("click", function () {
            var hnd = ov.querySelector(".newhandle").value;
            A3.request("handle_create", { handle: hnd }).then(function (r) {
              if (r.error && r.error !== "") { Modal.alert("Handles", r.error === "taken" ? "Handle already exists." : "Invalid handle."); return; }
              ov.querySelector(".newhandle").value = "";
              loadHandles(draw);
            });
          });
          ov.querySelector(".close").addEventListener("click", function () { ov.remove(); });
          draw();
        });
      });
      A3.on("msg_notify", function (d) {
        if (window.AE3_toast) window.AE3_toast("New message from " + ((d && d.peer) || "unknown"), "ok");
        A3.send("chat_pull", {});
      });

      A3.send("chat_pull", {});
      win.timer = setInterval(function () { A3.send("chat_pull", {}); }, 3000);
      win.app.onClose = function (w) { if (w.timer) clearInterval(w.timer); };
    }
  });

  // ---------------- My Computer ----------------
  // Central computer view: removable volumes (auto-mounted USB), mount/unmount, shortcuts to Network
  // & System properties, plus an embedded file browser - like a real Debian/Ubuntu "Computer".
  Apps.register({
    id: "mycomputer", title: "My Computer", glyph: (Icons.computer || Icons.files), width: 780, height: 560,
    showInDock: true, singleton: true, showInMenu: false,
    render: function (body, win) {
      body.innerHTML =
        '<div style="display:flex;height:100%">' +
          '<div class="mc-side" style="width:230px;border-right:1px solid var(--line);overflow:auto">' +
            '<div class="pad" style="font-weight:600">Volumes</div>' +
            '<div class="mc-vols"></div>' +
            '<div class="pad" style="font-weight:600;border-top:1px solid var(--line)">Shortcuts</div>' +
            '<div style="padding:6px 12px;display:flex;flex-direction:column;gap:6px">' +
              '<button class="btn mc-net">Network properties</button>' +
              '<button class="btn mc-sys">System properties</button>' +
            '</div>' +
          '</div>' +
          '<div class="mc-main" style="flex:1;display:flex;flex-direction:column;min-width:0"></div>' +
        '</div>';
      var volsEl = body.querySelector(".mc-vols");
      var main = body.querySelector(".mc-main");
      var browserApi = null;

      function openIn(path) {
        window.AE3_FileBrowser(main, win, { path: path }, { onReady: function (api) { browserApi = api; } });
      }
      function loadVols() {
        A3.request("vol_list", {}).then(function (res) {
          volsEl.innerHTML = "";
          (res && res.volumes || []).forEach(function (v) {
            var card = h('<div class="mc-vol"><div class="mc-name">' + esc(v.label) + '</div>' +
              '<div class="mc-sub">' + (v.type === "usb" ? (v.mounted ? "USB &middot; mounted" : "USB &middot; not mounted") : "Local disk") + '</div>' +
              '<div class="mc-actions"></div></div>');
            var acts = card.querySelector(".mc-actions");
            if (v.type === "usb") {
              if (v.mounted) {
                var openB = h('<button class="btn">Open</button>'); openB.addEventListener("click", function (e) { e.stopPropagation(); openIn(v.path); }); acts.appendChild(openB);
                var um = h('<button class="btn">Eject</button>'); um.addEventListener("click", function (e) { e.stopPropagation(); A3.request("vol_unmount", { interface: v.id }).then(function () { setTimeout(loadVols, 400); }); }); acts.appendChild(um);
              } else {
                var mt = h('<button class="btn accent">Mount</button>'); mt.addEventListener("click", function (e) { e.stopPropagation(); A3.request("vol_mount", { interface: v.id }).then(function () { setTimeout(loadVols, 400); }); }); acts.appendChild(mt);
              }
            }
            card.addEventListener("click", function () { if (v.type !== "usb" || v.mounted) openIn(v.path); });
            volsEl.appendChild(card);
          });
          if (!volsEl.children.length) volsEl.innerHTML = '<div class="pad muted">No volumes</div>';
        }).catch(function () { volsEl.innerHTML = '<div class="pad muted">Unavailable</div>'; });
      }

      body.querySelector(".mc-net").addEventListener("click", function () { Apps.launch("network"); });
      body.querySelector(".mc-sys").addEventListener("click", function () { Apps.launch("settings"); });
      A3.on("vol_changed", loadVols);
      openIn("/");
      loadVols();
    }
  });

  // ---------------- Calculator ----------------
  Apps.register({
    id: "calculator", title: "Calculator", glyph: (Icons.calculator || Icons.about), width: 280, height: 380,
    showInDock: true, singleton: true,
    render: function (body) {
      var keys = ["C","(",")","/","7","8","9","*","4","5","6","-","1","2","3","+","0",".","=",""];
      body.innerHTML =
        '<div class="pad" style="display:flex;flex-direction:column;gap:8px;height:100%">' +
          '<input class="input cdisp" readonly style="text-align:right;font-size:20px;height:40px" value="0">' +
          '<div class="ckeys" style="flex:1;display:grid;grid-template-columns:repeat(4,1fr);gap:6px"></div>' +
        '</div>';
      var disp = body.querySelector(".cdisp");
      var grid = body.querySelector(".ckeys");
      var expr = "";
      function setDisp() { disp.value = expr === "" ? "0" : expr; }
      function press(k) {
        if (k === "") return;
        if (k === "C") { expr = ""; setDisp(); return; }
        if (k === "=") {
          // Safe arithmetic only: digits, operators, parens, dot, spaces.
          if (!/^[0-9+\-*/().\s]+$/.test(expr)) { disp.value = "Error"; expr = ""; return; }
          try {
            // eslint-disable-next-line no-new-func
            var r = Function('"use strict";return (' + expr + ")")();
            expr = (r == null || !isFinite(r)) ? "" : String(r);
          } catch (e) { disp.value = "Error"; expr = ""; return; }
          setDisp(); return;
        }
        expr += k; setDisp();
      }
      keys.forEach(function (k) {
        if (k === "") { grid.appendChild(h('<div></div>')); return; }
        var b = h('<button class="btn' + (k === "=" ? " accent" : "") + '" style="font-size:16px">' + k + "</button>");
        b.addEventListener("click", function () { press(k); });
        grid.appendChild(b);
      });
      body.addEventListener("keydown", function (e) {
        if (e.key === "Enter" || e.key === "=") { press("="); e.preventDefault(); }
        else if (e.key === "Escape") press("C");
        else if (e.key === "Backspace") { expr = expr.slice(0, -1); setDisp(); }
        else if (/^[0-9+\-*/().]$/.test(e.key)) press(e.key);
      });
      setDisp();
    }
  });

  // ---------------- Ping ----------------
  // Tests whether another device is reachable through the simulated AE3 network.
  Apps.register({
    id: "ping", title: "Ping", glyph: (Icons.ping || Icons.terminal), width: 420, height: 260,
    showInDock: true, singleton: true,
    render: function (body) {
      var ipPrefix = { value: "192.168.0." };
      seedIpPrefix(body, ".pto", ipPrefix);
      body.innerHTML =
        '<div class="pad" style="display:flex;flex-direction:column;gap:10px;max-width:380px">' +
          '<h3>Ping</h3>' +
          '<input class="input pto" placeholder="Host IP" value="' + esc(ipPrefix.value) + '">' +
          '<div><button class="btn accent pgo">Ping</button></div>' +
          '<pre class="pout" style="min-height:76px;white-space:pre-wrap;background:#1e1e1e;padding:10px;border-radius:6px;margin:0;font-family:monospace;font-size:12px"></pre>' +
        '</div>';
      var input = body.querySelector(".pto");
      var out = body.querySelector(".pout");
      function run() {
        var ip = input.value.trim();
        if (ip === "") return;
        out.textContent = "Pinging " + ip + "...";
        A3.request("ping_host", { to: ip }).then(function (r) {
          if (!r || (r.error && r.error !== "")) {
            out.textContent = {
              bad_addr: "Invalid address.",
              no_route: "Package dropped."
            }[r && r.error] || "Package dropped.";
            return;
          }
          var routeLength = Math.round(Number(r.routeLength || 0));
          var ms = Math.round(routeLength / 1e5);
          out.textContent = "Reply from " + ip + " (" + (r.host || "remote") + ")\nroute=" + routeLength + "m time=" + ms + "ms";
        }).catch(function () { out.textContent = "Ping timed out."; });
      }
      body.querySelector(".pgo").addEventListener("click", run);
      input.addEventListener("keydown", function (e) { if (e.key === "Enter") run(); });
    }
  });

  // ---------------- SSH ----------------
  // Connect to another SSH-enabled device on the network, then browse/copy files between the local
  // laptop (left pane) and the remote device (right pane).
  Apps.register({
    id: "ssh", title: "SSH", glyph: (Icons.terminal || Icons.network), width: 820, height: 560,
    showInDock: true, singleton: true,
    render: function (body, win) {
      var conn = null; // { to, user, pass }
      var ipPrefix = { value: "192.168.0." };
      seedIpPrefix(body, ".sto", ipPrefix);
      function showConnect(msg) {
        body.innerHTML =
          '<div class="pad" style="display:flex;flex-direction:column;gap:8px;max-width:360px">' +
            '<h3>Connect via SSH</h3>' +
            '<input class="input sto" placeholder="Host IP" value="' + esc(ipPrefix.value) + '">' +
            '<input class="input suser" placeholder="Username">' +
            '<input class="input spass" type="password" placeholder="Password">' +
            '<div><button class="btn accent sgo">Connect</button> <span class="muted smsg">' + (msg || "") + '</span></div>' +
          '</div>';
        body.querySelector(".sgo").addEventListener("click", function () {
          var c = { to: body.querySelector(".sto").value, user: body.querySelector(".suser").value, pass: body.querySelector(".spass").value };
          body.querySelector(".smsg").textContent = "Connecting";
          A3.request("ssh_connect", c).then(function (r) {
            if (!r || (r.error && r.error !== "")) {
              showConnect({ ssh_disabled: "SSH is disabled on that host.", auth_failed: "Wrong username or password.", no_route: "No route to host.", bad_addr: "Invalid address.", busy: "Remote host is busy.", offline: "Remote host is offline." }[r && r.error] || "Connection failed.");
              return;
            }
            conn = c; showSession(r.host || c.to);
          }).catch(function () { showConnect("Connection timed out. Try again."); });
        });
      }
      function showSession(host) {
        body.innerHTML =
          '<div class="toolbar"><span style="flex:1">Connected to <b>' + esc(host) + '</b> as ' + esc(conn.user) + '</span><button class="btn sdisc">Disconnect</button></div>' +
          '<div style="display:flex;height:calc(100% - 50px)">' +
            '<div class="ssh-local" style="width:50%;border-right:1px solid var(--line);display:flex;flex-direction:column"><div class="pad" style="font-weight:600;display:flex;align-items:center">This computer<button class="btn supload" style="margin-left:auto">Upload &#8594;</button></div><div class="ssh-localbody" style="flex:1;min-height:0;display:flex;flex-direction:column"></div></div>' +
            '<div class="ssh-remote" style="flex:1;display:flex;flex-direction:column"><div class="pad" style="font-weight:600">Remote: ' + esc(host) + '</div>' +
              '<div class="toolbar"><button class="btn rup">&#8593;</button><input class="input rpath" style="flex:1" readonly></div>' +
              '<ul class="list rentries" style="flex:1;overflow:auto"></ul></div>' +
          '</div>';
        body.querySelector(".sdisc").addEventListener("click", function () { conn = null; showConnect(); });
        // Local pane reuses the standard file browser; double-click a file pushes it to remote cwd.
        var localApi = null;
        window.AE3_FileBrowser(body.querySelector(".ssh-localbody"), win, { path: window.AE3_HOME || "/home" }, {
          onReady: function (api) { localApi = api; }
        });
        body.querySelector(".supload").addEventListener("click", function () {
          var s = localApi && localApi.getSel();
          if (!s || s.dir) { Modal.alert("Upload", "Select a file in the left pane first."); return; }
          var dest = joinPath(rcwd, s.name);
          A3.request("ssh_push", { to: conn.to, user: conn.user, pass: conn.pass, path: s.path, dest: dest }).then(function (r) {
            Modal.alert("SSH", (r.error && r.error !== "") ? "Upload failed." : "Uploaded to " + dest);
            rload();
          });
        });
        // Remote pane.
        var rentries = body.querySelector(".rentries");
        var rpath = body.querySelector(".rpath");
        var rcwd = "/";
        function rload() {
          rpath.value = rcwd;
          rentries.innerHTML = '<li class="muted pad">Loading</li>';
          A3.request("ssh_ls", { to: conn.to, user: conn.user, pass: conn.pass, path: rcwd }).then(function (res) {
            rentries.innerHTML = "";
            if (res.error && res.error !== "") { rentries.innerHTML = '<li class="muted pad">' + esc(res.error) + "</li>"; return; }
            (res.entries || []).forEach(function (it) {
              var isApp = /\.app$/i.test(it.name);
              var cls = it.dir ? "isdir" : (isApp ? "isapp" : "isfile");
              var glyph = it.dir ? Icons.folder : (isApp ? Icons.app : Icons.file);
              var li = h('<li class="' + cls + '"><span class="ico">' + glyph + '</span><span>' + esc(it.name) + "</span></li>");
              li.addEventListener("dblclick", function () { if (it.dir) { rcwd = joinPath(rcwd, it.name); rload(); } });
              li.addEventListener("contextmenu", function (e) {
                e.preventDefault(); e.stopPropagation();
                if (it.dir) return;
                var full = joinPath(rcwd, it.name);
                window.AE3_ctxMenu(e.clientX, e.clientY, [
                  { label: "Download to this computer", action: function () {
                    var dest = joinPath(window.AE3_HOME || "/home", it.name);
                    A3.request("ssh_pull", { to: conn.to, user: conn.user, pass: conn.pass, path: full, dest: dest }).then(function (r) {
                      Modal.alert("SSH", (r.error && r.error !== "") ? "Download failed." : "Downloaded to " + dest);
                      if (localApi) localApi.reload();
                    });
                  } }
                ]);
              });
              rentries.appendChild(li);
            });
            if (!rentries.children.length) rentries.innerHTML = '<li class="muted pad">Empty</li>';
          }).catch(function () { rentries.innerHTML = '<li class="muted pad">Unavailable</li>'; });
        }
        body.querySelector(".rup").addEventListener("click", function () { if (rcwd !== "/") { rcwd = rcwd.replace(/\/+$/, "").split("/").slice(0, -1).join("/") || "/"; rload(); } });
        // Upload: drag not available; provide a button via toolbar prompt.
        rload();
      }
      showConnect();
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
