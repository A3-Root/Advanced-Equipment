(function () {
  function svgData(svg) {
    return "data:image/svg+xml;charset=utf-8," + encodeURIComponent(svg.trim());
  }
  var items = [
    {
      tag: "night",
      title: "Night relay over the ridge",
      caption: "Observation ridge",
      text: "A moonlit hill shot used as the hero image for the archive.",
      svg: '<svg viewBox="0 0 600 600" xmlns="http://www.w3.org/2000/svg"><rect width="600" height="600" fill="#1f2032"/><circle cx="180" cy="150" r="84" fill="#88d7ff" fill-opacity=".35"/><path d="M0 430 L150 340 L260 420 L380 280 L600 430 L600 600 L0 600 Z" fill="#10131f"/><path d="M95 430 L175 270 L260 430 Z" fill="#2e3250"/><path d="M250 430 L360 240 L470 430 Z" fill="#242943"/><path d="M430 430 L510 330 L600 430 Z" fill="#2a2f49"/></svg>'
    },
    {
      tag: "terrain",
      title: "Survey line at dawn",
      caption: "Terrain scan",
      text: "A terrain image that can stand in for route recon or horizon planning.",
      svg: '<svg viewBox="0 0 600 600" xmlns="http://www.w3.org/2000/svg"><rect width="600" height="600" fill="#25263a"/><rect width="600" height="600" fill="url(#g)"/><defs><linearGradient id="g" x1="0" x2="1"><stop offset="0" stop-color="#2d334d"/><stop offset="1" stop-color="#171a28"/></linearGradient></defs><circle cx="420" cy="140" r="70" fill="#f6c177" fill-opacity=".62"/><path d="M0 470 C120 430, 210 400, 320 430 S520 540, 600 500 L600 600 L0 600 Z" fill="#10131f"/><path d="M70 500 L190 320 L300 500 Z" fill="#2d334d"/><path d="M260 500 L380 280 L500 500 Z" fill="#20253b"/></svg>'
    },
    {
      tag: "interior",
      title: "Evidence wall",
      caption: "Interior photo",
      text: "A warmer interior frame suitable for rooms, maps, or briefing board photos.",
      svg: '<svg viewBox="0 0 600 600" xmlns="http://www.w3.org/2000/svg"><rect width="600" height="600" fill="#2a2230"/><rect x="110" y="100" width="380" height="400" rx="18" fill="#40324b"/><rect x="145" y="135" width="310" height="330" rx="12" fill="#241d2c"/><circle cx="300" cy="250" r="76" fill="#f6c177" fill-opacity=".65"/><rect x="180" y="370" width="240" height="18" rx="9" fill="#88d7ff" fill-opacity=".52"/><rect x="180" y="402" width="180" height="18" rx="9" fill="#88d7ff" fill-opacity=".38"/></svg>'
    },
    {
      tag: "night",
      title: "Dock lights",
      caption: "Night port",
      text: "A darker harbor view for surveillance or harbor-watch missions.",
      svg: '<svg viewBox="0 0 600 600" xmlns="http://www.w3.org/2000/svg"><rect width="600" height="600" fill="#1a1730"/><circle cx="130" cy="130" r="100" fill="#88d7ff" fill-opacity=".28"/><path d="M0 420 L120 360 L240 420 L360 300 L480 390 L600 330 L600 600 L0 600 Z" fill="#0f1220"/><rect x="90" y="260" width="60" height="150" rx="8" fill="#302b46"/><rect x="210" y="220" width="60" height="190" rx="8" fill="#2b2740"/><rect x="330" y="260" width="60" height="150" rx="8" fill="#403558"/><rect x="450" y="190" width="60" height="220" rx="8" fill="#4b3e61"/></svg>'
    },
    {
      tag: "terrain",
      title: "Route markers",
      caption: "Map detail",
      text: "An overhead map-style image for patrol routes and checkpoints.",
      svg: '<svg viewBox="0 0 600 600" xmlns="http://www.w3.org/2000/svg"><rect width="600" height="600" fill="#1f2b23"/><path d="M0 500 L110 420 L220 450 L330 340 L460 390 L600 280 L600 600 L0 600 Z" fill="#121b17"/><circle cx="140" cy="270" r="44" fill="#73d6c9" fill-opacity=".55"/><circle cx="290" cy="230" r="44" fill="#f6c177" fill-opacity=".55"/><circle cx="440" cy="180" r="44" fill="#88d7ff" fill-opacity=".55"/><path d="M140 270 L290 230 L440 180" stroke="#d8e8ff" stroke-width="8" stroke-linecap="round" stroke-dasharray="10 8" fill="none"/></svg>'
    },
    {
      tag: "interior",
      title: "Briefing board",
      caption: "Planning room",
      text: "A cleaner room shot for intel, planning, or investigation galleries.",
      svg: '<svg viewBox="0 0 600 600" xmlns="http://www.w3.org/2000/svg"><rect width="600" height="600" fill="#2a2230"/><rect x="120" y="80" width="360" height="440" rx="20" fill="#3b3346"/><rect x="150" y="110" width="300" height="380" rx="14" fill="#191722"/><rect x="182" y="140" width="240" height="30" rx="10" fill="#88d7ff" fill-opacity=".6"/><rect x="182" y="190" width="180" height="18" rx="9" fill="#f6c177" fill-opacity=".66"/><rect x="182" y="220" width="220" height="18" rx="9" fill="#f6c177" fill-opacity=".46"/><rect x="182" y="250" width="200" height="18" rx="9" fill="#73d6c9" fill-opacity=".46"/></svg>'
    }
  ];

  var filters = document.getElementById("filters");
  var thumbs = document.getElementById("thumbs");
  var heroTitle = document.getElementById("heroTitle");
  var heroBody = document.getElementById("heroBody");
  var countAll = document.getElementById("countAll");
  var countTag = document.getElementById("countTag");
  var modal = document.getElementById("modal");
  var modalTitle = document.getElementById("modalTitle");
  var modalCaption = document.getElementById("modalCaption");
  var modalText = document.getElementById("modalText");
  var modalPreview = document.getElementById("modalPreview");
  var closeModal = document.getElementById("closeModal");
  var activeTag = "all";
  var currentItems = items.slice();

  function render() {
    thumbs.innerHTML = "";
    currentItems.forEach(function (item) {
      var el = document.createElement("button");
      el.className = "thumb";
      el.dataset.tag = item.tag;
      el.innerHTML =
        '<img alt="' + item.caption + '" src="' + svgData(item.svg) + '">' +
        '<div class="cap"><strong>' + item.title + '</strong><span>' + item.caption + '</span></div>';
      el.addEventListener("click", function () { openItem(item); });
      thumbs.appendChild(el);
    });
    countTag.textContent = String(currentItems.length);
  }
  function openItem(item) {
    heroTitle.textContent = item.title;
    heroBody.textContent = item.text;
    modalTitle.textContent = item.title;
    modalCaption.textContent = item.caption;
    modalText.textContent = item.text;
    modalPreview.innerHTML = item.svg;
    modal.classList.add("open");
    modal.setAttribute("aria-hidden", "false");
  }
  function applyFilter(tag) {
    activeTag = tag;
    filters.querySelectorAll(".filter").forEach(function (btn) {
      btn.classList.toggle("active", btn.dataset.tag === tag);
    });
    currentItems = tag === "all" ? items.slice() : items.filter(function (item) { return item.tag === tag; });
    render();
  }

  filters.addEventListener("click", function (e) {
    var btn = e.target.closest(".filter");
    if (!btn) return;
    applyFilter(btn.dataset.tag);
  });
  closeModal.addEventListener("click", function () {
    modal.classList.remove("open");
    modal.setAttribute("aria-hidden", "true");
  });
  modal.addEventListener("click", function (e) {
    if (e.target === modal) closeModal.click();
  });

  countAll.textContent = String(items.length);
  applyFilter(activeTag);
})();
