"""Build the static data-story site from pipeline outputs.

Usage: python scripts/build_site.py

Reads  papers/*/claims.json, report_card.json, outputs/results.json, steps.log
       site/content.json (narrative copy; must not contain literal digits, so every
       number on the site comes from pipeline outputs via {placeholders})
Writes site/index.html, site/papers/<id>.html, site/assets/*
"""

import html
import json
import re
import statistics
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from compare import precision_tolerance  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / "site"
REPO_URL = "https://github.com/SujalPradhan/paper-reproducibility-engine"
VERDICT_ORDER = ["Reproduced", "Partial", "Not reproduced", "Not reproducible"]
VERDICT_ICON = {"Reproduced": "✓", "Partial": "≈", "Not reproduced": "✗", "Not reproducible": "–"}
VERDICT_CLASS = {"Reproduced": "good", "Partial": "warn", "Not reproduced": "bad", "Not reproducible": "na"}

esc = html.escape


def load_papers():
    papers = []
    for d in sorted((ROOT / "papers").iterdir()):
        card_path = d / "report_card.json"
        if not card_path.exists():
            continue
        card = json.loads(card_path.read_text())
        claims = json.loads((d / "claims.json").read_text())
        results_path = d / "outputs" / "results.json"
        results = json.loads(results_path.read_text()) if results_path.exists() else {}
        log = (d / "steps.log").read_text() if (d / "steps.log").exists() else ""
        papers.append({"dir": d.name, "card": card, "claims": claims, "results": results, "log": log})
    order = {pid: i for i, pid in enumerate(CONTENT.get("paper_order", []))}
    papers.sort(key=lambda p: order.get(p["card"]["paper_id"], 99))
    return papers


def chart_rows(papers):
    rows = []
    for p in papers:
        short = CONTENT.get("cases", {}).get(p["card"]["paper_id"], {}).get("short", p["card"]["paper_id"])
        for c in p["card"]["claims"]:
            d = c["details"]
            paper_v = d.get("paper")
            ours = d.get("ours")
            dev = tol = digits = digits_tol = None
            if ours is not None and paper_v not in (None, 0):
                dev = 100 * (ours - paper_v) / abs(paper_v)
                tol = 100 * d["tolerance"] / abs(paper_v)
            if ours is not None and paper_v is not None:
                unit = 2 * precision_tolerance(c["paper_text"])
                digits = (ours - paper_v) / unit
                digits_tol = d["tolerance"] / unit
            rows.append({
                "paper": short,
                "paper_id": p["card"]["paper_id"],
                "claim": c["id"],
                "text": c["text"],
                "verdict": c["verdict"],
                "paper_text": c["paper_text"],
                "ours": fmt_value(ours, c["paper_text"]),
                "dev": dev,
                "tol": tol,
                "digits": digits,
                "digits_tol": digits_tol,
            })
    return rows


def fmt_value(x, ref_text):
    if x is None:
        return "not computed"
    m = re.search(r"\.(\d+)", str(ref_text))
    decimals = len(m.group(1)) if m else 0
    return f"{x:.{decimals + 1}f}"


def stats_for(papers, rows):
    verdicts = [r["verdict"] for r in rows]
    runtimes = [p["results"].get("run", {}).get("runtime_s") for p in papers]
    runtimes = [r for r in runtimes if r is not None]
    screening = CONTENT.get("screening", [])
    s = {
        "n_papers": len(papers),
        "n_claims": len(rows),
        "n_screened": len(screening),
        "n_gated": sum(1 for x in screening if x["stage"] == "passed"),
        "n_on_request": sum(1 for x in screening if x["stage"] == "on_request"),
        "n_tasks": len(list((ROOT / "tasks").glob("*__*/task.json"))),
        "n_papers_reproduced": sum(1 for p in papers if p["card"]["verdict"] == "Reproduced"),
        "n_papers_partial": sum(1 for p in papers if p["card"]["verdict"] == "Partial"),
        "median_runtime_s": round(statistics.median(runtimes)) if runtimes else 0,
    }
    for v in VERDICT_ORDER:
        s["n_" + v.lower().replace(" ", "_")] = verdicts.count(v)
    s["pct_reproduced"] = round(100 * s["n_reproduced"] / len(rows)) if rows else 0
    return s


