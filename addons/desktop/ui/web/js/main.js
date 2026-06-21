/*
 * AE3 web desktop boot. Shows the login screen (per-user filesystem, issue #9), authenticates
 * against the AE3 user list via the SQF backend (A3.request "login"), then starts the desktop.
 * SQF can also push "boot" with session info to skip/seed login.
 */
(function () {
  var seededHost = null; // hostname pushed by SQF on "ready", applied once the desktop starts

  function startDesktop(session) {
    document.getElementById("login").classList.remove("show");
    Desktop.init();
    var host = (session && session.hostname) || seededHost;
    if (host) Desktop.setHostname(host);
    // Apply the per-laptop wallpaper (#15) once the desktop is up.
    A3.request("sysinfo", {}).then(function (s) { if (s && s.wallpaper) Desktop.setWallpaper(s.wallpaper); }).catch(function () {});
  }

  function showLogin() {
    var login = document.getElementById("login");
    login.classList.add("show");
    var av = login.querySelector(".avatar");
    if (av && window.Icons) av.innerHTML = Icons.user;
    var user = document.getElementById("loginUser");
    var pass = document.getElementById("loginPass");
    var err = document.getElementById("loginErr");
    err.textContent = "";

    function submit(isRetry) {
      err.textContent = "";
      // Longer timeout: in MP the SQF side may block on an authoritative userlist sync before it
      // can give a verdict (see AE3_desktop_fnc_jsRouter "login").
      A3.request("login", { user: user.value, pass: pass.value }, 15000).then(function (res) {
        if (res && res.ok) { startDesktop(res); return; }
        // The backend now resolves the sync race itself, so "retry" should be rare. Keep a single
        // silent retry purely as a safety net.
        if (res && res.retry && !isRetry) {
          err.textContent = res.message || "Syncing…";
          setTimeout(function () { submit(true); }, 700);
          return;
        }
        err.textContent = (res && res.message) || "Login failed"; pass.value = "";
      }).catch(function (e) {
        // No A3API => plain-browser preview: allow straight in so the shell can be inspected.
        // In-game (A3API present) a timeout is a real failure - surface it instead of faking a login.
        if (typeof A3API === "undefined") { startDesktop({ hostname: "ae3-os", user: user.value || "user" }); return; }
        console.error("[AE3] login request failed:", e);
        err.textContent = "Login timed out - check the server connection."; pass.value = "";
      });
    }

    document.getElementById("loginBtn").addEventListener("click", function () { submit(); });
    pass.addEventListener("keydown", function (e) { if (e.key === "Enter") submit(); });
    user.focus();
  }

  // Re-show the login overlay (used by Sign out). The submit listeners were bound once in
  // showLogin() at boot and stay attached, so this only toggles visibility and resets the form.
  window.AE3_showLogin = function () {
    var login = document.getElementById("login");
    if (!login) return;
    login.classList.add("show");
    var pass = document.getElementById("loginPass");
    var err = document.getElementById("loginErr");
    if (pass) pass.value = "";
    if (err) err.textContent = "";
    var user = document.getElementById("loginUser");
    if (user) user.focus();
  };

  // Hostname seed (login stays up); apply to the top bar when the desktop starts.
  A3.on("hostname", function (s) { seededHost = (s && s.hostname) || seededHost; });

  // Explicit auto-login: SQF may push "boot" to skip the login screen (not sent on plain "ready").
  A3.on("boot", function (session) { startDesktop(session || {}); });

  function boot() {
    showLogin();
    // Tell SQF the UI is ready (so it can push session/hostname).
    A3.send("ready", {});
  }

  // This module is injected by the loader *after* DOMContentLoaded has already fired, so a
  // DOMContentLoaded listener would never run. Boot immediately when the DOM is ready.
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot);
  } else {
    boot();
  }
})();
