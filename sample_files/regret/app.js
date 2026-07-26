(function () {
  var feed = document.getElementById("feed");
  var chips = document.querySelectorAll(".chip");
  var alertCount = document.getElementById("alertCount");
  var current = "all";

  function setFilter(kind) {
    current = kind;
    chips.forEach(function (chip) { chip.classList.toggle("active", chip.dataset.filter === kind); });
    feed.querySelectorAll(".post").forEach(function (post) {
      var ok = kind === "all" || post.dataset.kind === kind;
      post.style.display = ok ? "" : "none";
    });
  }

  chips.forEach(function (chip) {
    chip.addEventListener("click", function () {
      setFilter(chip.dataset.filter);
    });
  });

  feed.addEventListener("click", function (e) {
    var btn = e.target.closest("button");
    if (!btn || !btn.textContent.trim().toLowerCase().startsWith("like")) return;
    var count = btn.querySelector(".count");
    if (count) count.textContent = String(Number(count.textContent) + 1);
    alertCount.textContent = String(Number(alertCount.textContent) + 1);
  });

  setFilter(current);
})();
