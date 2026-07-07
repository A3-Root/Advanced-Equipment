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
      // Executable files (code payload, reported by fs_list) are tinted green and run on double-click.
      var cls = it.dir ? "isdir" : (isApp ? "isapp" : (it.exec ? "isexec" : "isfile"));
      var glyph = it.dir ? Icons.folder : ((isApp || it.exec) ? Icons.app : Icons.file);
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
      // Executable: run it like an .app (switches to the CLI terminal and executes it there).
      if (it.exec) { A3.send("sys_run_file", { path: it.link && it.link !== "" ? it.link : full }); return; }
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
    id: "files", title: "Files", glyph: Icons.files, width: 577, height: 475,
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
          // Open mode: confirm the single-click selection (a double-click resolves on its own via
          // onPick). Fall back to the last picked file if the browser exposes no current selection.
          var s = apiRef && apiRef.getSel ? apiRef.getSel() : null;
          if (s && !s.dir) { close(s.path); }
          else if (lastFile) { close(lastFile); }
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
        '<div class="toolbar"><button class="btn mopen">Open </button>' +
          '<button class="btn mdecode">Decode B64</button>' +
          '<span class="muted mname" style="margin-left:10px;align-self:center"></span></div>' +
        '<div class="mstage" style="flex:1;min-height:0;display:flex;align-items:center;justify-content:center">' +
          '<div class="muted mload" style="padding:16px">No image open. Use "Open image" to load one.</div>' +
          '<img class="mimg" style="display:none;max-width:100%;max-height:100%;object-fit:contain">' +
        '</div>';
      var img = body.querySelector(".mimg");
      var load = body.querySelector(".mload");
      var nameEl = body.querySelector(".mname");
      // Guess the MIME type from a base64 payload's magic prefix (mirrors the SQF-side detection).
      function mimeFromB64(b64) {
        var h = String(b64 || "").slice(0, 8);
        if (h.slice(0, 5) === "iVBOR") return "image/png";
        if (h.slice(0, 4) === "/9j/") return "image/jpeg";
        if (h.slice(0, 6) === "R0lGOD") return "image/gif";
        if (h.slice(0, 5) === "UklGR") return "image/webp";
        if (h.slice(0, 2) === "Qk") return "image/bmp";
        return "image/png";
      }
      // Render a registered media source. It can be absolute (\myMod\img.paa), addon-relative, or
      // mission-relative (media\images\pic.jpg); try each form so any valid path resolves.
      function showImage(srcPath, name, opts) {
        opts = opts || {};
        nameEl.textContent = name || "";
        win.el.querySelector(".title").textContent = "Image Viewer" + (name ? " - " + name : "");
        // Inline base64 image: render straight as a data URL. No native fallback exists (native
        // RscPicture cannot load a data URL), so a decode failure just reports the error here.
        if (opts.b64) {
          var mime = opts.mime || "image/png";
          var data = String(opts.data || "").replace(/\s/g, "");
          img.onload = function () {
            if (!img.naturalWidth || !img.naturalHeight) { img.style.display = "none"; load.style.display = "block"; load.textContent = "Cannot decode this base64 image."; return; }
            load.style.display = "none"; img.style.display = "block";
          };
          img.onerror = function () { img.style.display = "none"; load.style.display = "block"; load.textContent = "Cannot decode this base64 image."; };
          img.style.display = "none"; load.style.display = "block"; load.textContent = "Rendering image...";
          img.src = "data:" + mime + ";base64," + data;
          return;
        }

        if (!srcPath) { img.style.display = "none"; load.style.display = "block"; load.textContent = 'No image open. Use "Open image" to load one.'; return; }

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
            if (media && media.type === "image" && media.b64) {
              showImage("", p.split("/").pop(), { b64: true, mime: media.mime, data: media.data, vfsPath: p, marker: content });
              return;
            }
            if (media && media.type === "image") {
              showImage(media.path, p.split("/").pop(), { scope: media.scope, web: media.web, vfsPath: p, marker: content });
              return;
            }
            Modal.alert("Open image", "That file is not an image.");
          });
        });
      });

      // Decode B64: paste raw base64 and render it live in this viewer, without touching the VFS.
      body.querySelector(".mdecode").addEventListener("click", function () {
        Modal.decodeB64().then(function (r) {
          if (!r || !r.data) return;
          var data = String(r.data).replace(/\s/g, "");
          var m = data.indexOf(";base64,");
          var mime = "";
          if (m !== -1) {
            var head = data.slice(0, m);
            var c = head.indexOf("data:");
            if (c !== -1) mime = head.slice(c + 5);
            data = data.slice(m + 8);
          }
          if ((r.type || "auto") !== "auto") { mime = "image/" + r.type; }
          if (!mime) { mime = mimeFromB64(data); }
          showImage("", "Pasted image", { b64: true, mime: mime, data: data });
        });
      });

      if (args && args.b64) {
        showImage("", (args && args.title) || "image", { b64: true, mime: args.mime, data: args.data, vfsPath: (args && args.vfsPath), marker: (args && args.marker) });
      } else {
        showImage((args && args.path) || "",
          (args && args.title) || ((args && args.path) ? String(args.path).split("\\").pop().split("/").pop() : ""),
          { scope: (args && args.scope), web: (args && args.web), vfsPath: (args && args.vfsPath), marker: (args && args.marker) });
      }
    }
  });

  // ---------------- Terminal ----------------
  // Action app (no window): switches this laptop from the GUI desktop to the CLI terminal. The SQF
  // side (jsRouter "sys_switch_cli") closes the web desktop and opens the classic terminal, gated by
  // the laptop's CLI interface-access rules. The `desktop` terminal command switches back.
  Apps.register({
    id: "terminal", title: "Terminal", glyph: (Icons.terminal || ">_"),
    showOnDesktop: false, showInDock: false, singleton: true,
    action: function () { A3.send("sys_switch_cli", {}); }
  });

  // ---------------- Settings ----------------
  Apps.register({
    id: "settings", title: "Settings", glyph: Icons.settings, width: 458, height: 458,
    showOnDesktop: true, showInDock: true, singleton: true,
    render: function (body) {
      body.innerHTML =
        '<div class="pad">' +
          '<h3>System</h3><div id="sysinfo" class="muted">Reading&hellip;</div>' +
          '<h3 style="margin-top:14px">Personalisation</h3>' +
          '<div style="display:flex;flex-direction:column;gap:8px;max-width:420px">' +
            '<label class="muted">System name (hostname)</label>' +
            '<input class="input shost" placeholder="armaOS">' +
            '<label class="muted">Wallpaper (CSS colour/gradient or image path, blank = default). Saved per user.</label>' +
            '<input class="input swall" placeholder="#1d1d1d or linear-gradient(...) or \\\\z\\\\...\\\\bg.jpg">' +
            '<div class="wallgrid" style="display:flex;flex-wrap:wrap;gap:6px;margin-top:2px"></div>' +
            '<div><button class="btn accent ssave">Apply</button> <span class="muted sst"></span></div>' +
          '</div>' +
        '</div>';
      var box = body.querySelector("#sysinfo");
      var hostEl = body.querySelector(".shost");
      var wallEl = body.querySelector(".swall");
      // Reads laptop status into the System panel. On the first load the editable fields are seeded
      // too; later live refreshes (Zeus/mission-maker changes pushed via "sys_changed") only repaint
      // the read-only readout. SSH access and the IP address are configured in the Network app.
      function loadSysinfo(initial) {
        A3.request("sysinfo", {}).then(function (s) {
          s = s || {};
          box.innerHTML =
            "Hostname: " + esc(s.hostname || "?") + "<br>" +
            "IP: " + esc(s.ip || "?") + " &nbsp; Gateway: " + esc(s.gateway || "?") + "<br>" +
            "Power: " + esc(s.power || "?") + " &nbsp; Battery: " + (s.battery != null ? s.battery + "%" : "?") + "<br>" +
            "Uptime: " + esc(s.uptime || "?");
          if (initial) {
            if (hostEl) hostEl.value = s.hostname || "";
            if (wallEl) wallEl.value = s.wallpaper || "";
          }
        }).catch(function () { box.textContent = "Unavailable"; });
      }
      loadSysinfo(true);
      // Live-update the panel when a curator/mission-maker changes battery, wifi, IP or hostname.
      A3.on("sys_changed", function () { loadSysinfo(false); });

      // Selectable wallpaper thumbnails (bundled images + any registered). Clicking one applies it for
      // the current user immediately; each engine texture is resolved to a data URL for the preview.
      var wallGrid = body.querySelector(".wallgrid");
      A3.request("wallpaper_list", {}).then(function (r) {
        ((r && r.wallpapers) || []).forEach(function (p) {
          var thumb = document.createElement("div");
          thumb.style.cssText = "width:72px;height:44px;border-radius:4px;background:#222 center/cover no-repeat;cursor:pointer;border:1px solid var(--line)";
          thumb.title = p;
          A3.loadImage(p).then(function (url) { thumb.style.backgroundImage = "url('" + url + "')"; }).catch(function () {});
          thumb.addEventListener("click", function () {
            if (wallEl) wallEl.value = p;
            A3.request("sys_set", { wallpaper: p }).then(function () { Desktop.setWallpaper(p); });
          });
          wallGrid.appendChild(thumb);
        });
      }).catch(function () {});
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
      body.innerHTML = '<div class="pad">' +
        '<div style="display:flex;align-items:center"><h3 style="flex:1">Wireless networks</h3>' +
          '<span class="muted nstat" style="margin-right:8px"></span>' +
          '<button class="btn nsettings" style="margin-right:6px">Settings</button>' +
          '<button class="btn rescan">Rescan</button></div>' +
        '<div class="netcfg" style="display:none;border:1px solid var(--line);border-radius:6px;padding:10px;margin:8px 0;flex-direction:column;gap:8px;max-width:420px">' +
          '<div class="muted ninfo"></div>' +
          '<label class="muted" style="display:flex;align-items:center;gap:8px"><input type="checkbox" class="ssh"> Allow SSH access to this device</label>' +
          '<label class="muted">IP address (changes immediately)</label>' +
          '<div style="display:flex;gap:8px"><input class="input sipval" placeholder="192.168.x.x" style="flex:1"><button class="btn accent sipapply">Apply</button></div>' +
          '<span class="muted sipst"></span>' +
        '</div>' +
        '<ul class="list nets"><li class="muted">Scanning&hellip;</li></ul></div>';
      var nets = body.querySelector(".nets");
      var statEl = body.querySelector(".nstat");

      // Device settings panel (SSH access + IP address), toggled by the Settings button next to Rescan.
      var cfg = body.querySelector(".netcfg");
      var infoEl = body.querySelector(".ninfo");
      var sshEl = body.querySelector(".ssh");
      var sipEl = body.querySelector(".sipval");
      var sipSt = body.querySelector(".sipst");
      body.querySelector(".nsettings").addEventListener("click", function () {
        cfg.style.display = (cfg.style.display === "none") ? "flex" : "none";
      });
      sshEl.addEventListener("change", function () {
        A3.request("ssh_config", { enabled: sshEl.checked });
      });
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
      // Seed the SSH state and IP field, and keep the SSH toggle in sync with mission-maker changes.
      // The IP input is only seeded when the panel is closed so a mid-edit value is not clobbered.
      function loadNetCfg(initial) {
        A3.request("sysinfo", {}).then(function (s) {
          s = s || {};
          sshEl.checked = !!s.sshEnabled;
          if (initial || cfg.style.display === "none") sipEl.value = s.ip || "";
          infoEl.textContent = "Current IP: " + (s.ip || "?") + "  ---  Default Gateway: " + (s.gateway || "?");
        }).catch(function () {});
      }
      loadNetCfg(true);
      A3.on("sys_changed", function () { loadNetCfg(false); });
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
    id: "calendar", title: "Calendar", glyph: Icons.calendar, width: 560, height: 740,
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
            '<div style="display:flex;align-items:center"><b style="flex:1">' + (e.time ? esc(e.time) + ' &#183; ' : "") + esc(e.title) + '</b><button class="btn evdel" data-idx="' + e.index + '">&#215;</button></div>' +
            (e.location ? '<div class="muted" style="font-size:12px">@ ' + esc(e.location) + '</div>' : "") +
            (e.body ? '<div style="margin-top:4px;white-space:pre-wrap">' + esc(e.body) + '</div>' : "") +
            '</div>';
        });
        html += '<hr style="border-color:var(--line)"><div style="display:flex;flex-direction:column;gap:6px">' +
          '<input class="input ntitle" placeholder="New event title">' +
          '<input class="input ntime" placeholder="Time HH:MM (optional)">' +
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
          A3.request("cal_add", { date: iso, title: title, time: detail.querySelector(".ntime").value, location: detail.querySelector(".nloc").value, body: detail.querySelector(".nbody").value }).then(function (r) {
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
      var sites = {}; // reserved for friendly-name -> page shortcuts; populated by regSites at runtime
      var intelPages = []; // intel pages registered via Zeus/API
      // True while a saved active tab is still waiting on these same registries to resolve its real
      // address (see the restore block below). The address bar reads "home" (its markup default)
      // during that wait regardless of which tab is being restored, so the home-refresh self-heal
      // below must not fire in that window - it would stomp the not-yet-resolved tab's saved label
      // with "home" via its own nav("home", true) call before the restore ever gets to use it.
      var _pendingRestore = false;
      function reloadIntelPages() {
        return A3.request("web_pages", {}).then(function (res) {
          intelPages = (res && res.pages) || [];
          // The page list arrives asynchronously. If the active tab is still on the homepage, re-resolve
          // it now that the list is available so the registered RootNet home replaces the static fallback
          // that was shown while the list was still empty.
          if (!_pendingRestore && active >= 0 && addrEl.value === "home") { nav("home", true); }
        }).catch(function () {});
      }
      // The laptop's homepage is the server-seeded RootNet index (registered as rootnet.root / home.root).
      // Until the page list loads - and if a mission ever strips the page - fall back to a static RootNet
      // page with the same content so the browser home is never the old Portal sample and never empty.
      var ROOTNET_HOME = "<t size='1.2'>Welcome to RootNet</t>\n\nThe internal network index. Pages published on this network appear on the home screen.\n\nType an address in the bar above, or pick a link below.\n\n[[home.root|Home]]";
      function homeTarget() {
        for (var hi = 0; hi < intelPages.length; hi++) {
          var u = (intelPages[hi].url || "").toLowerCase();
          if (u === "rootnet.root" || u === "home.root") {
            return { type: "intel", title: intelPages[hi].title, content: intelPages[hi].content, label: "home" };
          }
        }
        return { type: "intel", title: "RootNet", content: ROOTNET_HOME, label: "home" };
      }
      var _introLoaded = reloadIntelPages();
      // Registered custom domains -> mission site-root folders (AE3_desktop_fnc_registerSite).
      var regSites = {}; // { "thisisme.com": "sites/portal", ... }
      function reloadSites() {
        return A3.request("web_sites", {}).then(function (res) { regSites = (res && res.sites) || {}; }).catch(function () {});
      }
      var _sitesLoaded = reloadSites();
      // Re-pull the page + site lists when content is registered or removed while the Browser is open.
      A3.on("web_changed", reloadIntelPages);
      A3.on("web_changed", reloadSites);

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
        '<div class="tabbar" style="display:flex;align-items:center;gap:2px;padding:3px 4px 0;overflow-x:auto;background:var(--surface-2)"></div>' +
        '<div class="toolbar">' +
          '<button class="btn back" title="Back">&#8592;</button><button class="btn fwd" title="Forward">&#8594;</button>' +
          '<button class="btn home" title="Home">&#8962;</button>' +
          '<input class="input addr" style="flex:1" value="home">' +
          '<button class="btn accent go">Go</button>' +
          '<button class="btn hist" title="History" style="margin-left:4px">&#9776;</button>' +
        '</div>' +
        '<iframe class="page" style="width:100%;height:calc(100% - 82px);border:none;background:#fff"></iframe>';
      var frame = body.querySelector(".page");
      var addrEl = body.querySelector(".addr");
      var tabBar = body.querySelector(".tabbar");
      // Multiple tabs share one iframe. Each tab keeps its own history, current directory, address and
      // last-rendered document; switching a tab saves the live state and restores the target's.
      var tabs = [], active = -1;
      var history = [], hi = -1;
      var curDir = ""; // directory of the page currently shown, so relative in-page links resolve

      function saveTab() {
        if (active < 0) return;
        var T = tabs[active];
        T.history = history; T.hi = hi; T.curDir = curDir; T.label = addrEl.value; T.doc = frame.srcdoc;
      }
      function applyTab(i) {
        active = i; var T = tabs[i];
        // A tab restored from a previous session has only its address saved (no live document); load it
        // the first time it is shown instead of displaying a blank page.
        if (T.pending) {
          T.pending = false;
          history = []; hi = -1; curDir = "";
          addrEl.value = T.label || "home";
          renderTabs();
          nav(T.label || "home");
          return;
        }
        history = T.history; hi = T.hi; curDir = T.curDir; addrEl.value = T.label; frame.srcdoc = T.doc || "";
        window.AE3_browserNav = function (href) { nav(href); };
        renderTabs();
        persistTabs();
      }
      // Persist the open tabs (their addresses + the active index) onto the window's args, so the WM
      // layout snapshot saved to the laptop restores them when the desktop is closed and reopened.
      function persistTabs() {
        if (!win) return;
        win.args = {
          tabs: tabs.map(function (T, i) { return (i === active ? addrEl.value : (T.label || "home")); }),
          active: active
        };
        if (window.WM && WM.onStateChange) WM.onStateChange();
      }
      function renderTabs() {
        tabBar.innerHTML = "";
        tabs.forEach(function (T, i) {
          var tab = document.createElement("div");
          tab.style.cssText = "display:flex;align-items:center;gap:6px;max-width:170px;padding:4px 8px;border-radius:6px 6px 0 0;cursor:pointer;font-size:12px;white-space:nowrap;" +
            (i === active ? "background:var(--surface);color:var(--text)" : "background:transparent;color:var(--muted)");
          var name = document.createElement("span");
          name.textContent = (i === active ? addrEl.value : T.label) || "home";
          name.style.cssText = "overflow:hidden;text-overflow:ellipsis";
          tab.appendChild(name);
          if (tabs.length > 1) {
            var x = document.createElement("span");
            x.innerHTML = "&#215;"; x.style.cssText = "opacity:.7";
            x.addEventListener("click", function (e) { e.stopPropagation(); closeTab(i); });
            tab.appendChild(x);
          }
          tab.addEventListener("click", function () { if (i !== active) { saveTab(); applyTab(i); } });
          tabBar.appendChild(tab);
        });
        var add = document.createElement("div");
        add.textContent = "+"; add.title = "New tab";
        add.style.cssText = "padding:4px 9px;cursor:pointer;font-size:15px;color:var(--muted)";
        add.addEventListener("click", function () { newTab(); });
        tabBar.appendChild(add);
      }
      function newTab() {
        saveTab();
        tabs.push({ history: [], hi: -1, curDir: "", label: "home", doc: "" });
        active = tabs.length - 1;
        history = []; hi = -1; curDir = "";
        renderTabs();
        nav("home");
      }
      function closeTab(i) {
        if (tabs.length <= 1) return;
        if (i === active) saveTab();
        tabs.splice(i, 1);
        if (active > i) active -= 1; else if (active >= tabs.length) active = tabs.length - 1;
        applyTab(active);
        persistTabs();
      }

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

        // Registered custom domain? Match the host part (before the first "/"); the rest is a subpath
        // under the site root. "thisisme.com" -> <root>/index.html; "thisisme.com/about" -> <root>/about.
        // Checked before the generic path branch so a domain with a subpath is not mistaken for a file.
        var rawStripped = addr.replace(/^https?:\/\//i, "");
        var rawSlash = rawStripped.indexOf("/");
        var host = (rawSlash < 0 ? rawStripped : rawStripped.slice(0, rawSlash)).toLowerCase().replace(/\/+$/, "");
        if (regSites[host]) {
          var root = String(regSites[host]).replace(/\/+$/, "");
          var sub = (rawSlash < 0 ? "" : rawStripped.slice(rawSlash + 1)).replace(/^\/+/, "");
          return { type: "html", path: (sub === "" ? (root + "/index.html") : (root + "/" + sub)), label: addr };
        }

        var hasPath = addr.charAt(0) === "\\" || /^[a-z]:/i.test(addr) || addr.indexOf("/") >= 0 || addr.indexOf("\\") >= 0;
        var mdName = addr.match(/([^\/\\]+\.md)(?:[#?].*)?$/i); // keep original case for the VFS lookup

        // Explicit .md: a bare filename normally means a wiki page, BUT when we are inside a mission
        // site (curDir under sites/) a bare .md link is page-relative to that site (e.g. the gallery
        // page's "gallery.md"). A pathed .md (mod/mission) loads as given.
        if (/\.md($|[#?])/i.test(addr)) {
          if (mdName && !hasPath) {
            var inSite = curDir && /^sites\//i.test(curDir);
            return { type: "md", path: (inSite ? (curDir + mdName[1]) : ("wiki/" + mdName[1])), label: mdName[1] };
          }
          return { type: "md", path: addr, label: addr };
        }
        // Explicit .html / any pathed address: load through the root search (mod or mission). A
        // page-relative href (e.g. portal's "../wiki/index.html") is joined to the current page's
        // directory; bridge.loadFile then collapses the ".." so A3API gets a clean path.
        if (/\.html?($|[#?])/i.test(addr) || hasPath) {
          var p;
          if (!isAbsolute(addr) && isPageRelative(addr)) {
            p = curDir + addr;
          } else if (!isAbsolute(addr) && curDir && /^sites\//i.test(curDir) && !/^sites\//i.test(addr)) {
            // A slash-containing link inside a mission site (e.g. the gallery page's "assets/night.svg")
            // is relative to the site folder, not the VFS root, so join it to the current site directory.
            p = curDir + addr;
          } else {
            p = addr;
          }
          return { type: "html", path: p, label: addr };
        }

        var lower = addr.toLowerCase().replace(/^https?:\/\//, "").replace(/\/+$/, "");
        if (lower === "home" || lower === "rootnet") return homeTarget();
        if (sites[lower]) return sites[lower];
        for (var pi = 0; pi < intelPages.length; pi++) {
          if ((intelPages[pi].url || "").toLowerCase() === lower) {
            return { type: "intel", title: intelPages[pi].title, content: intelPages[pi].content, label: intelPages[pi].url };
          }
        }
        return homeTarget();
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
            '<label>Allowed sources (blank = any)</label><input id="ra" value="' + esc(String(r.extAllow || "")) + '">' +
            '<p class="sub" style="margin:4px 0 0">Comma-separated. A router gateway IP (e.g. 192.168.0.1) allows every laptop on that router; a specific IP allows just that host; or use a regex.</p>' +
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
          // Run the body through the Markdown renderer so wiki-style [[url|label]] links and basic
          // formatting become real anchors/markup instead of literal text in a raw <pre>.
          setDoc(wikiDoc("<h1>" + esc(t.title || t.label) + "</h1>" + MD.render(t.content || "")));
          return;
        }
        if (t.type === "md") {
          A3.loadFile(t.path).then(function (mdText) {
            curDir = dirOf(t.path); // base for relative links, adopted only once the page actually loaded
            setDoc(wikiDoc(MD.render(mdText || "")));
          }).catch(function (e) { console.error("[AE3] browser md load failed:", t.path, e); setDoc(wikiDoc("<h1>Page not found</h1><p><a href=\"home\">Back to home</a></p>")); });
        } else {
          A3.loadFile(t.path).then(function (htmlText) {
            curDir = dirOf(t.path);
            setDoc(htmlText || "<p>Empty page.</p>");
          }).catch(function (e) { console.error("[AE3] browser html load failed:", t.path, e); setDoc("<p style='font-family:sans-serif;padding:20px'>Page unavailable.</p>"); });
        }
      }

      function nav(addrRaw, fromHistory) {
        var t = resolve(addrRaw);
        if (!fromHistory) { history = history.slice(0, hi + 1); history.push(t); hi = history.length - 1; }
        window.AE3_browserNav = function (href) { nav(href); }; // active browser drives in-page links
        if (!fromHistory && t.label !== "home") { A3.send("web_log", { url: t.label }); }
        load(t);
        if (active >= 0) { tabs[active].label = addrEl.value; }
        renderTabs();
        persistTabs();
      }
      // Back/forward restore a previously visited target as-is. Re-resolving a bare label (e.g. a mission
      // site's "gallery.md") would depend on the current directory, which changes as you browse deeper,
      // so the stored resolved target is loaded directly instead of being resolved again.
      function loadHistoryEntry() {
        window.AE3_browserNav = function (href) { nav(href); };
        load(history[hi]);
        if (active >= 0) { tabs[active].label = addrEl.value; }
        renderTabs();
      }

      body.querySelector(".go").addEventListener("click", function () { nav(addrEl.value); });
      body.querySelector(".home").addEventListener("click", function () { nav("home"); });
      body.querySelector(".back").addEventListener("click", function () { if (hi > 0) { hi--; loadHistoryEntry(); } });
      body.querySelector(".fwd").addEventListener("click", function () { if (hi < history.length - 1) { hi++; loadHistoryEntry(); } });
      addrEl.addEventListener("keydown", function (e) { if (e.key === "Enter") nav(addrEl.value); });
      body.querySelector(".hist").addEventListener("click", function () {
        A3.request("web_history", {}).then(function (res) {
          var text = (res && res.history) || "";
          var rows = text.split(/\r?\n/).filter(function (l) { return l.trim() !== ""; });
          var html;
          if (!rows.length) { html = "<p>(no history)</p>"; }
          else {
            // Each logged line is "[HH:MM] <address>"; render the address as a live link that drives
            // the address bar. The in-page click hook routes the <a> back through nav().
            html = "<ul style='list-style:none;padding:0;line-height:1.9'>" + rows.map(function (l) {
              var m = l.match(/^\s*(\[[^\]]*\])?\s*(.*)$/);
              var ts = m && m[1] ? m[1] : "";
              var url = (m ? m[2] : l).trim();
              return "<li><span class='muted' style='margin-right:8px'>" + esc(ts) + "</span><a href='" + esc(url) + "'>" + esc(url) + "</a></li>";
            }).join("") + "</ul>";
          }
          setDoc(wikiDoc("<h1>Browser History</h1>" + html));
          addrEl.value = "history";
        }).catch(function () { setDoc(wikiDoc("<h1>Browser History</h1><p>Unavailable.</p>")); });
      });

      // Re-bind the in-page link hook to this window whenever it gains focus.
      win.el.addEventListener("mousedown", function () { window.AE3_browserNav = function (href) { nav(href); }; });

      // Restore the tabs saved from a previous desktop session (addresses + active tab), else open the
      // first tab on the laptop homepage. Only the active tab loads now; the rest load when first shown.
      var _saved = (win && win.args && win.args.tabs && win.args.tabs.length) ? win.args : null;
      if (_saved) {
        _saved.tabs.forEach(function (label) {
          tabs.push({ history: [], hi: -1, curDir: "", label: label || "home", doc: "", pending: true });
        });
        active = Math.min(Math.max(_saved.active | 0, 0), tabs.length - 1);
        history = []; hi = -1; curDir = "";
        renderTabs();
        // Wait for the intel-page/site registries to load before resolving the active tab's saved
        // address - resolving too early (still-empty intelPages/regSites) silently falls back to home
        // and loses the real target, since restore only re-loads the active tab immediately (inactive
        // tabs stay pending until clicked, by which point the registries have long since loaded).
        _pendingRestore = true;
        Promise.all([_introLoaded, _sitesLoaded]).then(function () {
          _pendingRestore = false;
          tabs[active].pending = false;
          nav(tabs[active].label || "home");
        });
      } else {
        newTab(); // open the first tab (navigates to the laptop homepage)
      }
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
      var range = 50;
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

  // ---------------- Cryptography Helpers ----------------
  var CryptoLab = (function () {
    var U = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    var L = "abcdefghijklmnopqrstuvwxyz";
    var WORDS = ["the", "and", "that", "have", "for", "not", "with", "you", "this", "but", "from", "they", "say", "her", "she", "will", "one", "all", "would", "there", "their", "what", "about", "which", "when", "make", "can", "like", "time", "just", "him", "know", "take", "people", "into", "year", "your", "good", "some", "could", "them", "see", "other", "than", "then", "now", "look", "only", "come", "its", "over", "think", "also", "back", "after", "use", "two", "how", "our", "work", "first", "well", "way", "even", "new", "want", "because", "any", "these", "give", "day", "most", "us"];
    var MORSE = { A: ".-", B: "-...", C: "-.-.", D: "-..", E: ".", F: "..-.", G: "--.", H: "....", I: "..", J: ".---", K: "-.-", L: ".-..", M: "--", N: "-.", O: "---", P: ".--.", Q: "--.-", R: ".-.", S: "...", T: "-", U: "..-", V: "...-", W: ".--", X: "-..-", Y: "-.--", Z: "--..", 0: "-----", 1: ".----", 2: "..---", 3: "...--", 4: "....-", 5: ".....", 6: "-....", 7: "--...", 8: "---..", 9: "----.", ".": ".-.-.-", ",": "--..--", "?": "..--..", "!": "-.-.--", "-": "-....-", "/": "-..-.", "(": "-.--.", ")": "-.--.-", "&": ".-...", ":": "---...", ";": "-.-.-.", "=": "-...-", "+": ".-.-.", "_": "..--.-", "\"": ".-..-.", "$": "...-..-", "@": ".--.-.", "'": ".----." };
    var MORSE_REV = {};
    var NATO = { A: "Alpha", B: "Bravo", C: "Charlie", D: "Delta", E: "Echo", F: "Foxtrot", G: "Golf", H: "Hotel", I: "India", J: "Juliett", K: "Kilo", L: "Lima", M: "Mike", N: "November", O: "Oscar", P: "Papa", Q: "Quebec", R: "Romeo", S: "Sierra", T: "Tango", U: "Uniform", V: "Victor", W: "Whiskey", X: "Xray", Y: "Yankee", Z: "Zulu", 0: "Zero", 1: "One", 2: "Two", 3: "Three", 4: "Four", 5: "Five", 6: "Six", 7: "Seven", 8: "Eight", 9: "Nine" };
    var NATO_REV = {};
    var BASE64_STD = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    var BASE64_URL = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
    var BASE32_STD = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
    var BASE32_HEX = "0123456789ABCDEFGHIJKLMNOPQRSTUV";
    var BACON24 = "ABCDEFGHIKLMNOPQRSTUWXYZ";
    var BACON26 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    var BACON_REV24 = {};
    var BACON_REV26 = {};
    var FREQ = { e: 12.7, t: 9.1, a: 8.2, o: 7.5, i: 7.0, n: 6.7, s: 6.3, h: 6.1, r: 6.0, d: 4.3, l: 4.0, c: 2.8, u: 2.8, m: 2.4, w: 2.4, f: 2.2, g: 2.0, y: 2.0, p: 1.9, b: 1.5, v: 1.0, k: 0.8, j: 0.2, x: 0.2, q: 0.1, z: 0.1 };
    function arr(s) { return Array.from(String(s || "")); }
    function mod(n, m) { return ((n % m) + m) % m; }
    function gcd(a, b) { while (b !== 0) { var t = b; b = a % b; a = t; } return Math.abs(a); }
    function inv(a, m) { a = mod(a, m); for (var i = 1; i < m; i++) { if (mod(a * i, m) === 1) return i; } return -1; }
    function toBytes(s) { return window.TextEncoder ? new TextEncoder().encode(String(s || "")) : Uint8Array.from(unescape(encodeURIComponent(String(s || ""))), function (c) { return c.charCodeAt(0); }); }
    function fromBytes(bytes) { return window.TextDecoder ? new TextDecoder("utf-8", { fatal: false }).decode(bytes) : decodeURIComponent(escape(String.fromCharCode.apply(null, bytes))); }
    function bin(bytes) { var s = ""; for (var i = 0; i < bytes.length; i += 8192) { s += String.fromCharCode.apply(null, bytes.slice(i, i + 8192)); } return s; }
    function b64(bytes, url) { return btoa(bin(bytes)).replace(/\+/g, url ? "-" : "+").replace(/\//g, url ? "_" : "/"); }
    function unb64(s, url) { s = String(s || "").replace(/\s+/g, ""); if (url) s = s.replace(/-/g, "+").replace(/_/g, "/"); while ((s.length % 4) !== 0) s += "="; var out = []; var raw = atob(s); for (var i = 0; i < raw.length; i++) out.push(raw.charCodeAt(i)); return Uint8Array.from(out); }
    function bytesToBase32(bytes, hex, pad) {
      var alp = hex ? BASE32_HEX : BASE32_STD, out = "", bits = 0, val = 0;
      for (var i = 0; i < bytes.length; i++) { val = (val << 8) | bytes[i]; bits += 8; while (bits >= 5) { out += alp[(val >>> (bits - 5)) & 31]; bits -= 5; } }
      if (bits > 0) out += alp[(val << (5 - bits)) & 31];
      if (pad !== false) while ((out.length % 8) !== 0) out += "=";
      return out;
    }
    function base32ToBytes(s, hex) {
      var alp = hex ? BASE32_HEX : BASE32_STD, map = {}, val = 0, bits = 0, out = [];
      for (var i = 0; i < alp.length; i++) map[alp[i]] = i;
      s = String(s || "").toUpperCase().replace(/[^A-Z2-7=0-9]/g, "");
      if (hex) s = s.replace(/[^0-9A-V=]/g, "");
      for (var j = 0; j < s.length; j++) {
        var ch = s[j];
        if (ch === "=") break;
        if (!(ch in map)) continue;
        val = (val << 5) | map[ch];
        bits += 5;
        if (bits >= 8) { out.push((val >>> (bits - 8)) & 255); bits -= 8; }
      }
      return Uint8Array.from(out);
    }
    function ascii85Encode(bytes, adobe, compress) {
      var out = [], i = 0;
      while (i < bytes.length) {
        var remain = Math.min(4, bytes.length - i), chunk = [0, 0, 0, 0];
        for (var j = 0; j < remain; j++) chunk[j] = bytes[i + j];
        i += remain;
        var v = (((chunk[0] * 256 + chunk[1]) * 256 + chunk[2]) * 256 + chunk[3]) >>> 0;
        if (compress !== false && remain === 4 && v === 0) { out.push("z"); continue; }
        var digits = ["", "", "", "", ""];
        for (var k = 4; k >= 0; k--) { digits[k] = String.fromCharCode((v % 85) + 33); v = Math.floor(v / 85); }
        out.push(digits.join("").slice(0, remain + 1));
      }
      return (adobe ? "<~" : "") + out.join("") + (adobe ? "~>" : "");
    }
    function ascii85Decode(s) {
      s = String(s || "").replace(/<~|~>/g, "").replace(/\s+/g, "");
      var out = [], group = "";
      for (var i = 0; i < s.length; i++) {
        var ch = s[i];
        if (ch === "z") { out.push(0, 0, 0, 0); continue; }
        group += ch;
        if (group.length === 5) {
          var v = 0;
          for (var j = 0; j < 5; j++) v = v * 85 + (group.charCodeAt(j) - 33);
          out.push((v >>> 24) & 255, (v >>> 16) & 255, (v >>> 8) & 255, v & 255);
          group = "";
        }
      }
      if (group.length > 0) {
        var pad = 5 - group.length;
        while (group.length < 5) group += "u";
        var vv = 0;
        for (var jj = 0; jj < 5; jj++) vv = vv * 85 + (group.charCodeAt(jj) - 33);
        var tail = [(vv >>> 24) & 255, (vv >>> 16) & 255, (vv >>> 8) & 255, vv & 255];
        out.push.apply(out, tail.slice(0, 4 - pad));
      }
      return Uint8Array.from(out);
    }
    function score(text) {
      var t = String(text || "").toLowerCase(), s = 0;
      if (/[\u0000-\u0008\u000b\u000c\u000e-\u001f]/.test(t)) s -= 500;
      for (var i = 0; i < t.length; i++) {
        var ch = t[i], code = t.charCodeAt(i);
        if (ch === " ") s += 1;
        else if (ch in FREQ) s += FREQ[ch];
        else if (/[a-z]/.test(ch)) s += 0.5;
        else if (/[0-9]/.test(ch)) s += 0.1;
        else if (",.;:'\"!?()-/".indexOf(ch) >= 0) s += 0.05;
        else if (code < 32 || code > 126) s -= 4;
        else s -= 0.05;
      }
      for (var j = 0; j < WORDS.length; j++) if (t.indexOf(WORDS[j]) >= 0) s += WORDS[j].length * 2;
      return s;
    }
    function formatCase(src, out) { return src === src.toLowerCase() ? out.toLowerCase() : out; }
    function alphaByMode(mode) { return mode === "lower" ? L : U; }
    function cleanKeyword(text) { return arr(text).map(function (c) { return c.toUpperCase(); }).filter(function (c) { return U.indexOf(c) >= 0; }).join(""); }
    function keywordAlphabet(keyword, base) {
      base = base || U;
      var seen = {}, out = "";
      arr(keyword).map(function (c) { return c.toUpperCase(); }).forEach(function (c) { if (base.indexOf(c) >= 0 && !seen[c]) { seen[c] = true; out += c; } });
      arr(base).forEach(function (c) { if (!seen[c]) { seen[c] = true; out += c; } });
      return out;
    }
    function mapAlpha(text, from, to, preserve) {
      from = from || U; to = to || U;
      return arr(text).map(function (ch) {
        var u = ch.toUpperCase(), idx = from.indexOf(u);
        if (idx < 0) return ch;
        var out = to[idx % to.length];
        return preserve ? formatCase(ch, out) : out;
      }).join("");
    }
    function affine(text, opts, decrypt) {
      var alpha = alphaByMode(opts.alphaMode || "upper"), a = Number(opts.a || 1), b = Number(opts.b || 0), n = alpha.length;
      if (gcd(a, n) !== 1) return "";
      var invA = inv(a, n);
      if (decrypt) { if (invA < 0) return ""; a = invA; b = mod(-a * b, n); }
      return arr(text).map(function (ch) {
        var u = ch.toUpperCase(), idx = alpha.indexOf(u);
        if (idx < 0) return ch;
        var out = alpha[mod(a * idx + b, n)];
        return opts.preserveCase ? formatCase(ch, out) : out;
      }).join("");
    }
    function rot(text, kind, decrypt, preserveCase) {
      var shift = kind === "rot5" ? 5 : kind === "rot13" ? 13 : kind === "rot18" ? 18 : 47, sign = decrypt ? -1 : 1;
      return arr(text).map(function (ch) {
        var code = ch.charCodeAt(0);
        if (kind === "rot47" && code >= 33 && code <= 126) return String.fromCharCode(33 + mod((code - 33) + sign * shift, 94));
        if (/[0-9]/.test(ch) && (kind === "rot5" || kind === "rot18")) return String.fromCharCode(48 + mod((code - 48) + sign * 5, 10));
        if (/[A-Za-z]/.test(ch) && (kind === "rot13" || kind === "rot18")) {
          var base = ch === ch.toLowerCase() ? 97 : 65;
          var out = String.fromCharCode(base + mod((code - base) + sign * 13, 26));
          return preserveCase ? out : out;
        }
        return ch;
      }).join("");
    }
    function vigenere(text, key, decrypt, opts) {
      var alpha = alphaByMode(opts.alphaMode || "upper"), k = cleanKeyword(key);
      if (!k) return "";
      var ki = 0;
      return arr(text).map(function (ch) {
        var u = ch.toUpperCase(), idx = alpha.indexOf(u);
        if (idx < 0) return ch;
        var ks = alpha.indexOf(k[ki % k.length]);
        if (ks < 0) return ch;
        ki++;
        var out = alpha[mod(idx + (decrypt ? -ks : ks), alpha.length)];
        return opts.preserveCase ? formatCase(ch, out) : out;
      }).join("");
    }
    function bacon(text, variant, decrypt) {
      var base = variant === "extended" ? BACON26 : BACON24;
      var rev = variant === "extended" ? BACON_REV26 : BACON_REV24;
      if (!decrypt) {
        return arr(text).map(function (ch) {
          var u = ch.toUpperCase();
          if (u === "J" && base === BACON24) u = "I";
          if (u === "V" && base === BACON24) u = "U";
          var idx = base.indexOf(u);
          return idx < 0 ? ch : idx.toString(2).padStart(5, "0").replace(/0/g, "A").replace(/1/g, "B");
        }).join(" ");
      }
      var bits = String(text || "").toUpperCase().replace(/[^AB]/g, "");
      var out = [];
      for (var i = 0; i + 4 < bits.length; i += 5) {
        var n = parseInt(bits.slice(i, i + 5).replace(/A/g, "0").replace(/B/g, "1"), 2);
        out.push(rev[n] || "?");
      }
      return out.join("");
    }
    function rail(text, rails, decrypt) {
      rails = Math.max(2, Number(rails || 2) | 0);
      var chars = arr(text), len = chars.length;
      if (rails >= len) return text;
      var pat = [], r = 0, d = 1;
      for (var i = 0; i < len; i++) { pat.push(r); if (r === 0) d = 1; else if (r === rails - 1) d = -1; r += d; }
      if (!decrypt) {
        var rows = Array.from({ length: rails }, function () { return []; });
        for (var j = 0; j < len; j++) rows[pat[j]].push(chars[j]);
        return rows.map(function (row) { return row.join(""); }).join("");
      }
      var counts = Array.from({ length: rails }, function () { return 0; });
      pat.forEach(function (p) { counts[p]++; });
      var slices = [], idx = 0;
      for (var rr = 0; rr < rails; rr++) { slices.push(chars.slice(idx, idx + counts[rr])); idx += counts[rr]; }
      var pos = Array.from({ length: rails }, function () { return 0; });
      return pat.map(function (p) { return slices[p][pos[p]++]; }).join("");
    }
    function morse(text, decrypt) {
      if (!decrypt) return arr(text).map(function (ch) { if (ch === " ") return "/"; var u = ch.toUpperCase(); return MORSE[u] || ch; }).join(" ");
      return String(text || "").trim().split(/\s+/).map(function (tok) { if (tok === "/" || tok === "|") return " "; return MORSE_REV[tok] || ""; }).join("").replace(/\s+/g, " ");
    }
    function spelling(text, decrypt) {
      if (!decrypt) return arr(text).map(function (ch) { if (ch === " ") return "/"; var u = ch.toUpperCase(); return NATO[u] || ch; }).join(" ");
      return String(text || "").trim().split(/\s+/).map(function (tok) { if (tok === "/" || tok === "|") return " "; return NATO_REV[tok.toLowerCase()] || ""; }).join("");
    }
    function unicode(text, decrypt, fmt) {
      if (!decrypt) return arr(text).map(function (ch) { return fmt === "escape" ? ("\\u" + ch.codePointAt(0).toString(16).toUpperCase().padStart(4, "0")) : ("U+" + ch.codePointAt(0).toString(16).toUpperCase().padStart(ch.codePointAt(0) > 0xFFFF ? 6 : 4, "0")); }).join(" ");
      var toks = String(text || "").match(/(?:U\+[0-9A-Fa-f]{2,6}|\\u[0-9A-Fa-f]{4})/g);
      return toks ? toks.map(function (tok) { var hex = tok[1] === "+" ? tok.slice(2) : tok.slice(2); return String.fromCodePoint(parseInt(hex, 16)); }).join("") : "";
    }
    function integer(text, decrypt, radix, width, signed) {
      var bits = Number(width || 8), max = Math.pow(2, bits), half = Math.pow(2, bits - 1);
      if (!decrypt) return arr(text).map(function (ch) {
        var n = ch.codePointAt(0);
        if (signed && n >= half) n -= max;
        var s = Math.abs(n).toString(radix).toUpperCase();
        if (radix === 2) s = s.padStart(bits, "0");
        else if (radix === 8) s = s.padStart(Math.ceil(bits / 3), "0");
        else if (radix === 16) s = s.padStart(Math.ceil(bits / 4), "0");
        return n < 0 ? "-" + s : s;
      }).join(" ");
      return String(text || "").trim().split(/[\s,;]+/).filter(Boolean).map(function (tok) {
        var neg = tok[0] === "-"; if (neg) tok = tok.slice(1);
        var n = parseInt(tok, radix);
        if (isNaN(n)) return "";
        if (neg) n = -n;
        if (signed && n < 0) n = max + n;
        return String.fromCodePoint(mod(n, max));
      }).join("");
    }
    function bestCaesar(col) {
      var best = { score: -1e9, key: 0, text: "" };
      for (var k = 0; k < 26; k++) {
        var out = rot(col, "rot13", true, true);
        out = arr(col).map(function (ch) {
          if (!/[A-Za-z]/.test(ch)) return ch;
          var base = ch === ch.toLowerCase() ? 97 : 65;
          return String.fromCharCode(base + mod((ch.charCodeAt(0) - base) - k, 26));
        }).join("");
        var sc = score(out);
        if (sc > best.score) best = { score: sc, key: k, text: out };
      }
      return best;
    }
    function crackAffine(text) {
      var out = [];
      for (var a = 1; a < 26; a++) if (gcd(a, 26) === 1) for (var b = 0; b < 26; b++) {
        var p = affine(text, { a: a, b: b, alphaMode: "upper", preserveCase: true }, true);
        if (p) out.push({ score: score(p), label: "a=" + a + " b=" + b, text: p });
      }
      out.sort(function (x, y) { return y.score - x.score; });
      return out.slice(0, 10).map(function (c) { return c.label + " | " + c.text; });
    }
    function crackRot(text, kind) {
      var max = kind === "rot47" ? 94 : kind === "rot5" ? 10 : 26, out = [];
      for (var i = 1; i < max; i++) {
        var p = arr(text).map(function (ch) {
          var code = ch.charCodeAt(0);
          if (kind === "rot47" && code >= 33 && code <= 126) return String.fromCharCode(33 + mod((code - 33) - i, 94));
          if (kind === "rot5" && /[0-9]/.test(ch)) return String.fromCharCode(48 + mod((code - 48) - i, 10));
          if (kind === "rot13" && /[A-Za-z]/.test(ch)) {
            var base = ch === ch.toLowerCase() ? 97 : 65;
            return String.fromCharCode(base + mod((code - base) - i, 26));
          }
          if (kind === "rot18") {
            if (/[0-9]/.test(ch)) return String.fromCharCode(48 + mod((code - 48) - (i % 10), 10));
            if (/[A-Za-z]/.test(ch)) {
              var base2 = ch === ch.toLowerCase() ? 97 : 65;
              return String.fromCharCode(base2 + mod((code - base2) - i, 26));
            }
          }
          return ch;
        }).join("");
        out.push({ score: score(p), label: "shift=" + i, text: p });
      }
      out.sort(function (x, y) { return y.score - x.score; });
      return out.slice(0, 10).map(function (c) { return c.label + " | " + c.text; });
    }
    function crackRail(text) {
      var out = [];
      for (var r = 2; r <= Math.min(12, Math.max(2, text.length - 1)); r++) { var p = rail(text, r, true); out.push({ score: score(p), label: "rails=" + r, text: p }); }
      out.sort(function (x, y) { return y.score - x.score; });
      return out.slice(0, 10).map(function (c) { return c.label + " | " + c.text; });
    }
    function crackVigenere(text, opts) {
      var mode = opts.vmode || "score", maxLen = Math.max(1, Math.min(12, Number(opts.maxLen || 12) | 0)), cand = [];
      var keyList = (String(opts.wordlist || "").split(/[\s,;]+/).filter(function (w) { return w && w.length <= 12; }));
      if (keyList.length === 0) keyList = WORDS.filter(function (w) { return w.length <= 12; });
      if (mode === "wordlist") {
        keyList.forEach(function (k) { var p = vigenere(text, k, true, opts); if (p) cand.push({ score: score(p), label: "key=" + k, text: p }); });
      } else {
        for (var len = 1; len <= maxLen; len++) {
          var key = "";
          for (var pos = 0; pos < len; pos++) {
            var col = "";
            for (var i = pos; i < text.length; i += len) if (/[A-Za-z]/.test(text[i])) col += text[i];
            var best = { score: -1e9, key: 0 };
            for (var sh = 0; sh < 26; sh++) {
              var dec = arr(col).map(function (ch) { var base = ch === ch.toLowerCase() ? 97 : 65; return String.fromCharCode(base + mod((ch.charCodeAt(0) - base) - sh, 26)); }).join("");
              var sc = score(dec);
              if (sc > best.score) best = { score: sc, key: sh };
            }
            key += U[best.key];
          }
          var p2 = vigenere(text, key, true, opts);
          if (p2) cand.push({ score: score(p2), label: "len=" + len + " key=" + key, text: p2 });
        }
      }
      cand.sort(function (x, y) { return y.score - x.score; });
      return cand.slice(0, 10).map(function (c) { return c.label + " | " + c.text; });
    }
    function crackSub(text, opts) {
      var base = alphaByMode(opts.alphaMode || "upper"), limit = Math.max(1, Number(opts.steps || 500) | 0), best = [];
      var freq = "ETAOINSHRDLCUMWFGYPBVKJXQZ";
      var freqLetters = arr(text.toUpperCase().replace(/[^A-Z]/g, "")).sort(function (a, b) { return (text.match(new RegExp(a, "gi")) || []).length < (text.match(new RegExp(b, "gi")) || []).length ? 1 : -1; }).join("");
      var seed = keywordAlphabet(freqLetters + freq, base);
      function mutate(alpha) {
        var a = arr(alpha), i = Math.floor(Math.random() * a.length), j = Math.floor(Math.random() * a.length);
        var t = a[i]; a[i] = a[j]; a[j] = t; return a.join("");
      }
      for (var r = 0; r < 6; r++) {
        var cipherAlpha = mutate(seed);
        var plain = mapAlpha(text, cipherAlpha, base, true), sc = score(plain);
        for (var i = 0; i < limit; i++) {
          var next = mutate(cipherAlpha), out = mapAlpha(text, next, base, true), nsc = score(out);
          if (nsc > sc) { cipherAlpha = next; plain = out; sc = nsc; }
        }
        best.push({ score: sc, label: "solver " + (r + 1), text: plain });
      }
      best.sort(function (x, y) { return y.score - x.score; });
      return best.slice(0, 10).map(function (c) { return c.label + " | " + c.text; });
    }
    function crackStructured(text, opts) {
      var kind = opts.cipher, out = [];
      if (kind === "base64") {
        ["standard", "url"].forEach(function (v) { try { var p = fromBytes(unb64(text, v === "url")); out.push({ score: score(p), label: v, text: p }); } catch (e) {} });
      } else if (kind === "base32") {
        ["standard", "hex"].forEach(function (v) { try { var p = fromBytes(base32ToBytes(text, v === "hex")); out.push({ score: score(p), label: v, text: p }); } catch (e) {} });
      } else if (kind === "ascii85") {
        ["adobe", "bare"].forEach(function (v) { try { var p = fromBytes(ascii85Decode(text)); out.push({ score: score(p), label: v, text: p }); } catch (e) {} });
      } else if (kind === "unicode") {
        var p2 = unicode(text, true, "uplus"); if (p2) out.push({ score: score(p2), label: "U+", text: p2 });
      } else if (kind === "integer") {
        [2, 8, 10, 16].forEach(function (r) { [8, 16, 32].forEach(function (w) { [false, true].forEach(function (s) { try { var p = integer(text, true, r, w, s); if (p) out.push({ score: score(p), label: r + "/" + w + (s ? "/signed" : ""), text: p }); } catch (e) {} }); }); });
      } else if (kind === "morse") {
        var p3 = morse(text, true); if (p3) out.push({ score: score(p3), label: "morse", text: p3 });
      } else if (kind === "spelling") {
        var p4 = spelling(text, true); if (p4) out.push({ score: score(p4), label: "spelling", text: p4 });
      } else if (kind === "bacon") {
        ["standard", "extended"].forEach(function (v) { try { var p = bacon(text, v, true); out.push({ score: score(p), label: v, text: p }); } catch (e) {} });
      } else if (kind === "rot") {
        out = crackRot(text, opts.variant || "rot13").map(function (l) { return { score: 0, label: "", text: l }; });
      } else if (kind === "affine") {
        return crackAffine(text);
      } else if (kind === "railfence") {
        return crackRail(text);
      } else if (kind === "vigenere") {
        return crackVigenere(text, opts);
      } else if (kind === "substitution" || kind === "alpha_sub") {
        return crackSub(text, opts);
      }
      out.sort(function (x, y) { return y.score - x.score; });
      return out.slice(0, 10).map(function (c) { return c.label + (c.label ? " | " : "") + c.text; });
    }
    Object.keys(MORSE).forEach(function (k) { MORSE_REV[MORSE[k]] = k; });
    Object.keys(NATO).forEach(function (k) { NATO_REV[String(NATO[k]).toLowerCase()] = k; });
    arr(U).forEach(function (c, i) { BACON_REV26[i] = c; if (i < BACON24.length) BACON_REV24[i] = BACON24[i]; });
    return {
      run: function (cipher, mode, text, opts) {
        opts = opts || {};
        if (mode === "bruteforce") return crackStructured(text, opts);
        switch (cipher) {
          case "morse": return morse(text, mode === "decrypt");
          case "spelling": return spelling(text, mode === "decrypt");
          case "affine": return affine(text, opts, mode === "decrypt");
          case "rot": return rot(text, opts.variant || "rot13", mode === "decrypt", !!opts.preserveCase);
          case "vigenere": return vigenere(text, opts.key || "", mode === "decrypt", opts);
          case "bacon": return bacon(text, opts.variant || "standard", mode === "decrypt");
          case "alpha_sub": {
            var base = alphaByMode(opts.alphaMode || "upper");
            var cipher = opts.variant === "manual" ? (opts.manualAlphabet || base) : keywordAlphabet(opts.keyword || "", base);
            return mode === "decrypt" ? mapAlpha(text, cipher, base, !!opts.preserveCase) : mapAlpha(text, base, cipher, !!opts.preserveCase);
          }
          case "substitution": {
            var plain = U;
            var subst = opts.manualAlphabet || U;
            return mode === "decrypt" ? mapAlpha(text, subst, plain, !!opts.preserveCase) : mapAlpha(text, plain, subst, !!opts.preserveCase);
          }
          case "railfence": return rail(text, opts.rails || 2, mode === "decrypt");
          case "base32": return mode === "decrypt" ? fromBytes(base32ToBytes(text, (opts.variant || "standard") === "hex")) : bytesToBase32(toBytes(text), (opts.variant || "standard") === "hex", opts.padding !== false);
          case "base64": return mode === "decrypt" ? fromBytes(unb64(text, (opts.variant || "standard") === "url")) : b64(toBytes(text), (opts.variant || "standard") === "url");
          case "ascii85": return mode === "decrypt" ? fromBytes(ascii85Decode(text)) : ascii85Encode(toBytes(text), (opts.variant || "adobe") === "adobe", opts.compressZeros !== false);
          case "unicode": return unicode(text, mode === "decrypt", opts.variant || "uplus");
          case "integer": return integer(text, mode === "decrypt", opts.radix || 16, opts.width || 8, !!opts.signed);
          default: return "";
        }
      }
    };
  })();

  function renderCryptoApp(body, win, isCrack) {
    body.innerHTML =
      '<div class="pad" style="display:flex;flex-direction:column;gap:8px;height:100%">' +
        '<div style="display:flex;gap:8px;flex-wrap:wrap">' +
          '<select class="input cmode" style="min-width:120px"><option value="encrypt">Encrypt</option><option value="decrypt">Decrypt</option><option value="bruteforce">Bruteforce</option></select>' +
          '<select class="input csrc" style="min-width:110px"><option value="text">Text</option><option value="files">Files</option></select>' +
          '<select class="input calgo" style="min-width:160px"></select>' +
          '<select class="input cvar" style="min-width:160px"></select>' +
        '</div>' +
        '<div style="display:grid;grid-template-columns:1.35fr .95fr;gap:8px;min-height:0;flex:1">' +
          '<div style="display:flex;flex-direction:column;gap:8px;min-height:0">' +
            '<textarea class="input ctext" rows="7" placeholder="Text input"></textarea>' +
            '<div class="cfiles" style="display:none;border:1px solid var(--line);border-radius:6px;padding:8px;min-height:84px;overflow:auto"></div>' +
            '<textarea class="input cout" rows="8" readonly placeholder="Result"></textarea>' +
            '<div style="display:flex;gap:8px;flex-wrap:wrap">' +
              '<button class="btn accent crun">Run</button>' +
              '<button class="btn csave">Save Output</button>' +
              '<button class="btn ccopy">Copy Output</button>' +
              '<button class="btn cclear">Clear</button>' +
              '<button class="btn cadd" style="display:none">Add File</button>' +
              '<button class="btn crem" style="display:none">Remove Selected</button>' +
              '<button class="btn cclrfiles" style="display:none">Clear Files</button>' +
            '</div>' +
          '</div>' +
          '<div style="display:flex;flex-direction:column;gap:8px;min-height:0;overflow:auto">' +
            '<input class="input ckey" placeholder="Key / password / keyword">' +
            '<input class="input ckw" placeholder="Wordlist or solver seed">' +
            '<input class="input calpha" placeholder="Manual alphabet / substitution alphabet">' +
            '<input class="input craw" placeholder="Affine A/B or rail count">' +
            '<div style="display:flex;gap:8px">' +
              '<input class="input cmax" type="number" min="1" max="12" value="12" style="flex:1" placeholder="Max key length">' +
              '<input class="input cstep" type="number" min="1" value="400" style="flex:1" placeholder="Solver steps">' +
            '</div>' +
            '<div style="display:flex;gap:8px">' +
              '<select class="input cradix" style="flex:1"><option value="2">Binary</option><option value="8">Octal</option><option value="10">Decimal</option><option value="16" selected>Hex</option></select>' +
              '<select class="input cwidth" style="flex:1"><option value="8">8-bit</option><option value="16">16-bit</option><option value="32">32-bit</option></select>' +
            '</div>' +
            '<div style="display:flex;gap:8px;flex-wrap:wrap">' +
              '<select class="input calphaMode"><option value="upper">Alphabet: Upper</option><option value="lower">Alphabet: Lower</option></select>' +
              '<select class="input cpres"><option value="1">Preserve case</option><option value="0">Force upper</option></select>' +
              '<select class="input csigned"><option value="0">Unsigned</option><option value="1">Signed</option></select>' +
              '<select class="input cpad"><option value="1">Pad output</option><option value="0">No pad</option></select>' +
              '<select class="input ccomp"><option value="1">Ascii85 zero-compress</option><option value="0">Ascii85 raw</option></select>' +
            '</div>' +
            '<textarea class="input cwords" rows="6" placeholder="Wordlist (one key per line)"></textarea>' +
          '</div>' +
        '</div>' +
      '</div>';

    var mode = body.querySelector(".cmode");
    var src = body.querySelector(".csrc");
    var algo = body.querySelector(".calgo");
    var variant = body.querySelector(".cvar");
    var txt = body.querySelector(".ctext");
    var out = body.querySelector(".cout");
    var key = body.querySelector(".ckey");
    var word = body.querySelector(".ckw");
    var alpha = body.querySelector(".calpha");
    var raw = body.querySelector(".craw");
    var max = body.querySelector(".cmax");
    var steps = body.querySelector(".cstep");
    var radix = body.querySelector(".cradix");
    var width = body.querySelector(".cwidth");
    var preserve = body.querySelector(".cpres");
    var alphaMode = body.querySelector(".calphaMode");
    var signed = body.querySelector(".csigned");
    var padding = body.querySelector(".cpad");
    var compress = body.querySelector(".ccomp");
    var words = body.querySelector(".cwords");
    var filesWrap = body.querySelector(".cfiles");
    var addBtn = body.querySelector(".cadd");
    var remBtn = body.querySelector(".crem");
    var clrFilesBtn = body.querySelector(".cclrfiles");
    var files = [], selected = -1;

    var algos = [
      ["morse", "Morse Code"], ["spelling", "Spelling Alphabet"], ["affine", "Affine"], ["rot", "ROT"], ["vigenere", "Vigenere"],
      ["bacon", "Bacon"], ["alpha_sub", "Alphabetical Substitution"], ["substitution", "Substitution"], ["railfence", "Railfence"],
      ["base32", "Base32"], ["base64", "Base64"], ["ascii85", "Ascii85"], ["unicode", "Unicode Notation"], ["integer", "Integer"]
    ];
    var variants = {
      morse: [["standard", "Standard"]],
      spelling: [["nato", "NATO/ICAO"]],
      affine: [["keyword", "Keyword"], ["manual", "Manual"]],
      rot: [["rot5", "ROT5"], ["rot13", "ROT13"], ["rot18", "ROT18"], ["rot47", "ROT47"]],
      vigenere: [["manual", "Manual"], ["wordlist", "Wordlist"], ["score", "Score"]],
      bacon: [["standard", "Standard"], ["extended", "Extended"]],
      alpha_sub: [["keyword", "Keyword"], ["manual", "Manual"]],
      substitution: [["manual", "Manual"], ["solver", "Solver"]],
      railfence: [["zigzag", "Zigzag"]],
      base32: [["standard", "Standard"], ["hex", "Base32Hex"]],
      base64: [["standard", "Standard"], ["url", "URL-safe"]],
      ascii85: [["adobe", "Adobe"], ["bare", "Bare"]],
      unicode: [["uplus", "U+ notation"], ["escape", "\\u escape"]],
      integer: [["bin", "Binary"], ["oct", "Octal"], ["dec", "Decimal"], ["hex", "Hexadecimal"]]
    };
    algos.forEach(function (a) { var o = document.createElement("option"); o.value = a[0]; o.textContent = a[1]; algo.appendChild(o); });
    function fillVariants() {
      var list = variants[algo.value] || [["standard", "Standard"]];
      variant.innerHTML = "";
      list.forEach(function (v) { var o = document.createElement("option"); o.value = v[0]; o.textContent = v[1]; variant.appendChild(o); });
    }
    function updateMode() {
      var crack = mode.value === "bruteforce";
      if (isCrack) mode.value = "bruteforce";
      body.querySelector(".crun").textContent = mode.value === "bruteforce" ? "Analyse" : "Run";
      addBtn.style.display = src.value === "files" ? "" : "none";
      remBtn.style.display = src.value === "files" ? "" : "none";
      clrFilesBtn.style.display = src.value === "files" ? "" : "none";
      filesWrap.style.display = src.value === "files" ? "" : "none";
      txt.style.display = src.value === "files" ? "none" : "";
      if (crack || isCrack) words.style.display = "block";
      else words.style.display = "block";
    }
    fillVariants();
    mode.value = isCrack ? "bruteforce" : "encrypt";
    body.querySelector(".crun").textContent = isCrack ? "Analyse" : "Run";
    mode.addEventListener("change", updateMode);
    algo.addEventListener("change", fillVariants);
    src.addEventListener("change", updateMode);
    updateMode();

    function renderFiles() {
      if (!files.length) { filesWrap.innerHTML = '<div class="muted">No files selected.</div>'; return; }
      filesWrap.innerHTML = files.map(function (f, i) {
        return '<div data-idx="' + i + '" style="padding:4px 6px;border-radius:4px;margin-bottom:4px;cursor:pointer;background:' + (i === selected ? "rgba(255,255,255,0.08)" : "transparent") + '">' + esc(f.name) + "</div>";
      }).join("");
      Array.prototype.slice.call(filesWrap.children).forEach(function (n) {
        n.addEventListener("click", function () { selected = Number(n.getAttribute("data-idx")); renderFiles(); });
      });
    }
    function addFile() {
      if (typeof window.AE3_pickFile !== "function") return;
      AE3_pickFile("open", { title: "Select file", start: (window.AE3_HOME || "/home") }).then(function (p) {
        if (!p) return;
        files.push({ path: p, name: p.split("/").pop() });
        selected = files.length - 1;
        renderFiles();
      });
    }
    function clearFiles() { files = []; selected = -1; renderFiles(); }
    function readFile(path) {
      return A3.request("fs_read", { path: path }).then(function (res) {
        if (res && res.locked) {
          return Modal.prompt("This file is password protected. Enter password:", "").then(function (pass) {
            if (pass == null) return null;
            return A3.request("fs_unlock", { path: path, pass: pass }).then(function (r2) { return (r2 && r2.error && r2.error !== "") ? null : (r2.content || ""); });
          });
        }
        return (res && res.error && res.error !== "") ? null : (res.content || "");
      });
    }
    function getInputs() {
      if (src.value !== "files") return Promise.resolve([{ name: "input", text: txt.value || "" }]);
      if (!files.length) return Promise.resolve([]);
      return Promise.all(files.map(function (f) { return readFile(f.path).then(function (t) { return { name: f.name, text: t == null ? "" : t }; }); }));
    }
    function opts() {
      var a = raw.value.trim().split(/[\/,\s]+/);
      return {
        variant: variant.value,
        key: key.value,
        keyword: word.value,
        manualAlphabet: alpha.value,
        a: a[0] || 1,
        b: a[1] || 0,
        rails: a[0] || 2,
        alphaMode: alphaMode.value,
        preserveCase: preserve.value === "1",
        wordlist: words.value,
        maxLen: max.value,
        steps: steps.value,
        radix: Number(radix.value),
        width: Number(width.value),
        signed: signed.value === "1",
        padding: padding.value === "1",
        compressZeros: compress.value === "1",
        cipher: algo.value,
        vmode: variant.value
      };
    }
    function setOutput(value) { out.value = Array.isArray(value) ? value.join("\n") : String(value || ""); }
    function runOne(text) {
      return CryptoLab.run(algo.value, mode.value, text, opts());
    }
    function runAll() {
      getInputs().then(function (list) {
        if (!list || !list.length) { setOutput("No input."); return; }
        if (mode.value === "bruteforce") {
          var lines = [];
          list.forEach(function (item) {
            var res = CryptoLab.run(algo.value, "bruteforce", item.text, opts());
            lines.push("[" + item.name + "]");
            lines = lines.concat(res && res.length ? res : ["No candidates."]);
            lines.push("");
          });
          setOutput(lines.join("\n"));
        } else {
          var outLines = [];
          list.forEach(function (item) {
            var r = runOne(item.text);
            if (list.length > 1) outLines.push("[" + item.name + "]");
            outLines.push(String(r || ""));
            if (list.length > 1) outLines.push("");
          });
          setOutput(outLines.join("\n"));
        }
      });
    }
    function saveOutput() {
      if (typeof window.AE3_pickFile !== "function") return;
      AE3_pickFile("save", { title: "Save output", start: (window.AE3_HOME || "/home"), filename: (algo.value + ".txt") }).then(function (p) {
        if (!p) return;
        A3.request("fs_save", { path: p, content: out.value || "" }).then(function (r) {
          if (r && r.error && r.error !== "") Modal.alert("Save", "Permission denied.");
        });
      });
    }
    addBtn.addEventListener("click", addFile);
    remBtn.addEventListener("click", function () { if (selected >= 0) { files.splice(selected, 1); selected = Math.min(selected, files.length - 1); renderFiles(); } });
    clrFilesBtn.addEventListener("click", clearFiles);
    body.querySelector(".crun").addEventListener("click", runAll);
    body.querySelector(".csave").addEventListener("click", saveOutput);
    body.querySelector(".ccopy").addEventListener("click", function () { navigator.clipboard && navigator.clipboard.writeText(out.value || ""); });
    body.querySelector(".cclear").addEventListener("click", function () { txt.value = ""; out.value = ""; clearFiles(); });
    win.app.onClose = function () {};
    renderFiles();
  }

  Apps.register({
    id: "crypto", title: "Crypto", glyph: Icons.crypto, width: 940, height: 620, showInDock: false,
    render: function (body, win) { renderCryptoApp(body, win, false); }
  });

  Apps.register({
    id: "crack", title: "Crack", glyph: Icons.crack, width: 940, height: 620, showInDock: false,
    render: function (body, win) { renderCryptoApp(body, win, true); }
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
        if (snake.some(function (s) { return s.x === head.x && s.y === head.y; })) { over = true; stat.textContent = "Game over! Score: " + score; return; }
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
              // Jump to the Sent box so the just-sent copy is visible regardless of the active tab.
              if (!err || err === "") setTimeout(function () { setActiveTab("sent"); }, 400);
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
      // Event-driven refresh: the server pushes mail_notify to the laptop in use when a new mail
      // is delivered (incoming) or a sent copy is written (own send), so inbox/sent update live
      // without polling. Re-lists whichever box is currently open.
      A3.on("mail_notify", function () { list(); });
      list();
    }
  });

  // ---------------- Messenger ----------------
  Apps.register({
    id: "messenger", title: "Messenger", glyph: Icons.messenger, width: 880, height: 500,
    showInDock: true, singleton: true,
    render: function (body, win) {
      // FB-Messenger-style 3-pane layout: a left nav rail (Message Center / Handles plus a
      // "Reading as" identity selector), a chat list keyed by (own handle, peer), and a conversation
      // pane. Each conversation is bound to one sending identity, so multiple handles on the same
      // laptop keep separate boxes and a reply always goes out under the right handle.
      body.innerHTML =
        '<div style="display:flex;height:100%">' +
          '<div class="rail" style="width:150px;min-width:150px;border-right:1px solid var(--line);display:flex;flex-direction:column">' +
            '<div class="pad" style="font-weight:700;font-size:15px">Messenger</div>' +
            '<button class="btn nav-msgs" style="margin:2px 8px;text-align:left">Message Center</button>' +
            '<button class="btn nav-handles" style="margin:2px 8px;text-align:left">Handles</button>' +
            '<div style="flex:1"></div>' +
            '<div class="muted" style="padding:6px 12px 2px;font-size:11px">Reading as</div>' +
            '<button class="btn reading" style="margin:0 8px 10px;text-align:left">All handles</button>' +
          '</div>' +
          '<div class="center" style="width:34%;min-width:200px;border-right:1px solid var(--line);display:flex;flex-direction:column"></div>' +
          '<div class="convo" style="flex:1;display:flex;flex-direction:column;min-width:0"></div>' +
        '</div>';
      var centerEl = body.querySelector(".center");
      var convoEl = body.querySelector(".convo");
      var readingBtn = body.querySelector(".reading");
      var threads = [];      // [{self, peer, messages:[{dir,time,text}]}]
      var active = null;     // composite key of the active thread (see tkey)
      var handles = [];      // own handles on this laptop
      var readingAs = "*";   // "*" = every identity, otherwise a specific own handle to filter by
      var view = "chats";    // "chats" | "handles"
      var searchEl = null;   // (re)created with the chat-list view

      var SEP = String.fromCharCode(1);
      function tkey(self, peer) { return (self || "") + SEP + peer; }
      function findThread(k) { return threads.filter(function (x) { return tkey(x.self, x.peer) === k; })[0]; }
      // Legacy threads may carry an empty self; treat that as the laptop's first handle so they still
      // group under a concrete identity.
      function selfOf(t) { return t.self || handles[0] || ""; }
      // Stable colour per identity so each handle's chip is visually distinct.
      function colorFor(s) {
        var x = 0; s = String(s || "");
        for (var i = 0; i < s.length; i++) { x = (x * 31 + s.charCodeAt(i)) | 0; }
        return "hsl(" + (((x % 360) + 360) % 360) + ",50%,42%)";
      }
      function chip(self) {
        return '<span style="display:inline-block;font-size:10px;padding:1px 6px;border-radius:8px;color:#fff;white-space:nowrap;background:' +
          colorFor(self) + '">' + esc(String(self || "?").replace(/^@/, "")) + "</span>";
      }

      function loadHandles(cb) {
        A3.request("handle_list", {}).then(function (res) {
          handles = (res && res.handles) || [];
          if (cb) cb();
        }).catch(function () { handles = []; if (cb) cb(); });
      }

      // Threads visible for the current "Reading as" identity and search query.
      function visibleThreads() {
        var q = (searchEl && searchEl.value || "").toLowerCase();
        return threads.filter(function (t) {
          if (readingAs !== "*" && selfOf(t) !== readingAs) return false;
          if (!q) return true;
          if (t.peer.toLowerCase().indexOf(q) >= 0) return true;
          if (selfOf(t).toLowerCase().indexOf(q) >= 0) return true;
          return t.messages.some(function (m) { return (m.text || "").toLowerCase().indexOf(q) >= 0; });
        });
      }
      function renderReadingBtn() { readingBtn.textContent = readingAs === "*" ? "All handles" : readingAs; }

      function renderPeers() {
        var listEl = centerEl.querySelector(".peers");
        if (!listEl) return;
        listEl.innerHTML = "";
        var shown = visibleThreads();
        if (!shown.length) { listEl.innerHTML = '<li class="muted pad">No conversations</li>'; return; }
        shown.forEach(function (t) {
          var last = t.messages.length ? t.messages[t.messages.length - 1] : null;
          var li = h('<li style="flex-direction:column;align-items:stretch' + (tkey(t.self, t.peer) === active ? ';background:var(--surface-2)' : '') + '">' +
            '<div style="display:flex;align-items:center;gap:6px"><span style="flex:1">' + esc(t.peer) + "</span>" + chip(selfOf(t)) + "</div>" +
            '<span class="muted" style="font-size:12px">' + esc(last ? (last.dir === "o" ? "You: " : "") + last.text : "") + "</span></li>");
          li.addEventListener("click", function () { active = tkey(t.self, t.peer); renderThread(); renderPeers(); });
          listEl.appendChild(li);
        });
      }
      function renderThread() {
        if (view !== "chats") return;
        var t = findThread(active);
        if (!t || (readingAs !== "*" && selfOf(t) !== readingAs)) {
          convoEl.innerHTML = '<p class="muted pad">Select or start a conversation.</p>';
          return;
        }
        // Preserve any message the user is currently typing: an incoming message triggers a full
        // re-render of this pane, which would otherwise discard the unsent text and caret position.
        var prevInput = convoEl.querySelector(".ctext");
        var savedText = prevInput ? prevInput.value : null;
        var savedStart = prevInput ? prevInput.selectionStart : null;
        var savedEnd = prevInput ? prevInput.selectionEnd : null;
        convoEl.innerHTML =
          '<div class="toolbar" style="align-items:center"><span style="font-weight:600;flex:1">' + esc(t.peer) + "</span>" + chip(selfOf(t)) + "</div>" +
          '<div class="cmsgs" style="flex:1;overflow:auto;padding:12px;background:#262626"></div>' +
          '<div class="toolbar"><input class="input ctext" placeholder="Message" style="flex:1"><button class="btn accent csend">Send</button></div>';
        var msgs = convoEl.querySelector(".cmsgs");
        var q = (searchEl && searchEl.value || "").toLowerCase();
        t.messages.forEach(function (m) {
          if (q && (m.text || "").toLowerCase().indexOf(q) < 0) return;
          var out = m.dir === "o";
          msgs.appendChild(h('<div style="margin:6px 0;display:flex;' + (out ? "justify-content:flex-end" : "") + '">' +
            '<div style="max-width:75%;padding:6px 10px;border-radius:10px;background:' + (out ? "var(--accent);color:#fff" : "#3a3a3a") + '">' +
            esc(m.text) + '<div style="font-size:10px;opacity:.7;text-align:right">' + esc(m.time) + '</div></div></div>'));
        });
        msgs.scrollTop = msgs.scrollHeight;
        var ctext = convoEl.querySelector(".ctext");
        // Restore the in-progress message (and caret) that was present before this re-render.
        if (savedText !== null) {
          ctext.value = savedText;
          if (savedStart !== null) { try { ctext.setSelectionRange(savedStart, savedEnd); } catch (e) {} }
        }
        function doSend() { sendTo(t, ctext); }
        convoEl.querySelector(".csend").addEventListener("click", doSend);
        ctext.addEventListener("keydown", function (e) { if (e.key === "Enter") doSend(); });
      }
      // Sends under the conversation's bound identity (selfOf), so the recipient always sees which
      // handle the message came from.
      function sendTo(t, ctext) {
        if (ctext.value.trim() === "") return;
        A3.request("chat_send", { to: t.peer, from: selfOf(t), text: ctext.value }).then(function (r) {
          if (r.error && r.error !== "") { Modal.alert("Messenger", r.error === "unreachable" ? "Recipient unreachable." : ("Could not send: " + r.error)); return; }
          ctext.value = "";
          setTimeout(function () { A3.send("chat_pull", {}); }, 300);
        });
      }

      // ---- Chat-list view (Message Center) ----
      function renderChatList() {
        centerEl.innerHTML =
          '<div class="toolbar"><input class="input csearch" placeholder="Search handle / message" style="flex:1"><button class="btn accent newchat" title="New conversation">+</button></div>' +
          '<ul class="list peers" style="flex:1;overflow:auto"></ul>';
        searchEl = centerEl.querySelector(".csearch");
        searchEl.addEventListener("input", function () { renderPeers(); renderThread(); });
        centerEl.querySelector(".newchat").addEventListener("click", openNewChat);
        renderPeers();
      }

      // ---- Handles view (create / delete identities) ----
      function renderHandlesView() {
        centerEl.innerHTML =
          '<div class="pad" style="font-weight:600">Handles</div>' +
          '<div style="display:flex;gap:8px;padding:0 12px 8px"><input class="input newhandle" placeholder="@handle" style="flex:1"><button class="btn accent addhandle">Create</button></div>' +
          '<ul class="list handlelist" style="flex:1;overflow:auto"></ul>';
        var listEl = centerEl.querySelector(".handlelist");
        function draw() {
          listEl.innerHTML = "";
          if (!handles.length) { listEl.innerHTML = '<li class="muted pad">No handles</li>'; return; }
          handles.forEach(function (hnd) {
            var li = h('<li><span style="flex:1">' + esc(hnd) + '</span><button class="btn delhandle">Delete</button></li>');
            li.querySelector(".delhandle").addEventListener("click", function () {
              A3.request("handle_delete", { handle: hnd }).then(function () {
                if (readingAs === hnd) readingAs = "*";
                loadHandles(function () { draw(); renderReadingBtn(); });
              });
            });
            listEl.appendChild(li);
          });
        }
        centerEl.querySelector(".addhandle").addEventListener("click", function () {
          var v = centerEl.querySelector(".newhandle").value;
          A3.request("handle_create", { handle: v }).then(function (r) {
            if (r.error && r.error !== "") { Modal.alert("Handles", r.error === "taken" ? "Handle already exists." : "Invalid handle."); return; }
            centerEl.querySelector(".newhandle").value = "";
            loadHandles(draw);
          });
        });
        convoEl.innerHTML = '<p class="muted pad">Create or remove the identities used to send and receive messages on this laptop. Select <b>Message Center</b> to chat.</p>';
        draw();
      }

      function setView(v) {
        view = v;
        body.querySelector(".nav-msgs").className = "btn nav-msgs" + (v === "chats" ? " accent" : "");
        body.querySelector(".nav-handles").className = "btn nav-handles" + (v === "handles" ? " accent" : "");
        if (v === "chats") { renderChatList(); renderThread(); } else { renderHandlesView(); }
      }

      // ---- New conversation dialog (with a From-handle picker) ----
      function defaultSelf() { return (readingAs !== "*" && readingAs) ? readingAs : (handles[0] || ""); }
      function startWith(self, handle) {
        if (!handle) return;
        if (handle.charAt(0) !== "@") handle = "@" + handle;
        if (!self) { Modal.alert("Messenger", "Create a handle first (Handles)."); return; }
        if (!findThread(tkey(self, handle))) threads.push({ self: self, peer: handle, messages: [] });
        // Make sure the new conversation is visible under the current filter.
        if (readingAs !== "*" && readingAs !== self) { readingAs = self; renderReadingBtn(); }
        active = tkey(self, handle); renderPeers(); renderThread();
      }
      function showNewChat(knownHandles) {
        var def = defaultSelf();
        var fromOpts = handles.map(function (hn) { return '<option value="' + esc(hn) + '"' + (hn === def ? " selected" : "") + ">" + esc(hn) + "</option>"; }).join("");
        var ov = h('<div class="pk-overlay"><div class="pk-dialog" style="width:380px;height:auto;min-height:0">' +
          '<div class="pk-title">Start conversation</div>' +
          '<div class="pad" style="display:flex;flex-direction:column;gap:8px">' +
            '<label class="muted" style="font-size:12px">From (your handle)</label>' +
            '<select class="input nfrom">' + (fromOpts || '<option value="">(no handles)</option>') + "</select>" +
            '<label class="muted" style="font-size:12px">To</label>' +
            '<ul class="list hpick" style="max-height:180px;overflow:auto"></ul>' +
            '<div style="display:flex;gap:8px"><input class="input hnew" placeholder="or type a handle" style="flex:1"><button class="btn accent hgo">Start</button></div>' +
            '<div style="text-align:right"><button class="btn hclose">Cancel</button></div>' +
          "</div></div></div>");
        document.body.appendChild(ov);
        var pickEl = ov.querySelector(".hpick");
        function go(handle) { startWith(ov.querySelector(".nfrom").value || def, handle); ov.remove(); }
        if (!knownHandles || !knownHandles.length) {
          pickEl.innerHTML = '<li class="muted pad">No known handles</li>';
        } else {
          knownHandles.forEach(function (hnd) {
            var display = hnd.display || hnd.handle || hnd;
            var handle = hnd.handle || hnd;
            var li = h('<li><span style="flex:1">' + esc(display) + '</span><button class="btn pick">Chat</button></li>');
            li.querySelector(".pick").addEventListener("click", function () { go(handle); });
            pickEl.appendChild(li);
          });
        }
        ov.querySelector(".hgo").addEventListener("click", function () { go(ov.querySelector(".hnew").value.trim()); });
        ov.querySelector(".hnew").addEventListener("keydown", function (e) { if (e.key === "Enter") go(ov.querySelector(".hnew").value.trim()); });
        ov.querySelector(".hclose").addEventListener("click", function () { ov.remove(); });
      }
      function openNewChat() {
        A3.request("handles_all", {}).then(function (res) { showNewChat((res && res.handles) || []); }).catch(function () { showNewChat(null); });
      }

      // ---- "Reading as" identity selector ----
      function openReading() {
        var ov = h('<div class="pk-overlay"><div class="pk-dialog" style="width:260px;height:auto;min-height:0">' +
          '<div class="pk-title">Reading as</div><div class="pad"><ul class="list rlist"></ul></div></div></div>');
        document.body.appendChild(ov);
        var rl = ov.querySelector(".rlist");
        function pick(v) {
          readingAs = v; renderReadingBtn();
          var t = findThread(active);
          if (t && readingAs !== "*" && selfOf(t) !== readingAs) active = null;
          if (view === "chats") { renderPeers(); renderThread(); }
          ov.remove();
        }
        var opts = [["*", "All handles"]].concat(handles.map(function (hn) { return [hn, hn]; }));
        opts.forEach(function (o) {
          var li = h('<li' + (readingAs === o[0] ? ' style="background:var(--surface-2)"' : "") + '><span style="flex:1">' + esc(o[1]) + (readingAs === o[0] ? " &#10003;" : "") + "</span></li>");
          li.addEventListener("click", function () { pick(o[0]); });
          rl.appendChild(li);
        });
      }
      readingBtn.addEventListener("click", openReading);
      body.querySelector(".nav-msgs").addEventListener("click", function () { setView("chats"); });
      body.querySelector(".nav-handles").addEventListener("click", function () { setView("handles"); });

      A3.on("chat_data", function (d) {
        var incoming = (d && d.threads) || [];
        // Preserve an active pending thread the server doesn't know about yet (new conversation,
        // no messages sent — server won't return it until first message is exchanged).
        var pending = active && !incoming.some(function (t) { return tkey(t.self, t.peer) === active; })
          ? threads.find(function (t) { return tkey(t.self, t.peer) === active; })
          : null;
        threads = incoming;
        if (pending) threads.push(pending);
        if (!active) { var vis = visibleThreads(); if (vis.length) active = tkey(vis[0].self, vis[0].peer); }
        if (view === "chats") { renderPeers(); renderThread(); }
      });
      A3.on("msg_notify", function (d) {
        if (window.AE3_toast) window.AE3_toast("New message from " + ((d && d.peer) || "unknown"), "ok");
        A3.send("chat_pull", {});
      });

      // Fully event-driven: the initial pull seeds the conversation list, and msg_notify (pushed by
      // the server to the recipient) plus the post-send pull (sender's own echo) keep it current.
      // No interval polling, so an open Messenger generates no idle network traffic.
      loadHandles(function () { renderReadingBtn(); setView("chats"); A3.send("chat_pull", {}); });
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
      A3.on("vol_error", function (d) {
        if (window.AE3_toast) window.AE3_toast("Mount failed: " + ((d && d.message) || "unknown error"), "error");
        loadVols();
      });
      openIn("/");
      loadVols();
    }
  });

  // ---------------- Calculator ----------------
  Apps.register({
    id: "calculator", title: "Calculator", glyph: (Icons.calculator || Icons.about), width: 280, height: 380,
    showInDock: true, singleton: true,
    render: function (body) {
      var keys = ["C","(",")","/","7","8","9","*","4","5","6","-","1","2","3","+","0",".","=","<"];
      body.innerHTML =
        '<div class="pad" style="display:flex;flex-direction:column;gap:8px;height:100%">' +
          '<input class="input cdisp" readonly style="text-align:right;font-size:20px;height:40px" value="0">' +
          '<div class="ckeys" style="flex:1;display:grid;grid-template-columns:repeat(4,1fr);gap:6px"></div>' +
        '</div>';
      var disp = body.querySelector(".cdisp");
      var grid = body.querySelector(".ckeys");
      var expr = "";
      var justEvaluated = false; // true right after "=", so the next digit starts a new calculation
      function setDisp() { disp.value = expr === "" ? "0" : expr; }
      function press(k) {
        if (k === "") return;
        if (k === "C") { expr = ""; justEvaluated = false; setDisp(); return; }
        if (k === "<-") { expr = expr.slice(0, -1); justEvaluated = false; setDisp(); return; }
        if (k === "=") {
          // Safe arithmetic only: digits, operators, parens, dot, spaces.
          if (!/^[0-9+\-*/().\s]+$/.test(expr)) { disp.value = "Error"; expr = ""; justEvaluated = false; return; }
          try {
            // eslint-disable-next-line no-new-func
            var r = Function('"use strict";return (' + expr + ")")();
            expr = (r == null || !isFinite(r)) ? "" : String(r);
          } catch (e) { disp.value = "Error"; expr = ""; justEvaluated = false; return; }
          justEvaluated = true; setDisp(); return;
        }
        // After a result, a number/decimal/open-paren begins a fresh expression while an operator
        // continues the calculation from the displayed result.
        if (justEvaluated) {
          if (/[0-9.(]/.test(k)) expr = "";
          justEvaluated = false;
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
          '<div class="phist"></div>' +
          '<pre class="pout" style="min-height:76px;white-space:pre-wrap;background:#1e1e1e;padding:10px;border-radius:6px;margin:0;font-family:monospace;font-size:12px"></pre>' +
        '</div>';
      var input = body.querySelector(".pto");
      var out = body.querySelector(".pout");
      var histEl = body.querySelector(".phist");
      var hist = [];
      function drawHist() {
        histEl.innerHTML = "";
        if (!hist.length) return;
        var wrap = h('<div><div class="muted" style="font-size:12px;display:flex;align-items:center">Recent<button class="btn phclear" style="margin-left:auto;padding:0 6px">Clear</button></div><ul class="list precent" style="max-height:96px;overflow:auto"></ul></div>');
        var ul = wrap.querySelector(".precent");
        hist.forEach(function (e) {
          var li = h('<li style="cursor:pointer"><span style="flex:1">' + esc(e.ip) + '</span><span class="muted" style="font-size:11px">' + esc(e.host || "") + '</span></li>');
          li.addEventListener("click", function () { input.value = e.ip; });
          ul.appendChild(li);
        });
        wrap.querySelector(".phclear").addEventListener("click", function () { A3.request("hist_clear", { kind: "ping" }).then(function () { hist = []; drawHist(); }); });
        histEl.appendChild(wrap);
      }
      function loadHist() { A3.request("hist_get", {}).then(function (r) { hist = (r && r.ping) || []; drawHist(); }).catch(function () {}); }
      // Offer to remember a host the first time it is pinged successfully; a click on a saved row
      // refills the input.
      function maybeSave(ip, host) {
        if (hist.some(function (e) { return e.key === ip; })) return;
        Modal.confirm("Ping", "Save " + ip + " to history?").then(function (ok) {
          if (!ok) return;
          A3.request("hist_add", { kind: "ping", entry: { key: ip, ip: ip, host: host } }).then(function () { loadHist(); });
        });
      }
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
          maybeSave(ip, r.host || "remote");
        }).catch(function () { out.textContent = "Ping timed out."; });
      }
      body.querySelector(".pgo").addEventListener("click", run);
      input.addEventListener("keydown", function (e) { if (e.key === "Enter") run(); });
      loadHist();
    }
  });

  // ---------------- SSH ----------------
  // Connect to another SSH-enabled device on the network, then browse/copy files between the local
  // laptop (left pane) and the remote device (right pane).
  Apps.register({
    id: "ssh", title: "SSH", glyph: (Icons.terminal || Icons.network), width: 779, height: 578,
    showInDock: true, singleton: true,
    render: function (body, win) {
      var conn = null; // { to, user, pass }
      var ipPrefix = { value: "192.168.0." };
      seedIpPrefix(body, ".sto", ipPrefix);
      var sshHist = [];
      function drawSshHist() {
        var histEl = body.querySelector(".shist");
        if (!histEl) return;
        histEl.innerHTML = "";
        if (!sshHist.length) return;
        var wrap = h('<div style="margin-top:6px"><div class="muted" style="font-size:12px;display:flex;align-items:center">Recent<button class="btn shclear" style="margin-left:auto;padding:0 6px">Clear</button></div><ul class="list srecent" style="max-height:120px;overflow:auto"></ul></div>');
        var ul = wrap.querySelector(".srecent");
        sshHist.forEach(function (e) {
          var cred = e.savedPass ? " &middot; saved" : "";
          var li = h('<li style="cursor:pointer"><span style="flex:1">' + esc(e.user) + "@" + esc(e.ip) + '</span><span class="muted" style="font-size:11px">' + esc(e.host || "") + cred + "</span></li>");
          li.addEventListener("click", function () {
            var sto = body.querySelector(".sto"), su = body.querySelector(".suser"), sp = body.querySelector(".spass");
            if (sto) sto.value = e.ip;
            if (su) su.value = e.user;
            if (sp) sp.value = e.pass || "";
          });
          ul.appendChild(li);
        });
        wrap.querySelector(".shclear").addEventListener("click", function () { A3.request("hist_clear", { kind: "ssh" }).then(function () { sshHist = []; drawSshHist(); }); });
        histEl.appendChild(wrap);
      }
      function loadSshHist() { A3.request("hist_get", {}).then(function (r) { sshHist = (r && r.ssh) || []; drawSshHist(); }).catch(function () {}); }
      // First successful connect to a host/user offers to remember it, then (optionally) the password.
      // A saved row refills the connect form; a password is only stored when explicitly chosen.
      function maybeSaveSsh(c, host) {
        var key = c.to + "|" + c.user;
        if (sshHist.some(function (e) { return e.key === key; })) return;
        Modal.confirm("SSH", "Save " + c.user + "@" + c.to + " to history?").then(function (ok) {
          if (!ok) return;
          Modal.confirm("SSH", "Also save the password for this connection?").then(function (savePass) {
            A3.request("hist_add", { kind: "ssh", entry: { key: key, ip: c.to, user: c.user, host: host, savedPass: !!savePass, pass: savePass ? c.pass : "" } }).then(function () { loadSshHist(); });
          });
        });
      }
      function showConnect(msg) {
        body.innerHTML =
          '<div class="pad" style="display:flex;flex-direction:column;gap:8px;max-width:360px">' +
            '<h3>Connect via SSH</h3>' +
            '<input class="input sto" placeholder="Host IP" value="' + esc(ipPrefix.value) + '">' +
            '<input class="input suser" placeholder="Username">' +
            '<input class="input spass" type="password" placeholder="Password">' +
            '<div><button class="btn accent sgo">Connect</button> <span class="muted smsg">' + (msg || "") + '</span></div>' +
            '<div class="shist"></div>' +
          '</div>';
        body.querySelector(".sgo").addEventListener("click", function () {
          var c = { to: body.querySelector(".sto").value, user: body.querySelector(".suser").value, pass: body.querySelector(".spass").value };
          body.querySelector(".smsg").textContent = "Connecting";
          A3.request("ssh_connect", c).then(function (r) {
            if (!r || (r.error && r.error !== "")) {
              showConnect({ ssh_disabled: "SSH is disabled on that host.", auth_failed: "Wrong username or password.", no_route: "No route to host.", bad_addr: "Invalid address.", busy: "Remote host is busy.", offline: "Remote host is offline." }[r && r.error] || "Connection failed.");
              return;
            }
            maybeSaveSsh(c, r.host || c.to);
            conn = c; showSession(r.host || c.to);
          }).catch(function () { showConnect("Connection timed out. Try again."); });
        });
        drawSshHist();
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
                    // Save into the directory currently open in the local pane, not a fixed home path,
                    // so the file lands where the user is looking and appears on reload.
                    var localCwd = (localApi && localApi.getCwd) ? localApi.getCwd() : (window.AE3_HOME || "/home");
                    var dest = joinPath(localCwd, it.name);
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
      loadSshHist();
    }
  });

  // ---------------- About ----------------
  Apps.register({
    id: "about", title: "About OS", glyph: Icons.about, width: 420, height: 260, singleton: true,
    render: function (body) {
      body.innerHTML =
        '<div class="pad" style="text-align:center">' +
          '<div style="font-size:48px;color:var(--accent)">' + Icons.terminal + '</div><h2>armaOS</h2>' +
          '<p class="muted">Powered by SHITE Technologies</p>' +
          '<p class="muted">Made in Kingdom of Kekistan</p>' +
          '<p class="muted">at the behest of</p>' +
          '<p class="muted">Sir Doctor Professor Colonel Mr Matt The Fifth Senior</p>' +
          '<p class="muted">(Sir. Dr. Pf. Col. Mr. Matt V Sr.)</p>' +
          '<p class="muted">Professional Shitposter</p>' +
          '</div>';
    }
  });
})();
