"""Build the static data-story site from pipeline outputs.

Usage: python scripts/build_site.py

Reads  papers/*/claims.json, report_card.json, outputs/results.json, steps.log, audit.json
       site/content.json (copy; narrative strings must not contain literal digits, so every
       number on the site comes from pipeline outputs via {placeholders})
       site/screening.json (from scripts/extract_screening.py)
Writes site/index.html, site/papers/<id>.html, site/stats.json
"""

import html
import json
import re
import statistics
import sys
from decimal import Decimal
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from compare import null_value, number_text, precision_tolerance  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / "site"
REPO_URL = "https://github.com/SujalPradhan/paper-reproducibility-engine"
VERDICTS = ["Reproduced", "Partial", "Not reproduced", "Not reproducible"]
ICON = {"Reproduced": "✓", "Partial": "≈", "Not reproduced": "✗", "Not reproducible": "–"}
CLS = {"Reproduced": "good", "Partial": "warn", "Not reproduced": "bad", "Not reproducible": "na"}
STAGE_LABEL = {"passed": "Passed gate", "on_request": "Data on request", "rejected": "Dropped"}

esc = html.escape


def load_papers(content):
    papers = []
    configured = content["paper_order"]
    available = {p.parent.name for p in (ROOT / "papers").glob("*/report_card.json")}
    if len(configured) != len(set(configured)) or set(configured) != available:
        sys.exit("build_site: paper_order must include every report card exactly once")
    for pid in content["paper_order"]:
        d = ROOT / "papers" / pid
        results = d / "outputs" / "results.json"
        audit = d / "audit.json"
        papers.append({
            "id": pid,
            "card": json.loads((d / "report_card.json").read_text()),
            "claims": json.loads((d / "claims.json").read_text()),
            "results": json.loads(results.read_text()) if results.exists() else {},
            "log": (d / "steps.log").read_text() if (d / "steps.log").exists() else "",
            "overrides": json.loads(audit.read_text()).get("overrides", []) if audit.exists() else [],
            "audited": (d / "audit.md").exists(),
        })
    return papers


def decimals(text):
    return max(0, -Decimal(number_text(text)).as_tuple().exponent)


def fmt_value(x, ref_text):
    return "not computed" if x is None else f"{x:.{decimals(ref_text) + 1}f}"


def claim_rows(papers, content):
    rows = []
    for p in papers:
        short = content["cases"][p["id"]]["short"]
        frozen_claims = {c["id"]: c for c in p["claims"]["claims"]}
        for c in p["card"]["claims"]:
            key = f"{p['id']}/{c['id']}"
            d = c["details"]
            paper_v, ours = d.get("paper"), d.get("ours")
            digits = digits_tol = None
            if ours is not None and paper_v is not None:
                unit = 2 * precision_tolerance(c["paper_text"])
                digits = (ours - paper_v) / unit
                digits_tol = d["tolerance"] / unit
            cause = content["causes"].get(key)
            if c["verdict"] != "Reproduced" and cause not in content["cause_labels"]:
                sys.exit(f"build_site: no cause assigned for missed claim {key}")
            rows.append({
                "paper": short,
                "paper_id": p["id"],
                "claim": c["id"],
                "label": content["claim_labels"].get(key, c["text"]),
                "text": c["text"],
                "verdict": c["verdict"],
                "paper_text": c["paper_text"],
                "ours": fmt_value(ours, c["paper_text"]),
                "paper_value": paper_v,
                "ours_value": ours,
                "tolerance": d.get("tolerance"),
                "reference_value": null_value(frozen_claims[c["id"]]),
                "digits": digits,
                "digits_tol": digits_tol,
                "cause": content["cause_labels"].get(cause) if c["verdict"] != "Reproduced" else None,
                "cause_key": cause if c["verdict"] != "Reproduced" else None,
            })
    return rows


