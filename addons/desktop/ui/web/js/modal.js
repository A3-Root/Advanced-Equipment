/*
 * AE3 modal dialogs - prompt / confirm / alert as centered overlays (Yaru styled). Used by apps
 * for "Save As", "New folder", delete confirmation, etc. Promise-based.
 */
(function () {
  function overlay(buildBody, onResolve) {
    var ov = document.createElement("div");
    ov.style.cssText = "position:fixed;inset:0;z-index:5000;display:flex;align-items:center;justify-content:center;background:rgba(0,0,0,0.45);";
    var box = document.createElement("div");
    box.className = "window";
    box.style.cssText = "position:relative;min-width:340px;max-width:80%;";
    ov.appendChild(box);
    document.body.appendChild(ov);
    function close(val) { ov.remove(); onResolve(val); }
    buildBody(box, close);
    return ov;
  }

  var Modal = {
    prompt: function (title, value) {
      return new Promise(function (resolve) {
        overlay(function (box, close) {
          box.innerHTML =
            '<div class="titlebar"><span class="title">' + title + '</span></div>' +
            '<div class="pad"><input class="input" style="width:100%" value="' + (value || "") + '">' +
            '<div style="margin-top:12px;text-align:right;display:flex;gap:8px;justify-content:flex-end">' +
            '<button class="btn cancel">Cancel</button><button class="btn accent ok">OK</button></div></div>';
          var input = box.querySelector("input");
          input.focus(); input.select();
          box.querySelector(".ok").addEventListener("click", function () { close(input.value); });
          box.querySelector(".cancel").addEventListener("click", function () { close(null); });
          input.addEventListener("keydown", function (e) {
            if (e.key === "Enter") close(input.value);
            if (e.key === "Escape") close(null);
          });
        }, resolve);
      });
    },
    confirm: function (title, message) {
      return new Promise(function (resolve) {
        overlay(function (box, close) {
          box.innerHTML =
            '<div class="titlebar"><span class="title">' + title + '</span></div>' +
            '<div class="pad"><p>' + message + '</p>' +
            '<div style="margin-top:12px;text-align:right;display:flex;gap:8px;justify-content:flex-end">' +
            '<button class="btn cancel">Cancel</button><button class="btn accent ok">OK</button></div></div>';
          box.querySelector(".ok").addEventListener("click", function () { close(true); });
          box.querySelector(".cancel").addEventListener("click", function () { close(false); });
        }, resolve);
      });
    },
    alert: function (title, message) {
      return new Promise(function (resolve) {
        overlay(function (box, close) {
          box.innerHTML =
            '<div class="titlebar"><span class="title">' + title + '</span></div>' +
            '<div class="pad"><p>' + message + '</p>' +
            '<div style="margin-top:12px;text-align:right"><button class="btn accent ok">OK</button></div></div>';
          box.querySelector(".ok").addEventListener("click", function () { close(true); });
        }, resolve);
      });
    }
  };

  window.Modal = Modal;
})();
