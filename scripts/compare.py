"""Compare reproduced values against a paper's pre-registered claims.

Usage: python scripts/compare.py papers/<paper-id>

Reads   papers/<id>/claims.json   (frozen before reproduction; see CLAIMS_SCHEMA.md)
        papers/<id>/outputs/results.json   (written by the reproduction script)
        papers/<id>/audit.json   (optional auditor overrides, each with a reason)
Writes  papers/<id>/report_card.json and papers/<id>/report_card.md

Verdict rules (fixed before any reproduction ran):
  Reproduced        |ours - paper| <= tolerance. Tolerance is the pre-registered one
                    if given, else half a unit of the last digit the paper reported.
  Partial           outside tolerance, but same direction (side of the null value: 1 for
                    ratios, 0 otherwise, or claims' null_value), same significance
                    conclusion where both p-values are known, and relative deviation
                    <= partial_rel (default 0.5, pre-registered per claim if changed).
  Not reproduced    anything else that was computed.
  Not reproducible  the value could not be computed (data or method detail missing,
                    or the time box ran out); a reason is required.
"""

import json
import math
import re
import sys
from decimal import Decimal
from pathlib import Path

REPRODUCED = "Reproduced"
PARTIAL = "Partial"
NOT_REPRODUCED = "Not reproduced"
NOT_REPRODUCIBLE = "Not reproducible"
VERDICTS = (REPRODUCED, PARTIAL, NOT_REPRODUCED, NOT_REPRODUCIBLE)


NUMBER = re.compile(r"[-+]?(?:\d[\d,]*)?\.?\d+")


def number_text(reported_text):
    """The leading number as printed: 'N = 12,437' -> '12437', '−0.06 (CI95 …)' -> '-0.06'."""
    text = str(reported_text).replace("−", "-").replace("–", "-")
    match = NUMBER.search(text)
    if not match:
        raise ValueError(f"no number in reported text {reported_text!r}")
    return match.group(0).replace(",", "").lstrip("+")


def precision_tolerance(reported_text):
    """Half a unit of the last reported digit: '0.42' -> 0.005, '12' -> 0.5."""
    exponent = Decimal(number_text(reported_text)).as_tuple().exponent
    return 0.5 * 10.0 ** exponent


def tolerance_for(claim):
    tol = claim.get("tolerance") or {}
    reported = claim["reported"]
    kind = tol.get("type", "reported_precision")
    if kind == "abs":
        return float(tol["value"])
    if kind == "rel":
        return abs(float(reported["value"])) * float(tol["value"])
    return precision_tolerance(reported.get("text", reported["value"]))


RATIO_WORDS = ("ratio", "exp(b)", "odds", "hazard")


def null_value(claim):
    """The no-effect value that 'direction' is measured from: explicit, else 1 for ratios, else 0."""
    if claim.get("null_value") is not None:
        return float(claim["null_value"])
    statistic = f"{claim.get('statistic', '')} {claim.get('units', '')}".lower()
    return 1.0 if any(w in statistic for w in RATIO_WORDS) else 0.0


def significant(p, alpha):
    if p is None:
        return None
    if isinstance(p, str):  # "<0.001", ">0.05", "0.03"
        s = p.strip().replace(" ", "")
        if s.startswith("<"):
            return float(s[1:]) <= alpha
        if s.startswith(">"):
            return not float(s[1:]) < alpha
        p = float(s)
    return float(p) < alpha


def judge(claim, result):
    """Return (verdict, details dict) for one claim."""
    if result is None or result.get("status") != "ok" or result.get("value") is None:
        reason = (result or {}).get("reason") or "No value produced"
        return NOT_REPRODUCIBLE, {"reason": reason}

    paper = float(claim["reported"]["value"])
    ours = float(result["value"])
    diff = ours - paper
    tol = tolerance_for(claim)
    rel = abs(diff) / abs(paper) if paper != 0 else math.inf
    details = {"paper": paper, "ours": ours, "diff": diff, "tolerance": tol, "rel_diff": rel}

    if abs(diff) <= tol + 1e-12:
        return REPRODUCED, details

    alpha = claim.get("significance", {}).get("alpha", 0.05)
    sig_paper = significant(claim["reported"].get("p"), alpha)
    sig_ours = significant(result.get("p"), alpha)
    same_sig = sig_paper is None or sig_ours is None or sig_paper == sig_ours
    null = null_value(claim)
    same_sign = (paper >= null) == (ours >= null) or paper == null
    partial_rel = float((claim.get("tolerance") or {}).get("partial_rel", 0.5))
    details.update({"same_sign": same_sign, "same_significance": same_sig})

    if same_sign and same_sig and rel <= partial_rel:
        return PARTIAL, details
    return NOT_REPRODUCED, details