def compute_stats(papers, rows, screening):
    verdicts = [r["verdict"] for r in rows]
    runtimes = [p["results"].get("run", {}).get("runtime_s") for p in papers]
    runtimes = [runtime for runtime in runtimes if runtime is not None]
    s = {
        "n_papers": len(papers),
        "n_claims": len(rows),
        "n_screened": len(screening),
        "n_gated": sum(1 for x in screening if x["stage"] == "passed"),
        "n_on_request": sum(1 for x in screening if x["stage"] == "on_request"),
        "n_tasks": len(list((ROOT / "tasks").glob("*__*/task.json"))),
        "n_papers_reproduced": sum(1 for p in papers if p["card"]["verdict"] == "Reproduced"),
        "n_papers_partial": sum(1 for p in papers if p["card"]["verdict"] == "Partial"),
        "n_audit_overrides": sum(len(p["overrides"]) for p in papers),
        "n_audited": sum(1 for p in papers if p["audited"]),
        "median_runtime_s": round(statistics.median(runtimes)) if runtimes else 0,
    }
    for v in VERDICTS:
        s["n_" + v.lower().replace(" ", "_")] = verdicts.count(v)
    s["n_close"] = s["n_reproduced"] + s["n_partial"]
    s["pct_reproduced"] = round(100 * s["n_reproduced"] / len(rows)) if rows else 0
    s["n_misses"] = sum(1 for r in rows if r["verdict"] != "Reproduced")
    s["n_misses_explained"] = sum(1 for r in rows if r["cause"] and r["cause_key"] != "unexplained")
    return s


def fill(text, stats):
    """Fill {placeholders}; the copy itself must be digit-free so numbers are traceable."""
    if re.search(r"\d", re.sub(r"\{[a-z_]+\}", "", text)):
        sys.exit(f"build_site: literal digit in narrative copy: {text!r}")
    return text.format(**stats)


def badge(verdict):
    return (f'<span class="badge {CLS[verdict]}"><span aria-hidden="true">{ICON[verdict]}</span> '
            f"{esc(verdict)}</span>")


def page(content, title, description, body, depth=0, data=None):
    prefix = "../" * depth
    data_tag = ""
    if data is not None:
        data_tag = ('<script type="application/json" id="page-data">'
                    + json.dumps(data, ensure_ascii=False).replace("</", "<\\/") + "</script>")
    current = ' aria-current="page"'
    nav = f'<a href="{prefix}index.html"{current if depth == 0 else ""}>Overview</a>'
    for pid in content["paper_order"]:
        short = content["cases"][pid]["short"]
        active = current if depth and title.startswith(short) else ""
        nav += f'<a href="{prefix}papers/{pid}.html"{active}>{esc(short)}</a>'
    return f"""<!doctype html>
<html lang="en" class="no-js">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{esc(title)}</title>
<meta name="description" content="{esc(description)}">
<link rel="stylesheet" href="{prefix}assets/style.css">
<script>document.documentElement.classList.remove("no-js");try{{var t=localStorage.getItem("theme");if(t)document.documentElement.dataset.theme=t}}catch(e){{}}</script>
</head>
<body>
<a class="skip" href="#main">Skip to content</a>
<header class="topnav"><nav aria-label="Main">{nav}</nav>
<button class="theme" type="button" aria-label="Toggle light or dark theme">◐</button></header>
<main id="main">
{body}
</main>
<footer class="foot">
<p>{esc(content["footer"])}</p>
<p><a href="{REPO_URL}">Code, data links, logs and audits on GitHub</a></p>
</footer>
<div class="tooltip" role="status" hidden></div>
{data_tag}
<script src="{prefix}assets/charts.js"></script>
</body>
</html>
"""


def section_head(content, key, stats):
    s = content["sections"][key]
    sub = f'<p class="sub">{esc(fill(s["sub"], stats))}</p>' if s.get("sub") else ""
    return f'<h2>{esc(fill(s["h"], stats))}</h2>{sub}'


def legend_html():
    return '<div class="legend">' + "".join(
        f'<span><i class="sw {CLS[v]}"></i>{ICON[v]} {esc(v)}</span>' for v in VERDICTS[:3]
    ) + "</div>"


def outcome_strip(claims):
    """A source-derived chart that also works without JavaScript."""
    return '<div class="outcome-strip" aria-hidden="true">' + "".join(
        f'<span class="{CLS[v]}" style="flex:{n}"></span>'
        for v in VERDICTS
        if (n := sum(c["verdict"] == v for c in claims))
    ) + "</div>"


