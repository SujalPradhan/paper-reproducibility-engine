"""Extract the paper-screening log from candidates.md into site/screening.json.

Usage: python scripts/extract_screening.py
"""

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
JOURNALS = {
    "cam4": "Cancer Medicine",
    "hsr2": "Health Science Reports",
    "brb3": "Brain and Behavior",
    "ece3": "Ecology and Evolution",
    "phy2": "Physiological Reports",
}
DOI = re.compile(r"10\.\d{4,5}/[a-z0-9]+\.\d+")


def journal(doi):
    return JOURNALS.get(doi.split("/")[1].split(".")[0], "")


def section(text, number):
    m = re.search(rf"^## {number}\..*?$(.*?)(?=^## |\Z)", text, re.S | re.M)
    return m.group(1) if m else ""


def clean(s):
    s = re.sub(r"\*\*|`", "", s)
    s = re.sub(r"\s*\(PMC\d+\)", "", s)
    return s.strip().rstrip(".")


def main():
    text = (ROOT / "candidates.md").read_text()
    entries = {}

    for line in section(text, 1).splitlines():
        m = re.match(r"\|\s*(\d)\s*\|\s*`([^`]+)`.*?(10\.1002/[a-z0-9]+\.\d+)", line)
        if m:
            doi = m.group(3)
            entries[doi] = {"doi": doi, "title": m.group(2), "journal": journal(doi),
                            "stage": "passed", "reason": "Shortlisted for reproduction"}

    for line in section(text, 3).splitlines():
        m = re.match(r"\|\s*R\d\s+`([^`]+)`\s*\|\s*(10\.1002/[a-z0-9]+\.\d+)", line)
        if m:
            doi = m.group(2)
            dryad = "Dryad" in line and "needs token" in line
            entries[doi] = {"doi": doi, "title": m.group(1), "journal": journal(doi), "stage": "passed",
                            "reason": "Reserve; data needs a Dryad API token" if dryad else "Reserve; passed the gate, not needed"}

    for line in section(text, 4).splitlines():
        m = re.match(r"\d\.\s+\*\*(10\.\d+/[a-z0-9]+\.\d+)\*\*.*?\"([^\"]+)\"", line)
        if m and m.group(1) not in entries:
            doi = m.group(1)
            entries[doi] = {"doi": doi, "title": m.group(2), "journal": journal(doi), "stage": "on_request",
                            "reason": "Data available only on request from the authors"}

    for line in section(text, 5).splitlines():
        if not line.startswith("- 10."):
            continue
        dois = DOI.findall(line.split(":")[0])
        reason = clean(line.split(":", 1)[1]) if ":" in line else ""
        for doi in dois:
            if doi in entries:
                continue
            desc = re.search(r"^- [^ ]+ \(([^,)]+)", line)
            title = desc.group(1) if desc and not desc.group(1).startswith("PMC") else doi
            stage = "on_request" if re.search(r"on request|upon request", line, re.I) else "rejected"
            entries[doi] = {"doi": doi, "title": title, "journal": journal(doi), "stage": stage, "reason": reason}

    order = {"passed": 0, "on_request": 1, "rejected": 2}
    out = sorted(entries.values(), key=lambda e: (order[e["stage"]], e["journal"], e["doi"]))
    (ROOT / "site" / "screening.json").write_text(json.dumps(out, indent=2, ensure_ascii=False) + "\n")
    counts = {k: sum(1 for e in out if e["stage"] == k) for k in order}
    print(len(out), "screened", counts)


if __name__ == "__main__":
    main()