def paper_verdict(verdicts):
    vs = set(verdicts)
    if not vs:
        return NOT_REPRODUCIBLE
    if vs == {REPRODUCED}:
        return REPRODUCED
    if vs == {NOT_REPRODUCIBLE}:
        return NOT_REPRODUCIBLE
    if REPRODUCED in vs or PARTIAL in vs:
        return PARTIAL
    return NOT_REPRODUCED


def fmt(x, ref_text=None):
    if x is None:
        return "—"
    if isinstance(x, float) and math.isinf(x):
        return "∞"
    if ref_text is not None:
        try:
            decimals = max(0, -Decimal(number_text(ref_text)).as_tuple().exponent)
            return f"{x:.{decimals + 2}f}"
        except Exception:
            pass
    return f"{x:.4g}"


def compare(paper_dir):
    paper_dir = Path(paper_dir)
    claims = json.loads((paper_dir / "claims.json").read_text())
    results_path = paper_dir / "outputs" / "results.json"
    results = json.loads(results_path.read_text()) if results_path.exists() else {"claims": []}
    by_id = {r["id"]: r for r in results.get("claims", [])}
    audit_path = paper_dir / "audit.json"
    overrides = {}
    if audit_path.exists():
        for o in json.loads(audit_path.read_text()).get("overrides", []):
            assert o.get("verdict") in VERDICTS and o.get("reason"), f"bad override {o}"
            overrides[o["claim"]] = o

    rows = []
    for claim in claims["claims"]:
        result = by_id.get(claim["id"])
        verdict, details = judge(claim, result)
        row = {
            "id": claim["id"],
            "text": claim["text"],
            "statistic": claim.get("statistic"),
            "location": claim.get("location"),
            "paper_text": claim["reported"].get("text", str(claim["reported"]["value"])),
            "rule_verdict": verdict,
            "verdict": verdict,
            "details": details,
            "notes": (result or {}).get("notes", ""),
        }
        if claim["id"] in overrides:
            row["verdict"] = overrides[claim["id"]]["verdict"]
            row["override_reason"] = overrides[claim["id"]]["reason"]
        rows.append(row)

    card = {
        "paper_id": claims["paper_id"],
        "title": claims.get("title"),
        "doi": claims.get("doi"),
        "journal": claims.get("journal"),
        "verdict": paper_verdict([r["verdict"] for r in rows]),
        "claims": rows,
        "run": results.get("run", {}),
    }
    (paper_dir / "report_card.json").write_text(json.dumps(card, indent=2) + "\n")
    (paper_dir / "report_card.md").write_text(render_md(card))
    return card


def render_md(card):
    lines = [
        f"# Report card: {card['title']}",
        "",
        f"- DOI: https://doi.org/{card['doi']}",
        f"- Journal: {card['journal']}",
        f"- **Overall verdict: {card['verdict']}**",
        "- Verdicts are computed by `scripts/compare.py` against tolerances frozen in `claims.json` before reproduction.",
        "",
        "| Claim | Paper says | We got | Difference | Tolerance | Verdict | Notes |",
        "|---|---|---|---|---|---|---|",
    ]
    for r in card["claims"]:
        d = r["details"]
        verdict = r["verdict"]
        if r.get("override_reason"):
            verdict += f" (auditor override; rule said {r['rule_verdict']})"
        notes = r["notes"] or d.get("reason", "")
        if r.get("override_reason"):
            notes = f"{notes} Auditor: {r['override_reason']}".strip()
        lines.append(
            "| {id}: {text} ({loc}) | {paper} | {ours} | {diff} | ±{tol} | {verdict} | {notes} |".format(
                id=r["id"],
                text=r["text"].replace("|", "/"),
                loc=r.get("location") or "",
                paper=r["paper_text"],
                ours=fmt(d.get("ours"), r["paper_text"]),
                diff=fmt(d.get("diff"), r["paper_text"]),
                tol=fmt(d.get("tolerance")),
                verdict=verdict,
                notes=str(notes).replace("|", "/").replace("\n", " "),
            )
        )
    return "\n".join(lines) + "\n"


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    card = compare(sys.argv[1])
    print(f"{card['paper_id']}: {card['verdict']}")
    for r in card["claims"]:
        print(f"  {r['id']}: {r['verdict']}")