def index_page(content, papers, rows, stats, screening):
    hero = content["hero"]
    tiles = "".join(
        f'<div class="outcome {CLS[t["verdict"]]}"><div class="tile-value">{esc(fill(t["value"], stats))}'
        f'<span aria-hidden="true">{ICON[t["verdict"]]}</span></div>'
        f'<b>{esc(t["verdict"])}</b><div class="tile-label">{esc(t["label"])}</div></div>'
        for t in hero["tiles"]
    )
    steps = "".join(
        f'<li><span class="step-n" aria-hidden="true"></span><b>{esc(s["t"])}</b><span>{esc(s["d"])}</span></li>'
        for s in content["steps"]
    )
    who = "".join(
        f'<div class="tile"><div class="tile-label strong">{esc(w["label"])}</div>'
        f'<div class="tile-value">{esc(fill(w["value"], stats))}</div>'
        f'<div class="tile-label">{esc(fill(w["d"], stats))}</div></div>'
        for w in content["who"]
    )
    cards = "".join(
        f'<a class="case" href="papers/{esc(p["id"])}.html">'
        f'<span class="case-meta">{esc(p["card"]["journal"])}</span>'
        f'<b>{esc(content["cases"][p["id"]]["short"])}</b>{badge(p["card"]["verdict"])}'
        f'<span>{esc(fill(content["cases"][p["id"]]["finding"], stats))}</span>'
        f'<span class="case-link">See claims and evidence →</span></a>'
        for p in papers
    )
    rules = "".join(f"<li>{badge(v)} {esc(content['verdict_rules'][v])}</li>" for v in VERDICTS)
    screening_rows = "".join(
        f'<tr><td>{esc(s["title"]) + "<br>" if s["title"] != s["doi"] else ""}'
        f'<span class=muted>{esc(s.get("journal", ""))} · <a href="https://doi.org/{esc(s["doi"])}">{esc(s["doi"])}</a></span></td>'
        f'<td>{esc(STAGE_LABEL[s["stage"]])}</td><td>{esc(s.get("reason", ""))}</td></tr>'
        for s in screening
    )
    notes = "".join(f"<li>{esc(fill(n, stats))}</li>" for n in content["notes"])
    paper_chart_text = "".join(
        f'<li>{esc(content["cases"][p["id"]]["short"])}: ' + " · ".join(
            f'{sum(c["verdict"] == v for c in p["card"]["claims"])} {v.lower()}'
            for v in VERDICTS if any(c["verdict"] == v for c in p["card"]["claims"])
        ) + "</li>" for p in papers
    )
    audit_chart_text = "".join(
        f'<li>{esc(label)}: {sum(r["cause_key"] == key for r in rows)}</li>'
        for key, label in content["cause_labels"].items() if any(r["cause_key"] == key for r in rows)
    )
    body = f"""
<section class="hero">
<p class="kicker">{esc(hero['kicker'])}</p>
<h1>{esc(hero['title'])}</h1>
<p class="lead">{esc(fill(hero['lead'], stats))}</p>
<div class="outcomes" aria-label="Claim results">{tiles}</div>
{outcome_strip([c for p in papers for c in p['card']['claims']])}
<p class="scope">{esc(hero['scope'])}</p>
<div class="jump-links"><a href="#results">Compare papers ↓</a><a href="#method">How we checked ↓</a></div>
</section>

<div class="analysis-grid" id="results">
<section class="panel">
{section_head(content, "verdicts", stats)}
<figure class="chart" data-chart="verdicts" aria-label="Claim verdicts for each paper">{legend_html()}
<ul class="chart-text">{paper_chart_text}</ul>
<figcaption>Each block is a claim. {stats['n_papers_reproduced']} paper fully reproduced; {stats['n_papers_partial']} partly reproduced.</figcaption></figure>
<details class="more"><summary>What the verdicts mean</summary><ul class="rules">{rules}</ul></details>
</section>

<section class="panel">
{section_head(content, "causes", stats)}
<figure class="chart" data-chart="causes" aria-label="Audit observations for non-matching claims">
<ul class="chart-text">{audit_chart_text}</ul>
<figcaption>One audit category per claim. These observations do not establish causation.</figcaption></figure>
</section>
</div>

<section class="paper-section" id="papers">
{section_head(content, "papers", stats)}
<div class="cases">{cards}</div>
</section>

<section class="method-section" id="method">
{section_head(content, "how", stats)}
<ol class="pipeline">{steps}</ol>
<p class="audit-note">{stats['n_audited']} independent agent audits · {stats['n_audit_overrides']} verdict overrides · <a href="{REPO_URL}/blob/main/audit.md">Read the audit</a></p>
<details class="more method-details" data-render-on-open><summary>Paper selection and screening records</summary>
<div class="selection-grid"><div>
{section_head(content, "funnel", stats)}
<figure class="chart" data-chart="funnel" aria-label="Papers screened, passed the gate, selected and audited">
<figcaption>{stats['n_screened']} screened → {stats['n_gated']} passed → {stats['n_papers']} selected and audited.</figcaption></figure>
</div><p class="selection-note">{stats['n_on_request']} papers offered data only on request. Selection also considered size and complexity; this pilot does not measure a journal’s reproducibility rate.</p></div>
<details class="more"><summary>All screened papers and why</summary>
<div class="table-wrap"><table><caption>Screening decisions</caption><thead><tr><th scope="col">Paper</th><th scope="col">Outcome</th><th scope="col">Reason</th></tr></thead><tbody>{screening_rows}</tbody></table></div></details>
</details>
<details class="more" data-render-on-open>
<summary>Compare all {stats['n_claims']} claims in detail</summary>
<p class="sub">{esc(fill(content["sections"]["claims"]["sub"], stats))}</p>
<figure class="chart" data-chart="claims" aria-label="Every claim's distance from the paper's value"><figcaption>Signed logarithmic scale in last-printed-digit units; bands show frozen tolerances. Use the paper reports for original values.</figcaption></figure>
</details>
<details class="more"><summary>Scope and limitations</summary><ul class="notes">{notes}</ul></details>
</section>

<section class="value-section">
{section_head(content, "who", stats)}
<div class="tiles">{who}</div>
<p class="sub"><a href="{REPO_URL}/blob/main/tasks.md">How the AI-lab tasks are built</a> · <a href="{REPO_URL}/tree/main/tasks">Browse all tasks</a></p>
</section>
"""
    paper_data = [{
        "id": p["id"],
        "short": content["cases"][p["id"]]["short"],
        "verdict": p["card"]["verdict"],
        "counts": {v: sum(1 for c in p["card"]["claims"] if c["verdict"] == v) for v in VERDICTS},
        "labels": [{"v": c["verdict"], "l": content["claim_labels"].get(f"{p['id']}/{c['id']}", c["text"])}
                   for c in sorted(p["card"]["claims"], key=lambda c: VERDICTS.index(c["verdict"]))],
    } for p in papers]
    cause_counts = {}
    for r in rows:
        if r["cause"]:
            cause_counts.setdefault(r["cause_key"], []).append(f"{r['paper']}: {r['label']}")
    causes = sorted(({"key": k, "label": content["cause_labels"][k], "n": len(v), "claims": v}
                     for k, v in cause_counts.items()),
                    key=lambda c: (c["key"] == "unexplained", -c["n"]))  # unexplained last, like "Other"
    funnel = [
        {"label": "Screened", "n": stats["n_screened"]},
        {"label": "Passed licence and data gate", "n": stats["n_gated"]},
        {"label": "Selected and audited", "n": stats["n_papers"]},
    ]
    data = {"rows": rows, "papers": paper_data, "causes": causes, "funnel": funnel}
    return page(content, content["page_title"], content["description"], body, data=data)


