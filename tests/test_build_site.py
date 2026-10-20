"""Check that presentation changes retain the audited evidence and its coverage."""

from collections import Counter
from copy import deepcopy
from hashlib import sha256
from html.parser import HTMLParser
import json
from pathlib import Path
import shutil
import sys
from urllib.parse import unquote, urlsplit

import pytest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import build_site  # noqa: E402
from compare import null_value  # noqa: E402


class Page(HTMLParser):
    """Read semantic evidence, embedded chart data, and local resource links."""

    def __init__(self, path):
        super().__init__(convert_charrefs=True)
        self.links = []
        self.ids = set()
        self.rows = []
        self._row = None
        self._cell = None
        self._json = False
        self._json_parts = []
        self.feed(path.read_text())
        self.data = json.loads("".join(self._json_parts))

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if attrs.get("id"):
            self.ids.add(attrs["id"])
        if tag in {"a", "link", "script", "img"}:
            target = attrs.get("href") or attrs.get("src")
            if target:
                self.links.append(target)
        if tag == "script" and attrs.get("id") == "page-data":
            self._json = True
        if tag == "tr":
            self._row = []
        elif tag in {"th", "td"} and self._row is not None:
            self._cell = []

    def handle_data(self, data):
        if self._json:
            self._json_parts.append(data)
        if self._cell is not None:
            self._cell.append(data)

    def handle_endtag(self, tag):
        if tag == "script":
            self._json = False
        if tag in {"th", "td"} and self._cell is not None:
            self._row.append(" ".join(" ".join(self._cell).split()))
            self._cell = None
        elif tag == "tr" and self._row is not None:
            self.rows.append(self._row)
            self._row = None


def evidence_files():
    """The scientific inputs consumed by the site, plus packaged task records."""
    paths = {ROOT / "scripts" / "compare.py", ROOT / "site" / "screening.json"}
    for pattern in (
        "papers/*/claims.json",
        "papers/*/report_card.json",
        "papers/*/outputs/results.json",
        "papers/*/audit.json",
        "papers/*/audit.md",
        "papers/*/steps.log",
        "tasks/*/task.json",
    ):
        paths.update(ROOT.glob(pattern))
    return paths


def evidence_hashes():
    return {str(p.relative_to(ROOT)): sha256(p.read_bytes()).hexdigest() for p in evidence_files()}


@pytest.fixture
def source_content():
    return json.loads((ROOT / "site" / "content.json").read_text())


@pytest.fixture
def built_site(tmp_path, monkeypatch):
    destination = tmp_path / "site"
    destination.mkdir()
    for name in ("content.json", "screening.json"):
        shutil.copy2(ROOT / "site" / name, destination / name)
    shutil.copytree(ROOT / "site" / "assets", destination / "assets")
    before = evidence_hashes()
    monkeypatch.setattr(build_site, "SITE", destination)
    build_site.main()
    assert evidence_hashes() == before, "Building the story changed its source evidence"
    return destination


def source_claims():
    claims = {}
    for path in sorted(ROOT.glob("papers/*/report_card.json")):
        card = json.loads(path.read_text())
        for claim in card["claims"]:
            key = (card["paper_id"], claim["id"])
            assert key not in claims
            claims[key] = claim
    return claims


def assert_evidence_rows(rows, expected):
    frozen = {
        (path.parent.name, c["id"]): c
        for path in ROOT.glob("papers/*/claims.json")
        for c in json.loads(path.read_text())["claims"]
    }
    keys = [(r["paper_id"], r["claim"]) for r in rows]
    assert Counter(keys) == Counter({key: 1 for key in expected})
    for row in rows:
        claim = expected[(row["paper_id"], row["claim"])]
        assert row["paper_text"] == claim["paper_text"]
        assert row["paper_value"] == claim["details"].get("paper")
        assert row["ours_value"] == claim["details"].get("ours")
        assert row["tolerance"] == claim["details"].get("tolerance")
        assert row["verdict"] == claim["verdict"]
        assert row["reference_value"] == null_value(frozen[(row["paper_id"], row["claim"])])