def fill(text, stats):
    """Fill {placeholders}; copy itself must be digit-free so numbers are traceable."""
    if re.search(r"\d", re.sub(r"\{[a-z_]+\}", "", text)):
        sys.exit(f"build_site: literal digit in narrative copy: {text!r}")
    return text.format(**stats)


def badge(verdict):
    return (f'<span class="badge {VERDICT_CLASS[verdict]}"><span aria-hidden="true">'
            f'{VERDICT_ICON[verdict]}</span> {esc(verdict)}</span>')


def page(title, description, body, depth=0, data=None):
    prefix = "../" * depth
    data_tag = ""
    if data is not None:
        data_tag = ('<script type="application/json" id="page-data">'
                    + json.dumps(data).replace("</", "<\\/") + "</script>")
    nav = "".join(
        f'<a href="{prefix}{href}">{esc(label)}</a>' for label, href in CONTENT_NAV
    )
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{esc(title)}</title>
<meta name="description" content="{esc(description)}">
<link rel="stylesheet" href="{prefix}assets/style.css">
<script>try{{var t=localStorage.getItem("theme");if(t)document.documentElement.dataset.theme=t}}catch(e){{}}</script>
</head>
<body>
<header class="topnav"><nav>{nav}</nav>
<button class="theme" type="button" aria-label="Toggle light or dark theme">◐</button></header>
<main>
{body}
</main>
<footer class="foot">
<p>{esc(CONTENT["footer"])}</p>
<p><a href="{REPO_URL}">Code, data links, logs and audit trail on GitHub</a></p>
</footer>
<div class="tooltip" role="status" hidden></div>
{data_tag}
<script src="{prefix}assets/charts.js"></script>
</body>
</html>
"""


def claim_table(card):
    head = ("<tr><th>Claim</th><th>Paper says</th><th>We got</th><th>Difference</th>"
            "<th>Tolerance</th><th>Verdict</th><th>Notes</th></tr>")
    body = []
    for c in card["claims"]:
        d = c["details"]
        notes = c.get("notes") or d.get("reason", "")
        if c.get("override_reason"):
            notes += f" Auditor override (rule said {c['rule_verdict']}): {c['override_reason']}"
        diff = "—" if d.get("diff") is None else f"{d['diff']:+.{decimals(c['paper_text']) + 1}f}"
        tol = "—" if d.get("tolerance") is None else f"±{d['tolerance']:.{decimals(c['paper_text']) + 1}f}"
        body.append(
            f"<tr><td><b>{esc(c['id'])}</b> {esc(c['text'])}"
            f"<div class=muted>{esc(c.get('location') or '')}</div></td>"
            f"<td class=num>{esc(c['paper_text'])}</td>"
            f"<td class=num>{esc(fmt_value(d.get('ours'), c['paper_text']))}</td>"
            f"<td class=num>{diff}</td><td class=num>{tol}</td>"
            f"<td>{badge(c['verdict'])}</td><td>{esc(notes)}</td></tr>"
        )
    return f'<div class="table-wrap"><table>{head}{"".join(body)}</table></div>'


def decimals(text):
    m = re.search(r"\.(\d+)", str(text))
    return len(m.group(1)) if m else 0


def paper_page(p, prev_p, next_p, stats):
    card, claims, results = p["card"], p["claims"], p["results"]
    pid = card["paper_id"]
    case = CONTENT.get("cases", {}).get(pid, {})
    run = results.get("run", {})
    data = claims.get("data", {})
    code = claims.get("code") or {}
    links = [f'<a href="https://doi.org/{esc(card["doi"])}">Article (doi:{esc(card["doi"])})</a>']
    if data.get("url"):
        links.append(f'<a href="{esc(data["url"])}">Dataset ({esc(data.get("license", "license unknown"))})</a>')
    if code.get("url"):
        links.append(f'<a href="{esc(code["url"])}">Authors\' code</a>')
    links.append(f'<a href="{REPO_URL}/tree/main/papers/{esc(p["dir"])}">Our reproduction files</a>')
    software = ", ".join(f"{k} {v}" for k, v in (run.get("software") or {}).items())
    log_lines = p["log"].strip().splitlines()
    log_excerpt = "\n".join(log_lines[:80]) + ("\n…" if len(log_lines) > 80 else "")
    pager = ['<nav class="pager">']
    if prev_p:
        pager.append(f'<a href="{prev_p["card"]["paper_id"]}.html">← Previous paper</a>')
    pager.append('<a href="../index.html">Overview</a>')
    if next_p:
        pager.append(f'<a href="{next_p["card"]["paper_id"]}.html">Next paper →</a>')
    pager.append("</nav>")
    audit_note = CONTENT.get("audit", {}).get(pid, "")
    code_note = ("We ran the authors' own code first, changing only file paths and plot-only packages."
                 if run.get("used_author_code")
                 else "The authors deposited no code, so we wrote the analysis from the methods section.")
    body = f"""
