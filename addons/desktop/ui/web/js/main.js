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

    function submit() {
      err.textContent = "";
      A3.request("login", { user: user.value, pass: pass.value }).then(function (res) {
        if (res && res.ok) { startDesktop(res); }
        else { err.textContent = (res && res.message) || "Login failed"; pass.value = ""; }
      }).catch(function () {
        // Offline/browser preview: allow straight in so the shell can be inspected.
        startDesktop({ hostname: "ae3-os", user: user.value || "user" });
      });
    }

    document.getElementById("loginBtn").addEventListener("click", submit);
    pass.addEventListener("keydown", function (e) { if (e.key === "Enter") submit(); });
    user.focus();
  }

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
