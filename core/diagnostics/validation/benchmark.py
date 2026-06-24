"""
Benchmark — runs the diagnostics engine against
the golden corpus and reports accuracy metrics.

Metrics:
    Top-1 Accuracy: primary finding matches expected
    Top-3 Accuracy: expected in top 3 findings
    False Positive Rate: findings not in expected
    Miss Rate: expected findings not produced
"""

from core.diagnostics.engine import investigate
from core.diagnostics.validation.corpus import (
    load_corpus, CorpusEntry,
)


def run_benchmark(corpus=None):
    """
    Run engine against all corpus entries.
    Returns accuracy report.
    """
    if corpus is None:
        corpus = load_corpus()

    if not corpus:
        return {
            "total": 0,
            "message": "No corpus entries found",
        }

    results = []
    for entry in corpus:
        result = _evaluate_entry(entry)
        results.append(result)

    # Aggregate
    total = len(results)
    top1_correct = sum(
        1 for r in results if r["top1_correct"]
    )
    top3_correct = sum(
        1 for r in results if r["top3_correct"]
    )
    total_fp = sum(
        r["false_positives"] for r in results
    )
    total_misses = sum(
        r["misses"] for r in results
    )
    total_expected = sum(
        len(r["expected"]) for r in results
    )
    total_produced = sum(
        len(r["produced"]) for r in results
    )

    return {
        "total": total,
        "top1_accuracy": round(
            top1_correct / total, 3
        ) if total else 0,
        "top3_accuracy": round(
            top3_correct / total, 3
        ) if total else 0,
        "false_positive_rate": round(
            total_fp / total_produced, 3
        ) if total_produced else 0,
        "miss_rate": round(
            total_misses / total_expected, 3
        ) if total_expected else 0,
        "entries": results,
    }


def _evaluate_entry(entry):
    """Evaluate a single corpus entry."""
    report = investigate(entry.input_data)

    if not report:
        return {
            "id": entry.id,
            "top1_correct": False,
            "top3_correct": False,
            "false_positives": 0,
            "misses": len(entry.expected_findings),
            "expected": entry.expected_findings,
            "produced": [],
        }

    # Extract produced finding types (skip healthy)
    produced = [
        f.finding_type
        for f in report.findings
        if f.finding_type and f.id != "healthy"
    ]

    expected_types = [
        e["finding_type"]
        for e in entry.expected_findings
    ]

    # Top-1: first expected in first produced
    top1_correct = (
        bool(produced)
        and bool(expected_types)
        and produced[0] in expected_types
    )

    # Top-3: any expected in first 3 produced
    top3 = set(produced[:3])
    top3_correct = bool(
        top3 & set(expected_types)
    )

    # False positives: produced but not expected
    false_positives = len(
        set(produced) - set(expected_types)
    )

    # Misses: expected but not produced
    misses = len(
        set(expected_types) - set(produced)
    )

    return {
        "id": entry.id,
        "top1_correct": top1_correct,
        "top3_correct": top3_correct,
        "false_positives": false_positives,
        "misses": misses,
        "expected": expected_types,
        "produced": produced,
    }