<section class="hero">
<p class="kicker">{esc(card['journal'])} · {esc(str(claims.get('year', '')))} · {esc(claims.get('article_license', ''))}</p>
<h1>{esc(card['title'])}</h1>
<p class="lead">{esc(fill(case.get('finding', ''), stats))}</p>
<p>{badge(card['verdict'])}</p>
<p class="links">{' · '.join(links)}</p>
</section>
<section>
<h2>Claim by claim</h2>
<figure class="chart" data-chart="deviation" data-paper="{esc(pid)}" aria-label="Deviation of each reproduced value from the paper's value"></figure>
{claim_table(card)}
</section>
<section class="two-col">
<div><h2>What the paper said to do</h2><ol>{''.join(f'<li>{esc(s)}</li>' for s in claims.get('methods_steps', []))}</ol></div>
<div><h2>What the paper left unclear</h2><ul>{''.join(f'<li>{esc(s)}</li>' for s in claims.get('ambiguities', [])) or '<li>Nothing material.</li>'}</ul></div>
</section>
<section>
<h2>How we ran it</h2>
<ul>
<li>{code_note}</li>
<li>Script: <a href="{REPO_URL}/blob/main/papers/{esc(p['dir'])}/{esc(run.get('script', ''))}"><code>{esc(run.get('script', ''))}</code></a>{f' · runtime {run["runtime_s"]} s' if run.get('runtime_s') is not None else ''}</li>
<li>Software: {esc(software) or 'see environment files'}</li>
<li>Claims and tolerances were frozen in git (tag <code>claims-frozen-{esc(pid)}</code>) before any analysis ran.</li>
{f'<li>Independent audit: {esc(audit_note)}</li>' if audit_note else ''}
</ul>
<details><summary>Step log</summary><pre>{esc(log_excerpt)}</pre></details>
</section>
{''.join(pager)}
"""
    page_data = {"rows": [r for r in ROWS if r["paper_id"] == pid]}
    return page(f"{CONTENT.get('cases', {}).get(pid, {}).get('short', pid)} · Reproduction",
                f"Report card for {card['title']}", body, depth=1, data=page_data)


def index_page(papers, stats):
    hero = CONTENT["hero"]
    tiles = "".join(
        f'<div class="tile"><div class="tile-value">{esc(fill(t["value"], stats))}</div>'
        f'<div class="tile-label">{esc(fill(t["label"], stats))}</div></div>'
        for t in hero["tiles"]
    )
    narrative = "".join(f"<p>{fill(x, stats)}</p>" for x in CONTENT["narrative"])
    cards = []
    for p in papers:
        pid = p["card"]["paper_id"]
        case = CONTENT.get("cases", {}).get(pid, {})
        cards.append(
            f'<a class="case" href="papers/{esc(pid)}.html"><span class="case-meta">{esc(p["card"]["journal"])}</span>'
            f'{badge(p["card"]["verdict"])}<b>{esc(case.get("short", pid))}</b>'
            f'<span>{esc(fill(case.get("teaser", case.get("finding", "")), stats))}</span></a>'
        )
    screening_rows = "".join(
        f'<tr><td>{esc(s["title"]) if s["title"] != s["doi"] else ""}<div class=muted>{esc(s.get("journal", ""))} · '
        f'<a href="https://doi.org/{esc(s["doi"])}">{esc(s["doi"])}</a></div></td>'
        f'<td>{esc(STAGE_LABEL[s["stage"]])}</td><td>{esc(s.get("reason", ""))}</td></tr>'
        for s in CONTENT.get("screening", [])
    )
    tools = "".join(
        f'<tr><td><b>{esc(t["tool"])}</b></td><td>{esc(t["role"])}</td>'
        f'<td>{esc(t["decision"])}</td><td>{esc(t["reason"])}</td></tr>'
        for t in CONTENT.get("tools", [])
    )
    methods = "".join(f"<li>{x}</li>" for x in CONTENT.get("methods", []))
    rules = "".join(
        f"<li>{badge(v)} {esc(CONTENT['verdict_rules'][v])}</li>" for v in VERDICT_ORDER
    )
    task = CONTENT.get("task_example")
    task_html = ""
    if task:
        body = (ROOT / task["path"]).read_text() if (ROOT / task["path"]).exists() else ""
        task_html = (f'<section><h2>{esc(task["heading"])}</h2><p>{fill(task["intro"], stats)}</p>'
                     f'<details open><summary>{esc(task["path"])}</summary><pre class="task">{esc(body)}</pre></details></section>')
    footnotes = "".join(f"<li>{x}</li>" for x in CONTENT.get("footnotes", []))
    body = f"""
