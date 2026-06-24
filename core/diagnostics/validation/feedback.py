"""
Feedback — captures user verdicts on findings
so Kubsome can learn from being wrong.

Stores:
    ~/.kubsome/feedback/<finding_type>/<verdict>.jsonl
"""

import json
import os
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from enum import Enum
from pathlib import Path


FEEDBACK_DIR = os.path.expanduser(
    "~/.kubsome/feedback"
)


class Verdict(Enum):
    CORRECT = "correct"
    WRONG = "wrong"
    PARTIAL = "partial"
    MISSED = "missed"  # user expected finding, didn't get it


@dataclass
class Feedback:
    finding_type: str
    verdict: Verdict
    incident_id: str = ""
    comment: str = ""
    timestamp: datetime = None

    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.now(timezone.utc)


def record(feedback):
    """Store a feedback entry."""
    directory = os.path.join(
        FEEDBACK_DIR, feedback.finding_type
    )
    os.makedirs(directory, exist_ok=True)

    filepath = os.path.join(
        directory, f"{feedback.verdict.value}.jsonl"
    )

    entry = {
        "finding_type": feedback.finding_type,
        "verdict": feedback.verdict.value,
        "incident_id": feedback.incident_id,
        "comment": feedback.comment,
        "timestamp": feedback.timestamp.isoformat(),
    }

    with open(filepath, "a") as f:
        f.write(json.dumps(entry) + "\n")


def summary():
    """
    Compute accuracy summary across all feedback.
    Returns dict of finding_type → {correct, wrong, partial, total, accuracy}.
    """
    if not os.path.isdir(FEEDBACK_DIR):
        return {}

    results = {}
    for ft_dir in Path(FEEDBACK_DIR).iterdir():
        if not ft_dir.is_dir():
            continue
        ft = ft_dir.name
        counts = {
            "correct": 0, "wrong": 0,
            "partial": 0, "missed": 0,
        }
        for jsonl in ft_dir.glob("*.jsonl"):
            verdict = jsonl.stem
            with open(jsonl) as f:
                counts[verdict] = sum(
                    1 for _ in f
                )

        total = sum(counts.values())
        accuracy = (
            counts["correct"] / total
            if total > 0 else 0.0
        )

        results[ft] = {
            **counts,
            "total": total,
            "accuracy": round(accuracy, 3),
        }

    return results


def worst_performers(n=5):
    """Return finding types with lowest accuracy."""
    s = summary()
    ranked = sorted(
        s.items(),
        key=lambda x: x[1]["accuracy"],
    )
    return ranked[:n]


def false_positive_rate():
    """Overall false positive rate across all findings."""
    s = summary()
    total_wrong = sum(
        v["wrong"] for v in s.values()
    )
    total = sum(v["total"] for v in s.values())
    if total == 0:
        return 0.0
    return round(total_wrong / total, 3)
