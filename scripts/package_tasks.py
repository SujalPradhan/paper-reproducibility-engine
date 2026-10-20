"""Package audited claims as evaluation tasks for AI labs.

Usage: python scripts/package_tasks.py

Each computed claim of an audited paper becomes tasks/<paper-id>__<claim-id>/ with:
  task.json    CORE-Bench task object (MIT, siegelz/core-bench) plus our extension fields
  rubric.json  PaperBench-style TaskNode tree (MIT, openai/frontier-evals)
  inputs.json  data manifest: source URLs and SHA-256 (data is fetched, not redistributed)
  addendum.md  clarifications drawn from the frozen claims.json

The expected answer is the independently re-run value (audit runs), not the paper's
printed value. Where the two disagree the task says so (ground_truth_basis).
"""

import hashlib
import json
import shutil
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TASKS = ROOT / "tasks"
NAMESPACE = uuid.UUID("6f1d2c1e-9a57-4f0b-9a52-3d1f4f6e8b10")
FIELD = {"Cancer Medicine": "Medical Sciences", "Health Science Reports": "Medical Sciences"}


def node(key, requirements, weight=1, sub_tasks=(), category=None, fine=None):
    return {
        "id": str(uuid.uuid5(NAMESPACE, key)),
        "requirements": requirements,
        "weight": weight,
        "sub_tasks": list(sub_tasks),
        "task_category": category,
        "finegrained_task_category": fine,
    }


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def audit_runs(paper_dir, claim_id):
    runs = []
    for f in sorted((paper_dir / "audit").glob("results_run*.json")):
        for c in json.loads(f.read_text())["claims"]:
            if c["id"] == claim_id and c.get("status") == "ok":
                runs.append(c["value"])
    return runs


def question(claim):
    unit = f" ({claim['units']})" if claim.get("units") else ""
    return f"Report {claim['text'].rstrip('.')}{unit}, as in {claim['location']}."


def package(paper_dir):
    claims = json.loads((paper_dir / "claims.json").read_text())
    card = json.loads((paper_dir / "report_card.json").read_text())
    rows = {r["id"]: r for r in card["claims"]}
    pid = claims["paper_id"]
    language = (claims.get("code") or {}).get("language") or "R"
    data_files = [p for p in sorted((paper_dir / "data").iterdir()) if p.name != "README.md"]
    manifest = {
        "dataset": claims["data"],
        "files": [{"name": p.name, "sha256": sha256(p), "bytes": p.stat().st_size} for p in data_files],
    }
    made = []
    for claim in claims["claims"]:
        row = rows[claim["id"]]
        runs = audit_runs(paper_dir, claim["id"])
        if row["details"].get("ours") is None or len(runs) < 3:
            continue
        q = question(claim)
        basis = ("paper and independent re-run agree" if row["verdict"] == "Reproduced"
                 else f"independent re-run; paper's printed value differs (verdict: {row['verdict']})")
        task = {
            "field": FIELD.get(claims["journal"], "Life Sciences"),
            "language": language,
            "capsule_title": claims["title"],
            "capsule_id": f"{pid}__{claim['id']}",
            "task_prompt": (
                f"Using only the paper (doi:{claims['doi']}) and the dataset in inputs.json, "
                f"reproduce the analysis behind this claim and save report.json with the answer: {q}"
            ),
            "results": [{q: v} for v in runs],
            "capsule_doi": f"https://doi.org/{claims['doi']}",
            "difficulty": "hard",
            "paper_value": claim["reported"].get("text"),
            "expected_value": row["details"]["ours"],
            "ground_truth_basis": basis,
            "verdict": row["verdict"],
            "tolerance": {
                "rule": "PI95_or_tol",
                "pre_registered": claim.get("tolerance") or {"type": "reported_precision"},
                "abs": row["details"]["tolerance"],
                "frozen_tag": f"claims-frozen-{pid}",
            },
            "source_location": claim.get("location"),
            "data_sources": manifest,
            "env": {"language": language, "lock": f"papers/{pid}/env/"},
            "audit": {"status": "audited", "report": "audit.md"},
        }
        rubric = node(f"{pid}/{claim['id']}/root", f"Reproduce claim {claim['id']} of \"{claims['title']}\"", sub_tasks=[
            node(f"{pid}/{claim['id']}/data", "Fetched the deposited dataset and verified it against the SHA-256 checksums in inputs.json",
                 category="Code Execution", fine="Dataset and Model Acquisition"),
            node(f"{pid}/{claim['id']}/method", "Code implements the analysis described in the paper's methods for this claim (model, exclusions, reference levels)",
                 weight=2, category="Code Development", fine="Method Implementation"),
            node(f"{pid}/{claim['id']}/runs", "The submitted script runs end to end from a clean environment and writes report.json",
                 category="Code Execution", fine="Experimental Setup"),
            node(f"{pid}/{claim['id']}/value", f"Reported value is within tolerance of the expected value {row['details']['ours']:.6g}",
                 weight=3, category="Result Analysis", fine="Evaluation, Metrics & Benchmarking"),
            node(f"{pid}/{claim['id']}/nohardcode", "The value is computed from the data, not hard-coded or copied from the paper",
                 weight=2, category="Result Analysis", fine="Logging, Analysis & Presentation"),
        ])
        out = TASKS / f"{pid}__{claim['id']}"
        out.mkdir(parents=True, exist_ok=True)
        (out / "task.json").write_text(json.dumps(task, indent=2, ensure_ascii=False) + "\n")
        (out / "rubric.json").write_text(json.dumps(rubric, indent=2, ensure_ascii=False) + "\n")
        (out / "inputs.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
        addendum = ["# Addendum", "", "Clarifications drawn from the paper (frozen before reproduction):", ""]
        addendum += [f"- {s}" for s in claims.get("methods_steps", [])]
        (out / "addendum.md").write_text("\n".join(addendum) + "\n")
        made.append(out.name)
    return made


if __name__ == "__main__":
    for d in TASKS.glob("*__*"):
        shutil.rmtree(d)
    total = []
    for paper_dir in sorted((ROOT / "papers").iterdir()):
        if (paper_dir / "report_card.json").exists() and (paper_dir / "audit").is_dir():
            total += package(paper_dir)
    print(f"{len(total)} tasks written")
    for t in total:
        print(" ", t)