<section class="hero">
<p class="kicker">{esc(hero['kicker'])}</p>
<h1>{esc(hero['title'])}</h1>
<p class="lead">{fill(hero['lead'], stats)}</p>
<div class="tiles">{tiles}</div>
</section>
<section>
<h2>{esc(CONTENT['chart_heading'])}</h2>
<p class="chart-sub">{esc(CONTENT['chart_sub'])}</p>
<figure class="chart" data-chart="deviation" aria-label="Deviation of every reproduced claim from the paper's value"></figure>
<p class="caption">{fill(CONTENT['chart_caption'], stats)}</p>
<details><summary>Show as a table</summary><div class="table-wrap"><table class="rows-table"></table></div></details>
</section>
<section class="narrative">{narrative}</section>
<section>
<h2>The papers</h2>
<div class="cases">{''.join(cards)}</div>
</section>
<section>
<h2>{esc(CONTENT['screening_heading'])}</h2>
<figure class="chart" data-chart="screening" aria-label="Papers screened, passed the gate and reproduced"></figure>
<details><summary>Every paper we screened and why it was kept or dropped</summary>
<div class="table-wrap"><table><tr><th>Paper</th><th>Outcome</th><th>Reason</th></tr>{screening_rows}</table></div></details>
</section>
<section>
<h2>Methods and evidence</h2>
<ol class="methods">{methods}</ol>
<h3>Verdict rules (fixed before any reproduction ran)</h3>
<ul class="rules">{rules}</ul>
</section>
<section>
<h2>What we reused and what we built</h2>
<div class="table-wrap"><table><tr><th>Tool</th><th>Role</th><th>Decision</th><th>Why</th></tr>{tools}</table></div>
</section>
{task_html}
<section class="footnotes"><h2>Notes</h2><ol>{footnotes}</ol></section>
"""
    screening = {
        "stages": [
            {"label": "Screened", "n": stats["n_screened"]},
            {"label": "Passed license and data gate", "n": stats["n_gated"]},
            {"label": "Reproduced in full or in part", "n": stats["n_papers_reproduced"] + stats["n_papers_partial"]},
        ]
    }
    return page(CONTENT["page_title"], CONTENT["description"], body, data={"rows": ROWS, "screening": screening})


STAGE_LABEL = {"passed": "Passed gate", "on_request": "Flagged: data on request", "rejected": "Dropped"}

if __name__ == "__main__":
    CONTENT = json.loads((SITE / "content.json").read_text())
    CONTENT["screening"] = json.loads((SITE / "screening.json").read_text())
    CONTENT_NAV = [("Overview", "index.html")] + [
        (CONTENT["cases"][pid]["short"], f"papers/{pid}.html") for pid in CONTENT.get("paper_order", [])
        if (ROOT / "papers" / pid / "report_card.json").exists()
    ]
    papers = load_papers()
    ROWS = chart_rows(papers)
    stats = stats_for(papers, ROWS)
    (SITE / "papers").mkdir(parents=True, exist_ok=True)
    (SITE / "index.html").write_text(index_page(papers, stats))
    for i, p in enumerate(papers):
        prev_p = papers[i - 1] if i > 0 else None
        next_p = papers[i + 1] if i + 1 < len(papers) else None
        (SITE / "papers" / f"{p['card']['paper_id']}.html").write_text(paper_page(p, prev_p, next_p, stats))
    (SITE / "stats.json").write_text(json.dumps(stats, indent=2) + "\n")
    print(json.dumps(stats, indent=2))
