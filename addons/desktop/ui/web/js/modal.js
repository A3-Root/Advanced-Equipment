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
    // Slider input (Root_CW Vehicles #1): pick a numeric value within [min,max]. Resolves the chosen
    // number, or null on cancel. unit is an optional suffix shown next to the value (e.g. "%", "km/h").
    slider: function (title, min, max, value, step, unit, opts) {
      min = Number(min); max = Number(max); step = Number(step) || 1;
      if (!isFinite(value)) value = min;
      value = Math.min(max, Math.max(min, Number(value)));
      unit = unit || "";
      opts = opts || {};
      return new Promise(function (resolve) {
        overlay(function (box, close) {
          var checkHtml = opts.checkboxLabel ? '<label class="muted" style="display:flex;gap:8px;align-items:center;margin-top:10px"><input class="scheck" type="checkbox">' + opts.checkboxLabel + '</label>' : '';
          box.innerHTML =
            '<div class="titlebar"><span class="title">' + title + '</span></div>' +
            '<div class="pad">' +
              '<div style="display:flex;align-items:center;gap:10px">' +
                '<input class="srange" type="range" style="flex:1" min="' + min + '" max="' + max + '" step="' + step + '" value="' + value + '">' +
                '<input class="input snum" type="number" style="width:90px" min="' + min + '" max="' + max + '" step="' + step + '" value="' + value + '">' +
                '<span class="muted sunit">' + unit + '</span>' +
              '</div>' +
              '<div class="muted" style="font-size:12px;margin-top:6px">Range: ' + min + ' - ' + max + ' ' + unit + '</div>' +
              checkHtml +
              '<div style="margin-top:12px;text-align:right;display:flex;gap:8px;justify-content:flex-end">' +
              '<button class="btn cancel">Cancel</button><button class="btn accent ok">Apply</button></div></div>';
          var range = box.querySelector(".srange");
          var num = box.querySelector(".snum");
          function clamp(v) { v = Number(v); if (!isFinite(v)) v = min; return Math.min(max, Math.max(min, v)); }
          range.addEventListener("input", function () { num.value = range.value; });
          num.addEventListener("input", function () { range.value = clamp(num.value); });
          box.querySelector(".ok").addEventListener("click", function () {
            var out = clamp(num.value);
            if (opts.returnObject) out = { value: out, lock: !!(box.querySelector(".scheck") && box.querySelector(".scheck").checked) };
            close(out);
          });
          box.querySelector(".cancel").addEventListener("click", function () { close(null); });
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