def paper_page(content, p, prev_p, next_p, rows, stats):
    card, claims, run = p["card"], p["claims"], p["results"].get("run", {})
    pid = p["id"]
    case = content["cases"][pid]
    data, code = claims.get("data", {}), claims.get("code") or {}
    links = [f'<a href="https://doi.org/{esc(card["doi"])}">Article</a>']
    if data.get("url"):
        links.append(f'<a href="{esc(data["url"])}">Data ({esc(data.get("license", "licence unknown"))})</a>')
    if code.get("url"):
        links.append(f'<a href="{esc(code["url"])}">Authors\' code</a>')
    links.append(f'<a href="{REPO_URL}/tree/main/papers/{esc(pid)}">Our files</a>')
    links.append(f'<a href="{REPO_URL}/blob/main/papers/{esc(pid)}/audit.md">Audit report</a>')

    claim_by_id = {c["id"]: c for c in card["claims"]}
    paper_rows = [r for r in rows if r["paper_id"] == pid]
    table = "".join(
        f'<tr><th scope="row"><b>{esc(r["label"])}</b><div class="muted">{esc(r["claim"])}</div></th>'
        f'<td class="num">{esc(r["paper_text"])}</td><td class="num">{esc(str(r["ours_value"])) if r["ours_value"] is not None else "not computed"}</td>'
        f'<td class="num">{("±" + esc(str(r["tolerance"]))) if r["tolerance"] is not None else "—"}</td>'
        f'<td>{badge(r["verdict"])}</td>'
        f'<td>{esc(claim_by_id[r["claim"]].get("notes") or claim_by_id[r["claim"]]["details"].get("reason", ""))}'
        f'<div class="muted">{esc(claim_by_id[r["claim"]].get("location") or "")}</div></td></tr>'
        for r in paper_rows
    )
    counts = " · ".join(
        f'{sum(r["verdict"] == v for r in paper_rows)} {v.lower()}'
        for v in VERDICTS if any(r["verdict"] == v for r in paper_rows)
    )
    code_note = ("Authors' analysis retained; plotting and parallel execution adapted."
                 if run.get("used_author_code") else "No authors' code; one script written from the methods.")
    software = ", ".join(f"{k} {v}" for k, v in (run.get("software") or {}).items())
    log_lines = p["log"].strip().splitlines()
    log = "\n".join(log_lines[:80]) + ("\n…" if len(log_lines) > 80 else "")
    li = lambda xs: "".join(f"<li>{esc(x)}</li>" for x in xs)  # noqa: E731
    pager = '<nav class="pager">'
    pager += f'<a href="{prev_p["id"]}.html">← {esc(content["cases"][prev_p["id"]]["short"])}</a>' if prev_p else "<span></span>"
    pager += f'<a href="{next_p["id"]}.html">{esc(content["cases"][next_p["id"]]["short"])} →</a>' if next_p else "<span></span>"
    pager += "</nav>"
    body = f"""
<section class="hero">
<p class="kicker">{esc(card['journal'])} · {esc(str(claims.get('year', '')))} · {esc(claims.get('article_license', ''))}</p>
<h1>{esc(case['short'])}</h1>
<p class="paper-title">{esc(card['title'])}</p>
<p>{badge(card['verdict'])}</p>
<p class="lead">{esc(fill(case['finding'], stats))}</p>
{outcome_strip(card['claims'])}
<p class="claim-counts">{counts}</p>
<p class="links">{' · '.join(links)}</p>
</section>
<section>
<h2>Paper vs re-run</h2>
<p class="sub">Each claim uses its own scale and original units. Bars start at zero, or the no-effect value for ratios and proportions. Verdicts use the frozen tolerances.</p>
<figure class="chart comparison" data-chart="comparison" data-paper="{esc(pid)}" aria-label="Original paper values compared with re-run values">
<figcaption>{len(paper_rows)} claims compared. Full values, tolerances and notes are available below.</figcaption></figure>
<details class="more"><summary>What the audit found</summary><p>{esc(case['evidence'])}</p></details>
<details class="more evidence"><summary>Full values, tolerances and evidence</summary>
<div class="table-wrap"><table><caption>Unrounded re-run values and original printed claims</caption><thead><tr><th scope="col">Claim</th><th scope="col">Paper</th><th scope="col">Re-run</th><th scope="col">Tolerance</th><th scope="col">Verdict</th><th scope="col">Evidence</th></tr></thead><tbody>{table}</tbody></table></div></details>
<details class="more" data-render-on-open><summary>Inspect differences at printed precision</summary>
<p class="sub">Distance from the paper’s value in last-printed-digit units. The signed logarithmic scale compresses large differences; bands show the frozen tolerances.</p>
<figure class="chart" data-chart="claims" data-paper="{esc(pid)}" aria-label="Claim differences in last-printed-digit units"></figure></details>
</section>
<section>
<h2>Checks</h2>
<ul class="checks">
<li><b>Frozen first.</b> Numbers and tolerances tagged <code>claims-frozen-{esc(pid)}</code> before any analysis.</li>
<li><b>Re-run.</b> {esc(code_note)} {f'Runtime {run["runtime_s"]:.0f} s.' if run.get('runtime_s') is not None else ''}</li>
<li><b>Audited.</b> {esc(content['audit'].get(pid, ''))}</li>
</ul>
<details class="more"><summary>What the paper says to do</summary><ol>{li(claims.get('methods_steps', []))}</ol></details>
<details class="more"><summary>What the paper leaves unclear</summary><ul>{li(claims.get('ambiguities', []))}</ul></details>
<details class="more"><summary>Software</summary><p class="sub">{esc(software)}</p></details>
<details class="more"><summary>Step log</summary><pre>{esc(log)}</pre></details>
</section>
{pager}
"""
    return page(content, f"{case['short']} · Reproduction", f"Report card for {card['title']}", body,
                depth=1, data={"rows": paper_rows})


def main():
    content = json.loads((SITE / "content.json").read_text())
    screening = json.loads((SITE / "screening.json").read_text())
    papers = load_papers(content)
    rows = claim_rows(papers, content)
    stats = compute_stats(papers, rows, screening)
    (SITE / "papers").mkdir(parents=True, exist_ok=True)
    (SITE / "index.html").write_text(index_page(content, papers, rows, stats, screening))
    for i, p in enumerate(papers):
        prev_p = papers[i - 1] if i > 0 else None
        next_p = papers[i + 1] if i + 1 < len(papers) else None
        (SITE / "papers" / f"{p['id']}.html").write_text(paper_page(content, p, prev_p, next_p, rows, stats))
    (SITE / "stats.json").write_text(json.dumps(stats, indent=2) + "\n")
    print(json.dumps(stats, indent=2))


if __name__ == "__main__":
    main()
