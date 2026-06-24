"""
Evidence Strength — scores how strong the evidence
backing a finding is.

Not confidence. Evidence quality.

Strong: event + resource state + metrics
Medium: logs + correlation
Weak:   pattern inference only
"""

from enum import Enum

from core.diagnostics.models import (
    InvestigationReport,
    Finding,
    Observation,
    ObservationSource,
)


class EvidenceStrength(Enum):
    STRONG = "strong"
    MEDIUM = "medium"
    WEAK = "weak"


# Source weight — higher = stronger evidence
_SOURCE_WEIGHT = {
    ObservationSource.EVENT: 3,
    ObservationSource.RESOURCE: 3,
    ObservationSource.METRICS: 3,
    ObservationSource.CONFIG: 2,
    ObservationSource.LOG: 2,
    ObservationSource.CORRELATED_LOG: 2,
    ObservationSource.CROSS_SERVICE_EVENT: 2,
}


def score_finding(finding, report):
    """
    Score evidence strength for a single finding.
    Returns EvidenceStrength.
    """
    obs_map = {o.id: o for o in report.observations}

    sources = set()
    verified_count = 0

    for eid in finding.evidence_ids:
        obs = obs_map.get(eid)
        if not obs:
            continue
        sources.add(obs.source)
        if obs.verified:
            verified_count += 1

    if not sources:
        return EvidenceStrength.WEAK

    total_weight = sum(
        _SOURCE_WEIGHT.get(s, 1) for s in sources
    )

    # Strong: multiple high-weight sources, all verified
    if (
        total_weight >= 6
        and verified_count == len(finding.evidence_ids)
    ):
        return EvidenceStrength.STRONG

    # Medium: some evidence, mostly verified
    if total_weight >= 3 and verified_count >= 1:
        return EvidenceStrength.MEDIUM

    return EvidenceStrength.WEAK


def score_report(report):
    """
    Score all findings in a report.
    Returns dict of finding_id → EvidenceStrength.
    """
    scores = {}
    for f in report.findings:
        if f.id == "healthy":
            continue
        scores[f.id] = score_finding(f, report)
    return scores


def weakest_findings(report):
    """Return findings with weak evidence."""
    scores = score_report(report)
    return [
        fid for fid, strength in scores.items()
        if strength == EvidenceStrength.WEAK
    ]
