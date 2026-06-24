"""
Golden Corpus — expected findings for known incidents.

Each corpus entry:
    incident_id
    input data (events, logs, resources)
    expected findings (type + severity)

Use:
    Run engine against corpus → measure accuracy
    Every bug becomes a new corpus entry, not special-case code.
"""

import json
import os
from dataclasses import dataclass, field
from pathlib import Path


CORPUS_DIR = os.path.expanduser(
    "~/.kubsome/corpus"
)


@dataclass
class CorpusEntry:
    id: str
    description: str
    input_data: dict
    expected_findings: list[dict] = field(
        default_factory=list
    )
    # Each: {"finding_type": "oom_kill", "severity": "critical"}


def load_corpus():
    """Load all corpus entries."""
    if not os.path.isdir(CORPUS_DIR):
        return []

    entries = []
    for fp in sorted(Path(CORPUS_DIR).glob("*.json")):
        with open(fp) as f:
            data = json.load(f)
        entries.append(CorpusEntry(
            id=data["id"],
            description=data.get("description", ""),
            input_data=data["input_data"],
            expected_findings=data.get(
                "expected_findings", []
            ),
        ))
    return entries


def save_entry(entry):
    """Save a corpus entry."""
    os.makedirs(CORPUS_DIR, exist_ok=True)
    filepath = os.path.join(
        CORPUS_DIR, f"{entry.id}.json"
    )
    data = {
        "id": entry.id,
        "description": entry.description,
        "input_data": entry.input_data,
        "expected_findings": entry.expected_findings,
    }
    with open(filepath, "w") as f:
        json.dump(data, f, indent=2)


def add_from_incident(incident_id, input_data,
                      expected_findings, description=""):
    """
    Add a new corpus entry from a real incident.
    Call this when a bug is found — the bug becomes
    a regression test.
    """
    entry = CorpusEntry(
        id=incident_id,
        description=description,
        input_data=input_data,
        expected_findings=expected_findings,
    )
    save_entry(entry)
    return entry
