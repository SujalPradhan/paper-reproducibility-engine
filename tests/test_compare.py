import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

from compare import (  # noqa: E402
    NOT_REPRODUCED,
    NOT_REPRODUCIBLE,
    PARTIAL,
    REPRODUCED,
    judge,
    paper_verdict,
    precision_tolerance,
)


def claim(text, p=None, tolerance=None):
    c = {"id": "C1", "text": "t", "reported": {"value": float(text.rstrip("%")), "text": text, "p": p}}
    if tolerance:
        c["tolerance"] = tolerance
    return c


def ok(value, p=None):
    return {"id": "C1", "status": "ok", "value": value, "p": p}


def test_precision_tolerance():
    assert precision_tolerance("0.42") == 0.005
    assert precision_tolerance("12") == 0.5
    assert abs(precision_tolerance("3.1%") - 0.05) < 1e-12
    assert abs(precision_tolerance("-0.130") - 0.0005) < 1e-12
    assert precision_tolerance("N = 12,437") == 0.5
    assert precision_tolerance("0.48 [0.47, 0.49]") == 0.005
    assert precision_tolerance("−0.06 (CI95 [−0.09, −0.02])") == 0.005
    assert precision_tolerance(".03") == 0.005


def test_reproduced_at_reported_precision_boundary():
    assert judge(claim("0.42"), ok(0.4249))[0] == REPRODUCED
    assert judge(claim("0.42"), ok(0.415))[0] == REPRODUCED
    assert judge(claim("0.42"), ok(0.4251))[0] == PARTIAL


def test_explicit_tolerances():
    assert judge(claim("0.42", tolerance={"type": "abs", "value": 0.02}), ok(0.439))[0] == REPRODUCED
    assert judge(claim("10.0", tolerance={"type": "rel", "value": 0.05}), ok(10.49))[0] == REPRODUCED
    assert judge(claim("10.0", tolerance={"type": "rel", "value": 0.05}), ok(10.6))[0] == PARTIAL


def test_partial_needs_sign_significance_and_magnitude():
    assert judge(claim("0.42", p="<0.001"), ok(0.30, p=0.002))[0] == PARTIAL
    assert judge(claim("0.42", p="<0.001"), ok(0.30, p=0.2))[0] == NOT_REPRODUCED
    assert judge(claim("0.42"), ok(-0.40))[0] == NOT_REPRODUCED
    assert judge(claim("0.42"), ok(0.10))[0] == NOT_REPRODUCED
    assert judge(claim("0.42", tolerance={"partial_rel": 0.9}), ok(0.10))[0] == PARTIAL


def test_direction_uses_null_value_for_ratios():
    c = claim("0.966")
    c["statistic"] = "odds ratio"
    assert judge(c, ok(0.95))[0] == PARTIAL
    assert judge(c, ok(1.02))[0] == NOT_REPRODUCED
    c2 = claim("0.48")
    c2["null_value"] = 0.5
    assert judge(c2, ok(0.47))[0] == PARTIAL
    assert judge(c2, ok(0.52))[0] == NOT_REPRODUCED


def test_null_significance_block():
    c = claim("12437")
    c["significance"] = None
    assert judge(c, ok(12435))[0] == PARTIAL


def test_not_reproducible():
    assert judge(claim("0.42"), None)[0] == NOT_REPRODUCIBLE
    v, d = judge(claim("0.42"), {"id": "C1", "status": "not_computable", "reason": "no site column"})
    assert v == NOT_REPRODUCIBLE and d["reason"] == "no site column"


def test_paper_verdict():
    assert paper_verdict([REPRODUCED, REPRODUCED]) == REPRODUCED
    assert paper_verdict([REPRODUCED, NOT_REPRODUCED]) == PARTIAL
    assert paper_verdict([NOT_REPRODUCIBLE]) == NOT_REPRODUCIBLE
    assert paper_verdict([NOT_REPRODUCED, NOT_REPRODUCIBLE]) == NOT_REPRODUCED
