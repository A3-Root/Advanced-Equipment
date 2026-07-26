(function () {
  function pad(n) { return String(n).padStart(2, "0"); }
  var clock = document.getElementById("clock");
  var title = document.getElementById("heroTitle");
  var body = document.getElementById("heroBody");
  var bannerState = document.getElementById("bannerState");
  var frames = [
    ["Depot window closes at 04:15.", "Primary route remains open. Escort the second truck only if the relay confirms the handoff.", "Convoy watch"],
    ["Paper trail updated at 02:47.", "The portal now points to the field notes and the relay log.", "Intel refresh"],
    ["Fallback route is Blue tunnel.", "If Route Red gets blocked, the portal links the alternate site list.", "Route change"]
  ];
  var idx = 0;

  function tick() {
    var now = new Date();
    clock.textContent = pad(now.getHours()) + ":" + pad(now.getMinutes());
  }
  function rotate() {
    idx = (idx + 1) % frames.length;
    title.textContent = frames[idx][0];
    body.textContent = frames[idx][1];
    bannerState.textContent = frames[idx][2];
  }

  tick();
  setInterval(tick, 1000);
  setInterval(rotate, 7000);
})();