def test_overview_and_paper_chart_data_preserve_every_claim(built_site):
    expected = source_claims()
    overview = Page(built_site / "index.html")
    assert len(expected) == 24
    assert_evidence_rows(overview.data["rows"], expected)
    paper_rows = []
    for paper_id in sorted({key[0] for key in expected}):
        page = Page(built_site / "papers" / f"{paper_id}.html")
        own_claims = {key: value for key, value in expected.items() if key[0] == paper_id}
        assert_evidence_rows(page.data["rows"], own_claims)
        paper_rows.extend(page.data["rows"])
    assert_evidence_rows(paper_rows, expected)


def test_evidence_tables_retain_printed_and_full_reproduced_values(built_site):
    for (paper_id, claim_id), claim in source_claims().items():
        page = Page(built_site / "papers" / f"{paper_id}.html")
        candidates = [row for row in page.rows if row and claim_id in row[0].split()]
        assert len(candidates) == 1, (paper_id, claim_id, candidates)
        row = candidates[0]
        assert " ".join(claim["paper_text"].split()) in row
        values = []
        for cell in row[1:]:
            try:
                values.append(float(cell.replace("−", "-").replace(",", "")))
            except ValueError:
                pass
        assert claim["details"]["ours"] in values, (paper_id, claim_id, row)
        assert any(claim["verdict"] in cell for cell in row)


def test_story_totals_remain_the_audited_totals(built_site):
    stats = json.loads((built_site / "stats.json").read_text())
    expected = {
        "n_papers": 4,
        "n_claims": 24,
        "n_reproduced": 11,
        "n_partial": 9,
        "n_not_reproduced": 4,
        "n_not_reproducible": 0,
        "n_papers_reproduced": 1,
        "n_papers_partial": 3,
        "n_screened": 32,
        "n_gated": 8,
        "n_on_request": 3,
        "n_tasks": 24,
        "n_audited": 4,
        "n_audit_overrides": 0,
    }
    assert {key: stats[key] for key in expected} == expected
    observed = Counter(c["verdict"] for c in source_claims().values())
    assert observed == {"Reproduced": 11, "Partial": 9, "Not reproduced": 4}


@pytest.mark.parametrize(
    ("printed", "places", "value", "display"),
    [
        ("N = 12,437 (CI 0.12–0.34)", 0, 12435, "12435.0"),
        ("−0.130 (CI95 [−0.20, −0.02])", 3, -0.13045, "-0.1305"),
        ("12 [0.01, 30.00]", 0, 12.125, "12.1"),
        ("12.0 [0.01, 30.00]", 1, 12.123, "12.12"),
        (".03", 2, 0.0321, "0.032"),
        ("3.1%", 1, 3.123, "3.12"),
    ],
)
def test_display_precision_uses_the_leading_reported_number(printed, places, value, display):
    assert build_site.decimals(printed) == places
    assert build_site.fmt_value(value, printed) == display


def test_builder_rejects_a_configured_paper_without_a_report_card(source_content):
    content = deepcopy(source_content)
    content["paper_order"].append("missing-paper-without-report-card")
    with pytest.raises((SystemExit, ValueError, FileNotFoundError)):
        build_site.load_papers(content)


def test_builder_rejects_omitting_an_existing_report_card(source_content):
    content = deepcopy(source_content)
    content["paper_order"] = content["paper_order"][1:]
    with pytest.raises((SystemExit, ValueError)):
        build_site.load_papers(content)


def test_generated_local_links_resolve(built_site):
    pages = {path.resolve(): Page(path) for path in built_site.rglob("*.html")}
    for path, page in pages.items():
        for target in page.links:
            url = urlsplit(target)
            if url.scheme or url.netloc:
                continue
            resolved = (path.parent / unquote(url.path)).resolve() if url.path else path
            assert resolved.exists(), (path.name, target)
            if url.fragment and resolved in pages:
                assert unquote(url.fragment) in pages[resolved].ids, (path.name, target)


def test_rebuilding_is_deterministic_and_keeps_evidence_unchanged(built_site):
    outputs = list(built_site.rglob("*.html")) + [built_site / "stats.json"]
    first = {path.relative_to(built_site): path.read_bytes() for path in outputs}
    before = evidence_hashes()
    build_site.main()
    assert evidence_hashes() == before
    assert {path.relative_to(built_site): path.read_bytes() for path in outputs} == first
