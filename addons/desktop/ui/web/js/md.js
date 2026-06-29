/*
 * AE3 minimal Markdown -> HTML renderer for the in-browser wiki (the repo's wiki/*.md are vendored
 * into ui/web/wiki and rendered client-side, so the wiki stays a single source of truth with no
 * build step). Supports headings, bold/italic/inline-code, fenced code, links, blockquotes,
 * ordered/unordered lists, horizontal rules and paragraphs. Not a full CommonMark parser - just
 * enough for the bundled docs. window.MD is global.
 */
(function () {
  function esc(s) {
    return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  }

  // Inline spans: code, bold, italic, links. Operates on already HTML-escaped text.
  function inline(s) {
    return s
      .replace(/`([^`]+)`/g, function (_, c) { return "<code>" + c + "</code>"; })
      .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
      .replace(/__([^_]+)__/g, "<strong>$1</strong>")
      .replace(/(^|[^*])\*([^*]+)\*/g, "$1<em>$2</em>")
      // wiki-style links: [[target|label]] and the label-less [[target]]. Resolved before the
      // standard [text](url) rule so they render as real anchors instead of literal brackets.
      .replace(/\[\[([^\]|]+)\|([^\]]+)\]\]/g, function (_, href, t) { return '<a href="' + href.trim() + '">' + t.trim() + "</a>"; })
      .replace(/\[\[([^\]|]+)\]\]/g, function (_, href) { return '<a href="' + href.trim() + '">' + href.trim() + "</a>"; })
      .replace(/\[([^\]]+)\]\(([^)]+)\)/g, function (_, t, href) {
        // wiki-internal links keep their .md target; the wiki app intercepts clicks.
        return '<a href="' + href + '">' + t + "</a>";
      });
  }

  function render(md) {
    var lines = String(md).replace(/\r\n/g, "\n").split("\n");
    var out = [];
    var i = 0;
    var listType = null; // "ul" | "ol" | null

    function closeList() { if (listType) { out.push("</" + listType + ">"); listType = null; } }

    while (i < lines.length) {
      var line = lines[i];

      // fenced code block
      if (/^```/.test(line)) {
        closeList();
        var buf = [];
        i++;
        while (i < lines.length && !/^```/.test(lines[i])) { buf.push(esc(lines[i])); i++; }
        i++; // skip closing fence
        out.push("<pre><code>" + buf.join("\n") + "</code></pre>");
        continue;
      }

      // blank line
      if (/^\s*$/.test(line)) { closeList(); i++; continue; }

      // horizontal rule
      if (/^\s*(-{3,}|\*{3,})\s*$/.test(line)) { closeList(); out.push("<hr>"); i++; continue; }

      // heading
      var hm = /^(#{1,6})\s+(.*)$/.exec(line);
      if (hm) { closeList(); var lvl = hm[1].length; out.push("<h" + lvl + ">" + inline(esc(hm[2])) + "</h" + lvl + ">"); i++; continue; }

      // blockquote
      if (/^>\s?/.test(line)) {
        closeList();
        var qbuf = [];
        while (i < lines.length && /^>\s?/.test(lines[i])) { qbuf.push(inline(esc(lines[i].replace(/^>\s?/, "")))); i++; }
        out.push("<blockquote>" + qbuf.join("<br>") + "</blockquote>");
        continue;
      }

      // unordered list
      if (/^\s*[-*+]\s+/.test(line)) {
        if (listType !== "ul") { closeList(); out.push("<ul>"); listType = "ul"; }
        out.push("<li>" + inline(esc(line.replace(/^\s*[-*+]\s+/, ""))) + "</li>");
        i++; continue;
      }

      // ordered list
      if (/^\s*\d+\.\s+/.test(line)) {
        if (listType !== "ol") { closeList(); out.push("<ol>"); listType = "ol"; }
        out.push("<li>" + inline(esc(line.replace(/^\s*\d+\.\s+/, ""))) + "</li>");
        i++; continue;
      }

      // raw HTML block: a line that opens or closes an HTML tag passes through untouched, and so do
      // the contiguous lines up to the next blank one. Markdown allows embedded HTML, so this lets
      // authors write a page in plain HTML or drop HTML blocks (e.g. an intel webpage with <h2>/<p>
      // markup) into otherwise-markdown content. Tag-like only ("<word"/"</word"), so prose such as
      // "x < y" is still treated as a normal paragraph and escaped.
      if (/^\s*<\/?\w+[^>]*>/.test(line)) {
        closeList();
        var hbuf = [];
        while (i < lines.length && !/^\s*$/.test(lines[i])) { hbuf.push(lines[i]); i++; }
        out.push(hbuf.join("\n"));
        continue;
      }

      // paragraph (merge consecutive non-empty lines)
      closeList();
      var pbuf = [];
      while (i < lines.length && !/^\s*$/.test(lines[i]) && !/^(#{1,6}\s|>|```|\s*[-*+]\s|\s*\d+\.\s)/.test(lines[i]) && !/^\s*(-{3,}|\*{3,})\s*$/.test(lines[i])) {
        pbuf.push(inline(esc(lines[i]))); i++;
      }
      out.push("<p>" + pbuf.join("<br>") + "</p>");
    }
    closeList();
    return out.join("\n");
  }

  window.MD = { render: render, escape: esc };
})();
