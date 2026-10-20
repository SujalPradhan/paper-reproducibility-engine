(function () {
  "use strict";
  var NS = "http://www.w3.org/2000/svg";
  var VERDICT_VAR = { "Reproduced": "--good", "Partial": "--warn", "Not reproduced": "--bad", "Not reproducible": "--na" };
  var VERDICT_ICON = { "Reproduced": "✓", "Partial": "≈", "Not reproduced": "✗", "Not reproducible": "–" };
  var CLAMP = 100;

  var dataEl = document.getElementById("page-data");
  var DATA = dataEl ? JSON.parse(dataEl.textContent) : {};
  var tooltip = document.querySelector(".tooltip");

  function el(name, attrs, parent) {
    var n = document.createElementNS(NS, name);
    for (var k in attrs) n.setAttribute(k, attrs[k]);
    if (parent) parent.appendChild(n);
    return n;
  }
  function text(parent, x, y, str, cls, anchor) {
    var t = el("text", { x: x, y: y, "text-anchor": anchor || "start" }, parent);
    if (cls) t.setAttribute("class", cls);
    t.textContent = str;
    return t;
  }
  function color(v) {
    return getComputedStyle(document.documentElement).getPropertyValue(VERDICT_VAR[v]).trim();
  }
  function pct(v) {
    if (v === null || v === undefined) return "—";
    var s = Math.abs(v) < 10 ? v.toFixed(1) : v.toFixed(0);
    return (v > 0 ? "+" : "") + s + "%";
  }

  function showTip(evt, r) {
    tooltip.textContent = "";
    var b = document.createElement("b");
    b.textContent = VERDICT_ICON[r.verdict] + " " + r.verdict;
    tooltip.appendChild(b);
    var rows = [["Paper", r.paper_text], ["Ours", r.ours], ["Deviation", pct(r.dev)], ["Tolerance", r.tol === null ? "—" : "±" + Math.abs(r.tol).toFixed(2) + "%"]];
    rows.forEach(function (kv) {
      var d = document.createElement("div");
      d.className = "tt-row";
      var a = document.createElement("span"); a.className = "tt-muted"; a.textContent = kv[0];
      var v = document.createElement("span"); v.textContent = kv[1];
      d.appendChild(a); d.appendChild(v); tooltip.appendChild(d);
    });
    var c = document.createElement("div");
    c.className = "tt-muted";
    c.textContent = r.paper + " · " + r.claim + ": " + r.text;
    tooltip.appendChild(c);
    tooltip.hidden = false;
    var rect = evt.currentTarget.getBoundingClientRect();
    var x = evt.clientX || rect.left + rect.width / 2;
    var y = evt.clientY || rect.top;
    var w = tooltip.offsetWidth, h = tooltip.offsetHeight;
    tooltip.style.left = Math.max(8, Math.min(window.innerWidth - w - 8, x + 12)) + "px";
    tooltip.style.top = Math.max(8, (y - h - 12 < 8 ? y + 16 : y - h - 12)) + "px";
  }
  function hideTip() { tooltip.hidden = true; }

  function legend(fig, verdicts) {
    var lg = document.createElement("div");
    lg.className = "legend";
    verdicts.forEach(function (v) {
      var s = document.createElement("span");
      var i = document.createElement("i");
      i.style.background = color(v);
      s.appendChild(i);
      s.appendChild(document.createTextNode(VERDICT_ICON[v] + " " + v));
      lg.appendChild(s);
    });
    var s = document.createElement("span");
    var i = document.createElement("i"); i.className = "band-key";
    s.appendChild(i); s.appendChild(document.createTextNode("Pre-registered tolerance"));
    lg.appendChild(s);
    fig.appendChild(lg);
  }

  function deviation(fig) {
    var rows = DATA.rows || [];
    if (fig.dataset.paper) rows = rows.filter(function (r) { return r.paper_id === fig.dataset.paper; });
    if (!rows.length) { fig.remove(); return; }
    fig.textContent = "";
    var present = ["Reproduced", "Partial", "Not reproduced", "Not reproducible"].filter(function (v) {
      return rows.some(function (r) { return r.verdict === v; });
    });
    legend(fig, present);

    var W = Math.max(320, fig.clientWidth - 32);
    var labelH = 18, rowH = 46, groupH = 26, padTop = 8, axisH = 28;
    var maxAbs = 10;
    rows.forEach(function (r) {
      if (r.dev !== null) maxAbs = Math.max(maxAbs, Math.min(CLAMP, Math.abs(r.dev) * 1.15));
      if (r.tol !== null) maxAbs = Math.max(maxAbs, Math.min(CLAMP, Math.abs(r.tol) * 1.3));
    });
    var nice = [10, 20, 25, 50, 100];
    for (var i = 0; i < nice.length; i++) if (nice[i] >= maxAbs) { maxAbs = nice[i]; break; }
    var ticks = [-maxAbs, -maxAbs / 2, 0, maxAbs / 2, maxAbs];
    var x0 = 8, x1 = W - 8;
    function sx(v) { return x0 + (Math.max(-maxAbs, Math.min(maxAbs, v)) + maxAbs) / (2 * maxAbs) * (x1 - x0); }

    var groups = [];
    rows.forEach(function (r) {
      if (!groups.length || groups[groups.length - 1].paper !== r.paper) groups.push({ paper: r.paper, rows: [] });
      groups[groups.length - 1].rows.push(r);
    });
    var multi = groups.length > 1;
    var H = padTop + axisH + groups.reduce(function (a, g) { return a + (multi ? groupH : 0) + g.rows.length * rowH; }, 0);
    var svg = el("svg", { viewBox: "0 0 " + W + " " + H, role: "img" }, fig);
    var title = el("title", {}, svg);
    title.textContent = fig.getAttribute("aria-label");

    var plotTop = padTop, plotBottom = H - axisH;
    ticks.forEach(function (t) {
      el("line", { x1: sx(t), x2: sx(t), y1: plotTop, y2: plotBottom, class: t === 0 ? "zero" : "grid" }, svg);
      text(svg, sx(t), H - 8, (t > 0 ? "+" : "") + t + "%" + (Math.abs(t) === CLAMP ? "+" : ""), "t-muted", t === -maxAbs ? "start" : t === maxAbs ? "end" : "middle");
    });

    var y = plotTop;
    groups.forEach(function (g) {
      if (multi) {
        text(svg, x0, y + 18, g.paper, "t-ink").setAttribute("font-weight", "600");
        y += groupH;
      }
      g.rows.forEach(function (r) {
        var row = el("g", { class: "row", tabindex: "0", role: "listitem", "aria-label": r.claim + " " + r.text + ": " + r.verdict + ", paper " + r.paper_text + ", ours " + r.ours }, svg);
        el("rect", { x: 0, y: y, width: W, height: rowH, class: "rowbg", rx: 6 }, row);
        var label = r.claim + " · " + r.text;
        var maxChars = Math.floor((x1 - x0) / 6.6);
        if (label.length > maxChars) label = label.slice(0, maxChars - 1) + "…";
        text(row, x0, y + labelH - 2, label);
        var cy = y + labelH + 14;
        if (r.tol !== null) {
          var tw = Math.abs(r.tol);
          el("rect", { x: sx(-tw), y: cy - 9, width: Math.max(2, sx(tw) - sx(-tw)), height: 18, rx: 4, class: "band" }, row);
        }
        if (r.dev === null) {
          text(row, sx(0) + 8, cy + 4, "– could not compute", "t-muted");
        } else {
          var clamped = Math.abs(r.dev) > maxAbs;
          var cx = sx(r.dev);
          el("circle", { cx: cx, cy: cy, r: 6, class: "dot", fill: color(r.verdict) }, row);
          if (clamped) text(row, cx + (r.dev > 0 ? -12 : 12), cy + 4, (r.dev > 0 ? "▶ " : "◀ ") + pct(r.dev), "t-ink", r.dev > 0 ? "end" : "start");
        }
        var hit = el("rect", { x: 0, y: y, width: W, height: rowH, class: "hit" }, row);
        row.addEventListener("pointermove", function (e) { showTip(e, r); });
        row.addEventListener("pointerleave", hideTip);
        row.addEventListener("focus", function (e) { showTip(e, r); });
        row.addEventListener("blur", hideTip);
        y += rowH;
      });
    });
    el("line", { x1: x0, x2: x1, y1: plotBottom, y2: plotBottom, class: "axis" }, svg);
  }

  function screening(fig) {
    var s = DATA.screening;
    if (!s) { fig.remove(); return; }
    fig.textContent = "";
    var W = Math.max(320, fig.clientWidth - 32), rowH = 52, barH = 20;
    var H = s.stages.length * rowH;
    var max = Math.max.apply(null, s.stages.map(function (d) { return d.n; })) || 1;
    var svg = el("svg", { viewBox: "0 0 " + W + " " + H, role: "img" }, fig);
    el("title", {}, svg).textContent = fig.getAttribute("aria-label");
    var labelW = 40;
    s.stages.forEach(function (d, i) {
      var y = i * rowH;
      text(svg, 0, y + 16, d.label);
      var w = Math.max(4, (W - labelW) * d.n / max);
      var bar = el("path", { d: roundRight(0, y + 24, w, barH, 4), fill: "var(--ord-" + (i + 1) + ")" }, svg);
      bar.style.fill = "var(--ord-" + (i + 1) + ")";
      text(svg, w + 8, y + 24 + barH / 2 + 4, String(d.n), "t-ink");
    });
  }
  function roundRight(x, y, w, h, r) {
    r = Math.min(r, w);
    return "M" + x + "," + y + "h" + (w - r) + "a" + r + "," + r + " 0 0 1 " + r + "," + r + "v" + (h - 2 * r) + "a" + r + "," + r + " 0 0 1 " + -r + "," + r + "h" + -(w - r) + "z";
  }

  function rowsTable() {
    var t = document.querySelector(".rows-table");
    if (!t || !DATA.rows) return;
    var head = ["Paper", "Claim", "Paper says", "We got", "Deviation", "Verdict"];
    var tr = document.createElement("tr");
    head.forEach(function (h) { var th = document.createElement("th"); th.textContent = h; tr.appendChild(th); });
    t.appendChild(tr);
    DATA.rows.forEach(function (r) {
      var tr = document.createElement("tr");
      [r.paper, r.claim + " " + r.text, r.paper_text, r.ours, pct(r.dev), VERDICT_ICON[r.verdict] + " " + r.verdict].forEach(function (v, i) {
        var td = document.createElement("td");
        if (i >= 2 && i <= 4) td.className = "num";
        td.textContent = v;
        tr.appendChild(td);
      });
      t.appendChild(tr);
    });
  }

  function renderAll() {
    document.querySelectorAll('[data-chart="deviation"]').forEach(deviation);
    document.querySelectorAll('[data-chart="screening"]').forEach(screening);
  }

  var btn = document.querySelector(".theme");
  if (btn) btn.addEventListener("click", function () {
    var root = document.documentElement;
    var dark = root.dataset.theme ? root.dataset.theme === "dark" : matchMedia("(prefers-color-scheme: dark)").matches;
    root.dataset.theme = dark ? "light" : "dark";
    try { localStorage.setItem("theme", root.dataset.theme); } catch (e) {}
    renderAll();
  });
  var resizeTimer;
  window.addEventListener("resize", function () { clearTimeout(resizeTimer); resizeTimer = setTimeout(renderAll, 150); });
  matchMedia("(prefers-color-scheme: dark)").addEventListener("change", renderAll);
  rowsTable();
  renderAll();
})();
