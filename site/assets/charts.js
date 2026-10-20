(function () {
  "use strict";
  var NS = "http://www.w3.org/2000/svg";
  var ORDER = ["Reproduced", "Partial", "Not reproduced", "Not reproducible"];
  var VAR = { "Reproduced": "--good", "Partial": "--warn", "Not reproduced": "--bad", "Not reproducible": "--na" };
  var ICON = { "Reproduced": "✓", "Partial": "≈", "Not reproduced": "✗", "Not reproducible": "–" };
  var INK_ON = { "Reproduced": "#fff", "Partial": "#0b0b0b", "Not reproduced": "#fff", "Not reproducible": "#0b0b0b" };

  var dataEl = document.getElementById("page-data");
  var DATA = dataEl ? JSON.parse(dataEl.textContent) : {};
  var tooltip = document.querySelector(".tooltip");
  var titleId = 0, activeTip = null, dismissedTip = null, touchTip = null;
  if (tooltip) {
    tooltip.id = "chart-tooltip";
    tooltip.setAttribute("role", "tooltip");
  }

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
  function cssVar(name) { return getComputedStyle(document.documentElement).getPropertyValue(name).trim(); }
  function color(v) { return cssVar(VAR[v]); }
  function width(fig) {
    var style = getComputedStyle(fig);
    return Math.max(1, fig.clientWidth - parseFloat(style.paddingLeft || 0) - parseFloat(style.paddingRight || 0));
  }
  function svgFor(fig, W, H) {
    var old = fig.querySelector("svg");
    if (old) old.remove();
    var id = "chart-title-" + (++titleId);
    var svg = el("svg", { viewBox: "0 0 " + W + " " + H, role: "img", "aria-labelledby": id });
    fig.insertBefore(svg, fig.querySelector("figcaption"));
    el("title", { id: id }, svg).textContent = fig.getAttribute("aria-label") || "Analysis chart";
    return svg;
  }
  function resizeSvg(svg, W, H) { svg.setAttribute("viewBox", "0 0 " + W + " " + H); }
  // Measure the rendered font so labels wrap at the actual figure width.
  function wrapped(parent, x, y, str, maxWidth, cls, lineHeight) {
    var node = text(parent, x, y, "", cls), span = el("tspan", { x: x, y: y }, node);
    var line = "", count = 1;
    lineHeight = lineHeight || 16;
    function fits(value) {
      span.textContent = value;
      var measured = span.getComputedTextLength();
      return (measured || value.length * 6.5) <= maxWidth;
    }
    function next() {
      span.textContent = line;
      span = el("tspan", { x: x, dy: lineHeight }, node);
      line = ""; count++;
    }
    String(str).split(/\s+/).forEach(function (word) {
      var candidate = line ? line + " " + word : word;
      if (fits(candidate)) { line = candidate; return; }
      if (line) next();
      if (fits(word)) { line = word; return; }
      Array.from(word).forEach(function (character) {
        if (line && !fits(line + character)) next();
        line += character;
      });
    });
    span.textContent = line;
    return { node: node, height: count * lineHeight };
  }
  // Bar with 4px rounded data-end on the right only; square at the baseline.
  function bar(parent, x, y, w, h, roundLeft, roundRight) {
    var r = Math.min(4, w / 2);
    var rl = roundLeft ? r : 0, rr = roundRight ? r : 0;
    var d = "M" + (x + rl) + "," + y + "h" + (w - rl - rr) +
      (rr ? "a" + rr + "," + rr + " 0 0 1 " + rr + "," + rr : "") + "v" + (h - 2 * rr) +
      (rr ? "a" + rr + "," + rr + " 0 0 1 " + -rr + "," + rr : "") + "h" + -(w - rl - rr) +
      (rl ? "a" + rl + "," + rl + " 0 0 1 " + -rl + "," + -rl : "") + "v" + -(h - 2 * rl) +
      (rl ? "a" + rl + "," + rl + " 0 0 1 " + rl + "," + -rl : "") + "z";
    return el("path", { d: d }, parent);
  }

  function tip(evt, lines) {
    if (!tooltip || dismissedTip === evt.currentTarget) return;
    if (activeTip && activeTip !== evt.currentTarget) activeTip.removeAttribute("aria-describedby");
    activeTip = evt.currentTarget;
    activeTip.setAttribute("aria-describedby", tooltip.id);
    tooltip.textContent = "";
    lines.forEach(function (l, i) {
      var d = document.createElement("div");
      if (i === 0) { var b = document.createElement("b"); b.textContent = l; d.appendChild(b); }
      else { d.className = "tt-muted"; d.textContent = l; }
      tooltip.appendChild(d);
    });
    tooltip.hidden = false;
    tooltip.style.maxWidth = Math.max(1, Math.min(320, window.innerWidth - 32)) + "px";
    var rect = evt.currentTarget.getBoundingClientRect();
    var x = typeof evt.clientX === "number" ? evt.clientX : rect.left + rect.width / 2;
    var y = typeof evt.clientY === "number" ? evt.clientY : rect.top;
    var w = tooltip.offsetWidth, h = tooltip.offsetHeight;
    tooltip.style.left = Math.max(8, Math.min(window.innerWidth - w - 8, x + 12)) + "px";
    tooltip.style.top = Math.max(8, Math.min(window.innerHeight - h - 8, y - h - 12 < 8 ? y + 16 : y - h - 12)) + "px";
  }
  function hideTip() {
    if (tooltip) tooltip.hidden = true;
    if (activeTip) activeTip.removeAttribute("aria-describedby");
    activeTip = null; touchTip = null;
  }
  function hover(node, lines) {
    node.setAttribute("tabindex", "0");
    node.setAttribute("aria-label", lines.join(". "));
    node.addEventListener("pointerenter", function (e) { dismissedTip = null; if (e.pointerType !== "touch") tip(e, lines); });
    node.addEventListener("pointermove", function (e) { if (e.pointerType !== "touch") tip(e, lines); });
    node.addEventListener("pointerleave", function () { if (document.activeElement !== node && touchTip !== node) hideTip(); });
    node.addEventListener("pointerup", function (e) {
      if (e.pointerType !== "touch") return;
      if (touchTip === node) { hideTip(); return; }
      dismissedTip = null; touchTip = node; tip(e, lines);
    });
    node.addEventListener("focus", function (e) { dismissedTip = null; tip(e, lines); });
    node.addEventListener("blur", function () { if (activeTip === node) hideTip(); });
  }
  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape") { dismissedTip = activeTip; hideTip(); }
  });
  document.addEventListener("pointerdown", function (e) {
    if (activeTip && !activeTip.contains(e.target)) hideTip();
  });

  // 1. Verdict per paper: one block per headline number, grouped by verdict.
  function verdicts(fig) {
    var papers = DATA.papers || [];
    var W = width(fig), barH = 28, gap = 4, y = 0;
    var max = Math.max(1, Math.max.apply(null, papers.map(function (p) { return p.labels.length; })));
    var svg = svgFor(fig, W, 1), unit = W / max;
    papers.forEach(function (p) {
      var label = wrapped(svg, 0, y + 14, p.short, W, "t-ink");
      label.node.setAttribute("font-weight", "600");
      y += label.height + 8;
      p.labels.forEach(function (c, j) {
        var g = el("g", { class: "mark" }, svg);
        bar(g, j * unit, y, unit - gap, barH, true, true).setAttribute("fill", color(c.v));
        var glyph = text(g, j * unit + (unit - gap) / 2, y + 19, ICON[c.v], "", "middle");
        glyph.style.fill = INK_ON[c.v]; glyph.setAttribute("font-weight", "700");
        hover(g, [ICON[c.v] + " " + c.v, p.short + ": " + c.l]);
      });
      y += barH + 18;
      var summary = ORDER.filter(function (v) { return p.counts[v]; }).map(function (v) { return p.counts[v] + " " + v.toLowerCase(); }).join(" · ");
      y += wrapped(svg, 0, y, summary, W, "t-ink").height + 16;
    });
    resizeSvg(svg, W, Math.max(1, y - 10));
  }

  // 2. Causes of misses: one series, sorted.
  function causes(fig) {
    var cs = DATA.causes || [];
    var W = width(fig), barH = 18, y = 0;
    var max = Math.max(1, Math.max.apply(null, cs.map(function (c) { return c.n; })));
    var svg = svgFor(fig, W, 1), labelPad = 28;
    cs.forEach(function (c) {
      var g = el("g", { class: "mark" }, svg);
      var start = y;
      y += wrapped(g, 0, y + 14, c.label, W, "t-ink").height + 6;
      var w = Math.max(4, (W - labelPad) * c.n / max);
      bar(g, 0, y, w, barH, false, true).setAttribute("fill", cssVar(c.key === "unexplained" ? "--na" : "--ord-2"));
      var v = text(g, w + 8, y + barH / 2 + 4, String(c.n), "t-ink");
      v.setAttribute("font-weight", "600");
      y += barH + 12;
      el("rect", { x: 0, y: start, width: W, height: y - start, class: "hit" }, g);
      hover(g, [c.n + " × " + c.label].concat(c.claims));
    });
    resizeSvg(svg, W, Math.max(1, y));
  }

  // 3. Screening funnel: ordinal ramp.
  function funnel(fig) {
    var st = DATA.funnel || [];
    var W = width(fig), barH = 18, y = 0;
    var max = Math.max.apply(null, st.map(function (d) { return d.n; })) || 1;
    var svg = svgFor(fig, W, 1);
    st.forEach(function (d, i) {
      y += wrapped(svg, 0, y + 14, d.label, W, "t-ink").height + 6;
      var w = Math.max(4, (W - 36) * d.n / max);
      bar(svg, 0, y, w, barH, false, true).setAttribute("fill", cssVar("--ord-" + (i + 1)));
      var v = text(svg, w + 8, y + barH / 2 + 4, String(d.n), "t-ink");
      v.setAttribute("font-weight", "600");
      y += barH + 12;
    });
    resizeSvg(svg, W, Math.max(1, y));
  }

  // Each claim has its own linear scale, measured from its frozen no-effect reference.
  function comparison(fig) {
    var rows = DATA.rows || [];
    if (fig.dataset.paper) rows = rows.filter(function (r) { return r.paper_id === fig.dataset.paper; });
    if (!rows.length) return;
    var W = width(fig), svg = svgFor(fig, W, 1), inset = 8, barH = 10;
    var columns = W >= 680 ? 2 : 1, gap = 28, cellW = (W - gap * (columns - 1)) / columns;
    var gridY = 0, bandHeight = 0;
    rows.forEach(function (r, index) {
      var column = index % columns, y = 0;
      var row = el("g", { class: "row comparison-row", transform: "translate(" + column * (cellW + gap) + "," + gridY + ")" }, svg);
      var bg = el("rect", { x: 0, y: 0, width: cellW, height: 1, class: "rowbg", rx: 6 }, row);
      var label = wrapped(row, 0, y + 14, r.claim + " · " + r.label, cellW, "t-ink");
      label.node.setAttribute("font-weight", "600");
      y += label.height;
      y += wrapped(row, 0, y + 14, ICON[r.verdict] + " " + r.verdict, cellW, "t-ink").height + 5;

      var values = [r.paper_value, r.ours_value];
      var finite = values.filter(function (v) { return typeof v === "number" && Number.isFinite(v); });
      var reference = typeof r.reference_value === "number" && Number.isFinite(r.reference_value) ? r.reference_value : 0;
      var lo = Math.min.apply(null, [reference].concat(finite));
      var hi = Math.max.apply(null, [reference].concat(finite));
      if (lo === hi) hi = lo + 1;
      var extent = hi - lo;
      if (lo < reference) lo -= extent * 0.035;
      if (hi > reference) hi += extent * 0.035;
      function sx(value) { return inset + (value - lo) / (hi - lo) * (cellW - inset * 2); }
      var xReference = sx(reference);
      var unit = /%/.test(r.paper_text) ? "%" : "";
      [
        { name: "Paper", display: r.paper_value, value: r.paper_value, fill: cssVar("--ink-2") },
        { name: "Ours", display: r.ours_value, value: r.ours_value, fill: color(r.verdict) }
      ].forEach(function (series) {
        var display = series.value === null || series.value === undefined ? "not computed" : String(series.display) + unit;
        y += wrapped(row, 0, y + 13, series.name + ": " + display, cellW, "t-ink").height + 2;
        el("line", { x1: inset, x2: cellW - inset, y1: y + barH / 2, y2: y + barH / 2, class: "grid" }, row);
        if (typeof series.value === "number" && Number.isFinite(series.value)) {
          var xValue = sx(series.value), length = Math.abs(xValue - xReference);
          if (length > 0) bar(row, Math.min(xReference, xValue), y, length, barH, series.value < reference, series.value > reference).setAttribute("fill", series.fill);
          else el("circle", { cx: xReference, cy: y + barH / 2, r: 2, fill: series.fill }, row);
        }
        el("line", { x1: xReference, x2: xReference, y1: y - 2, y2: y + barH + 2, class: "zero" }, row);
        y += barH + 8;
      });
      var referenceLabel = reference === 0 ? "0" : "Reference: " + reference + (reference === 0.5 ? " (parity)" : " (no effect)");
      var referenceText = text(row, xReference, y + 7, referenceLabel, "t-muted", "middle");
      var halfLabel = referenceText.getComputedTextLength() / 2;
      referenceText.setAttribute("x", Math.max(halfLabel, Math.min(cellW - halfLabel, xReference)));
      y += 24;
      bg.setAttribute("height", y - 6);
      hover(row, [r.claim + " · " + r.label, ICON[r.verdict] + " " + r.verdict,
        "Paper " + r.paper_text + ". Ours " + r.ours,
        "Re-run value: " + (r.ours_value === null ? "not computed" : r.ours_value)].concat(r.cause ? ["Audit note: " + r.cause] : []));
      bandHeight = Math.max(bandHeight, y);
      if (column === columns - 1 || index === rows.length - 1) { gridY += bandHeight + 12; bandHeight = 0; }
    });
    resizeSvg(svg, W, Math.max(1, gridY - 12));
  }

  // 4. Each number: distance from the paper's value in last-printed-digit units (symlog).
  function slog(v) { return (v < 0 ? -1 : 1) * Math.log10(1 + Math.abs(v)); }
  function digitsText(v) {
    if (v === null || v === undefined) return "—";
    var a = Math.abs(v), s = a < 10 ? a.toFixed(1) : Math.round(a).toLocaleString("en");
    return (v > 0 ? "+" : v < 0 ? "−" : "") + s;
  }
  function claims(fig) {
    var rows = DATA.rows || [];
    if (fig.dataset.paper) rows = rows.filter(function (r) { return r.paper_id === fig.dataset.paper; });
    if (!rows.length || fig.clientWidth === 0) return;
    if (!fig.querySelector(".legend")) {
      var lg = document.createElement("div");
      lg.className = "legend";
      ORDER.filter(function (v) { return rows.some(function (r) { return r.verdict === v; }); }).forEach(function (v) {
        var s = document.createElement("span"), i = document.createElement("i");
        i.className = "sw"; i.style.background = color(v);
        s.appendChild(i); s.appendChild(document.createTextNode(ICON[v] + " " + v)); lg.appendChild(s);
      });
      var s = document.createElement("span"), i = document.createElement("i");
      i.className = "sw band-key"; s.appendChild(i); s.appendChild(document.createTextNode("Tolerance")); lg.appendChild(s);
      fig.insertBefore(lg, fig.querySelector("figcaption"));
    }
    var W = width(fig), groupH = 24, axisH = 34;
    var multi = !fig.dataset.paper;
    var maxAbs = 10;
    rows.forEach(function (r) {
      if (r.digits !== null) maxAbs = Math.max(maxAbs, Math.abs(r.digits));
      if (r.digits_tol !== null) maxAbs = Math.max(maxAbs, Math.abs(r.digits_tol));
    });
    var top = Math.pow(10, Math.ceil(Math.log10(maxAbs))), lim = slog(top);
    var ticks = [0];
    for (var t = 1; t <= top; t *= 10) { ticks.push(t); ticks.push(-t); }
    var x0 = 8, x1 = W - 8;
    function sx(v) { return x0 + (slog(v) + lim) / (2 * lim) * (x1 - x0); }
    var groups = [];
    rows.forEach(function (r) {
      if (!groups.length || groups[groups.length - 1].paper !== r.paper) groups.push({ paper: r.paper, rows: [] });
      groups[groups.length - 1].rows.push(r);
    });
    var svg = svgFor(fig, W, 1), grid = el("g", {}, svg), narrow = W < 520, y = 0;
    groups.forEach(function (g) {
      if (multi) { text(svg, x0, y + 17, g.paper, "t-ink halo").setAttribute("font-weight", "600"); y += groupH; }
      g.rows.forEach(function (r) {
        var row = el("g", { class: "row" }, svg);
        var bg = el("rect", { x: 0, y: y, width: W, height: 1, class: "rowbg", rx: 6 }, row);
        var label = wrapped(row, x0, y + 14, r.label, W - x0 * 2, "halo");
        var rowH = label.height + 24, cy = y + label.height + 11;
        bg.setAttribute("height", rowH);
        if (r.digits_tol !== null) {
          var tw = Math.abs(r.digits_tol);
          el("rect", { x: sx(-tw), y: cy - 7, width: Math.max(2, sx(tw) - sx(-tw)), height: 14, rx: 4, class: "band" }, row);
        }
        if (r.digits === null) text(row, sx(0) + 8, cy + 4, "– not computed", "t-muted");
        else el("circle", { cx: sx(r.digits), cy: cy, r: 6, class: "dot", fill: color(r.verdict) }, row);
        el("rect", { x: 0, y: y, width: W, height: rowH, class: "hit" }, row);
        hover(row, [ICON[r.verdict] + " " + r.verdict + " · " + r.label, "Paper " + r.paper_text + " · ours " + r.ours,
          "Off by " + digitsText(r.digits) + " in the last printed digit"].concat(r.cause ? ["Audit note: " + r.cause] : []));
        y += rowH;
      });
    });
    ticks.forEach(function (t) {
      el("line", { x1: sx(t), x2: sx(t), y1: 0, y2: y, class: t === 0 ? "zero" : "grid" }, grid);
      if (narrow && Math.abs(t) > 1 && Math.abs(t) < top) return;
      var anchor = t === -top ? "start" : t === top ? "end" : "middle";
      text(svg, sx(t), y + 16, t === 0 ? "0" : (t > 0 ? "+" : "−") + Math.abs(t).toLocaleString("en"), "t-muted", anchor);
    });
    text(svg, x0, y + 30, "← ours lower", "t-muted");
    text(svg, x1, y + 30, "ours higher →", "t-muted", "end");
    resizeSvg(svg, W, y + axisH);
  }

  var RENDER = { verdicts: verdicts, causes: causes, funnel: funnel, claims: claims, comparison: comparison };
  function render(fig) {
    var ancestor = fig.parentElement;
    while (ancestor) {
      if (ancestor.tagName === "DETAILS" && !ancestor.open) return;
      ancestor = ancestor.parentElement;
    }
    if (fig.clientWidth > 0 && RENDER[fig.dataset.chart]) RENDER[fig.dataset.chart](fig);
  }
  function renderAll() {
    hideTip();
    document.querySelectorAll("[data-chart]").forEach(render);
  }
  document.querySelectorAll("details").forEach(function (d) {
    d.addEventListener("toggle", function () {
      if (d.open) d.querySelectorAll("[data-chart]").forEach(render);
      else hideTip();
    });
  });
  var btn = document.querySelector(".theme");
  if (btn) btn.addEventListener("click", function () {
    var root = document.documentElement;
    var dark = root.dataset.theme ? root.dataset.theme === "dark" : matchMedia("(prefers-color-scheme: dark)").matches;
    root.dataset.theme = dark ? "light" : "dark";
    try { localStorage.setItem("theme", root.dataset.theme); } catch (e) {}
    renderAll();
  });
  var timer;
  window.addEventListener("resize", function () { clearTimeout(timer); timer = setTimeout(renderAll, 150); });
  matchMedia("(prefers-color-scheme: dark)").addEventListener("change", renderAll);
  renderAll();
})();
