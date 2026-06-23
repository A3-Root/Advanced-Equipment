/*
 * AE3 bridge - JS <-> SQF channel for the web desktop.
 *   JS -> SQF : A3.send(command, data)  -> alert(json) -> JSDialog -> AE3_desktop_fnc_jsRouter
 *   SQF -> JS : AE3_desktop_fnc_jsSend -> window.AE3_recv(command, payload) -> handlers here
 *
 * A3.request(command, data) returns a Promise resolved by the matching reply (correlated by
 * an auto _rid the router echoes back). A3.on(channel, cb) subscribes to pushed events.
 */
(function () {
  var handlers = {};   // channel -> [cb]
  var pending = {};    // rid -> {resolve, timer}
  var ridSeq = 1;

  // JS -> SQF transport. Arma raises the control's "JSDialog" event for A3API.SendAlert (and
  // SendConfirm) - NOT for the native window.alert(), which CEF shows/suppresses locally and never
  // delivers to SQF. Using window.alert here was why every A3.request timed out and the desktop
  // looked "logged in but dead". This matches the working os-master bridge (A3API.SendAlert).
  var hasA3 = (typeof A3API !== "undefined" && A3API && typeof A3API.SendAlert === "function");
  function rawSend(msg) {
    if (hasA3) { A3API.SendAlert(msg); return; }
    // Plain-browser preview (no A3API): nothing to talk to; log so it can be inspected.
    console.log("[A3 offline]", msg);
  }

  function emit(channel, payload) {
    (handlers[channel] || []).forEach(function (cb) {
      try { cb(payload); } catch (e) { console.error(e); }
    });
  }

  // Collapse "." and ".." segments out of a backslash path. A3API.RequestFile rejects any path
  // containing ".." ("only relative paths supported"), so links like portal -> "..\wiki\index.html"
  // must be flattened to "\z\ae3\...\wiki\index.html" before the request. Preserves a leading "\".
  function normalizePath(p) {
    var lead = (p.charAt(0) === "\\") ? "\\" : "";
    var out = [];
    p.split("\\").forEach(function (seg) {
      if (seg === "" || seg === ".") return;
      if (seg === "..") { if (out.length) out.pop(); return; }
      out.push(seg);
    });
    return lead + out.join("\\");
  }

  var A3 = {
    // Fire-and-forget command to SQF.
    send: function (command, data) {
      rawSend(JSON.stringify({ command: command, data: data === undefined ? null : data }));
    },

    // Command expecting a reply. Resolves when SQF pushes back the same command with _rid.
    request: function (command, data, timeoutMs) {
      var rid = "r" + (ridSeq++);
      var msg = JSON.stringify({ command: command, rid: rid, data: data === undefined ? null : data });
      return new Promise(function (resolve, reject) {
        pending[rid] = {
          resolve: resolve,
          timer: setTimeout(function () {
            delete pending[rid];
            reject(new Error("AE3 request timeout: " + command));
          }, timeoutMs || 8000)
        };
        rawSend(msg);
      });
    },

    on: function (channel, cb) {
      (handlers[channel] = handlers[channel] || []).push(cb);
    },

    // Load a UI asset (html/md/media/...) by path. CEF cannot resolve relative URLs from a PBO
    // file, so everything goes through A3API. Resolution order for a NON-absolute path:
    //   extraRoots (optional) -> this addon's PBO -> mission root.
    // Absolute paths (\z\ae3\..., \z\othermod\..., or any other loaded mod) are used as-is, so
    // other mods and mission-relative content both work.
    loadFile: function (rel, extraRoots) {
      rel = String(rel).replace(/\//g, "\\");
      if (typeof A3API === "undefined" || !A3API || !A3API.RequestFile) {
        // Plain-browser preview: fetch relatively.
        return fetch(rel.replace(/\\/g, "/")).then(function (r) { return r.text(); });
      }
      function requestOne(full) {
        full = normalizePath(full);
        return Promise.resolve(A3API.RequestFile(full)).then(function (t) {
          if (t == null || t === "") throw new Error("empty/missing: " + full);
          return t;
        });
      }
      if (rel.charAt(0) === "\\") return requestOne(rel); // absolute - this or any other mod
      var roots = (extraRoots || []).concat(window.AE3_WEB_ROOTS ||
        [window.AE3_WEB_ROOT || "\\z\\ae3\\addons\\desktop\\ui\\web\\", ""]);
      var i = 0;
      function next() {
        if (i >= roots.length) return Promise.reject(new Error("not found in any root: " + rel));
        return requestOne(roots[i++] + rel).catch(next);
      }
      return next();
    },

    // Load an image asset as a data URL for an <img>/CSS background. A3API.RequestTexture renders
    // the engine texture (paa/jpg/png, mission or mod) to a base64 PNG data URL, so arbitrary
    // images display inside the webview (above the OS surface) instead of a hidden native control.
    // Resolution order mirrors loadFile: absolute paths as-is, otherwise this addon's web root then
    // the mission root.
    loadTexture: function (rel, maxRes) {
      rel = String(rel).replace(/\//g, "\\");
      var res = maxRes || 2048;
      if (typeof A3API === "undefined" || !A3API || !A3API.RequestTexture) {
        return Promise.reject(new Error("no A3API.RequestTexture"));
      }
      function requestOne(full) {
        full = normalizePath(full);
        return Promise.resolve(A3API.RequestTexture(full, res)).then(function (t) {
          if (t == null || t === "") throw new Error("empty/missing: " + full);
          return t;
        });
      }
      if (rel.charAt(0) === "\\") return requestOne(rel); // absolute - this or any other mod
      var roots = (window.AE3_WEB_ROOTS ||
        [window.AE3_WEB_ROOT || "\\z\\ae3\\addons\\desktop\\ui\\web\\", ""]).concat([""]);
      var i = 0;
      function next() {
        if (i >= roots.length) return Promise.reject(new Error("not found in any root: " + rel));
        return requestOne(roots[i++] + rel).catch(next);
      }
      return next();
    },

    emit: emit
  };

  // Entry point called by AE3_desktop_fnc_jsSend.
  window.AE3_recv = function (command, payload) {
    if (payload && payload._rid && pending[payload._rid]) {
      var p = pending[payload._rid];
      clearTimeout(p.timer);
      delete pending[payload._rid];
      p.resolve(payload.data !== undefined ? payload.data : payload);
      return;
    }
    emit(command, payload);
  };

  window.A3 = A3;
})();
