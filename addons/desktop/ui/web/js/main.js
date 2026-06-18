/*
 * AE3 web desktop boot. Shows the login screen (per-user filesystem, issue #9), authenticates
 * against the AE3 user list via the SQF backend (A3.request "login"), then starts the desktop.
 * SQF can also push "boot" with session info to skip/seed login.
 */
(function () {
  function startDesktop(session) {
    document.getElementById("login").classList.remove("show");
    Desktop.init();
    if (session && session.hostname) Desktop.setHostname(session.hostname);
  }

  function showLogin() {
    var login = document.getElementById("login");
    login.classList.add("show");
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

  // SQF may push a ready boot (e.g. auto-login) at any time.
  A3.on("boot", function (session) { startDesktop(session || {}); });

  document.addEventListener("DOMContentLoaded", function () {
    showLogin();
    // Tell SQF the UI is ready (so it can push session/hostname).
    A3.send("ready", {});
  });
})();
