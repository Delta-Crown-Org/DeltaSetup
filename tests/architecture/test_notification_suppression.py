"""
ADR-011 Fitness Functions: Notification suppression by default.

These tests enforce the architectural invariants documented in:
  - docs/sharepoint-pnp-spec/decisions/011-notification-suppression-by-default.md
  - docs/sharepoint-pnp-spec/NOTIFICATION-SUPPRESSION-PLAYBOOK.md

The triggering incident (HTT-52, 2026-05-12 → 2026-05-15) sent welcome /
sharing / access-granted emails to ~57 users without operator consent.
The root cause was Microsoft 365's wildly inconsistent default-notify
behavior across 30+ provisioning surfaces. This module enforces the
"scaffold-quietly, launch-loudly" pattern at static-analysis time so CI
fails fast — before any tenant action.

Run with: pytest tests/architecture/test_notification_suppression.py -v

All tests are pure regex / file-scanning — no live tenant calls — and
complete in <1 second.
"""

import re
from pathlib import Path

import pytest

# ============================================================================
# WHAT WE SCAN — every script that could plausibly hit a tenant
# ============================================================================

REPO_ROOT = Path(__file__).resolve().parents[2]

# Path × extension matrix. Built defensively per ADR-011 release-gate-arbiter
# co-sign Tampering addendum #1: every plausible future provisioning-script
# directory must be covered even if it doesn't exist yet, so a new directory
# can't ship without triggering the scan.
_PROVISIONING_ROOTS = [
    "tools",
    "scripts",
    "dce-mockup/ci-cd/scripts",
    "phase4-migration",
    "phase4-migration/scripts",
    "phase2-week1",
    "phase3-week2",
    "phase5",  # placeholder — Phase 5 not yet started but reserve the name
]
_PROVISIONING_EXTENSIONS = ["ps1", "py", "sh"]

PROVISIONING_GLOBS: list[str] = [
    f"{root}/**/*.{ext}"
    for root in _PROVISIONING_ROOTS
    for ext in _PROVISIONING_EXTENSIONS
] + [
    # JSON config files (the Teams channel definitions live here)
    "dce-mockup/ci-cd/teams/**/*.json",
]

# Scripts that are intentionally read-only / forensic / inventory-only and
# do not provision anything. The mode-signal test is relaxed for these because
# a script that only READS from Graph cannot trigger a user notification.
READ_ONLY_SCRIPT_NAMES = {
    # Forensic / offboarding helpers under tools/
    "check-scot-roles.ps1",
    "find-kayla.ps1",
    "friday-re-audit.ps1",
    "generate_owner_decision_workbook.py",
    # Inventory / audit scripts under phase4-migration/scripts/
    # (these GET against Graph but never POST/PATCH against a tenant)
    "inventory_delta_crown_identity_graph.py",
    "inventory_delta_crown_sharepoint_graph.py",
    "review-delta-crown-duplicate-groups.py",
    "verify_delta_crown_metadata_teams_state.py",
}

# Files known to predate ADR-011. The test suite tracks these for retroactive
# remediation under bd DeltaSetup-<adr011-rollout> rather than blocking new
# work on the historical debt. REMOVING entries from this set is the final
# acceptance criterion of the ADR-011 rollout bd — do not delete an entry
# unless the corresponding script has been brought into compliance.
ADR_011_GRACE_PERIOD = {
    # The HTT-52 culprits — the actual incident scripts (tools/)
    "tools/provision-crown-connection.sh",
    "tools/expand-crown-connection-htt-corp.py",
    "tools/invite-htt-users-to-dce.py",
    "tools/offboard-scot-cannon.ps1",
    # CI/CD mockup scripts (dce-mockup/) — to be retrofitted under bd 17i
    # and migrated to the real Delta-Crown-Org/dce-sharepoint repo.
    "dce-mockup/ci-cd/scripts/provision-teams.ps1",
    "dce-mockup/ci-cd/scripts/deploy-prod.ps1",
    # Phase 4 migration scripts — retrofitted under bd 17i.
    "phase4-migration/scripts/4.3-Document-Migration.ps1",
    # Phase 2 + 3 provisioning scripts surfaced by the release-gate-arbiter
    # Tampering #1 addendum (glob coverage parity). These built the current
    # tenant state and need retrofit under bd 17i before next invocation.
    "phase2-week1/scripts/2.1-CorpHub-Provisioning.ps1",
    "phase2-week1/scripts/2.2-DCEHub-Provisioning.ps1",
    "phase2-week1/scripts/deploy-phase2-standalone.ps1",  # sibling of phase3 deploy
    "phase3-week2/scripts/3.1-DCE-Sites-Provisioning.ps1",
    "phase3-week2/scripts/3.2-Teams-Provisioning.ps1",
    "phase3-week2/scripts/deploy-teams-now.ps1",
    "phase3-week2/scripts/deploy-phase3-standalone.ps1",
    "phase3-week2/scripts/security-hardening-python.py",
    "phase3-week2/scripts/security-hardening-graph.py",
}


def _is_in_grace_period(path: Path) -> bool:
    """True if the file is a historical script tracked for retroactive remediation."""
    rel = str(path.relative_to(REPO_ROOT))
    return rel in ADR_011_GRACE_PERIOD


def _provisioning_files() -> list[Path]:
    files: list[Path] = []
    for glob in PROVISIONING_GLOBS:
        files.extend(REPO_ROOT.glob(glob))
    # Dedup + only real files + exclude the test module itself
    seen: set[Path] = set()
    out: list[Path] = []
    for f in files:
        if f.is_file() and f not in seen and "test_notification_suppression" not in f.name:
            seen.add(f)
            out.append(f)
    return out


def _strip_line_comments(line: str, suffix: str) -> str:
    """Return the code portion of a line, with line comments removed.

    PowerShell, Python, Bash all use ``#``. JSON has no comments.
    """
    if suffix == ".json":
        return line
    return re.sub(r"#.*$", "", line)


# ============================================================================
# Group 1 — no provisioning file may opt INTO notifications in scaffold mode
# ============================================================================


FORBIDDEN_OPT_INS: list[tuple[str, str]] = [
    (
        r"-SendInvitation\b(?!\s*:\s*\$false)",
        "Add-PnP*SharingInvite -SendInvitation is the opt-in to mail; "
        "scaffold mode must NEVER set this. Playbook §4.4.",
    ),
    (
        r"-SendEmail\b(?!\s*:\s*\$false)",
        "Add-PnPGroupMember -SendEmail is the opt-in to mail; "
        "use the -LoginName parameter set for internal users. Playbook §3 #11.",
    ),
    (
        r'"sendInvitation"\s*:\s*true',
        "Graph POST /drives/.../invite must always set sendInvitation:false. "
        "Playbook §4.4.",
    ),
    (
        r'"sendEmail"\s*:\s*true',
        "Legacy SP.Web.ShareObject sendEmail:true; do not use this endpoint. "
        "Playbook §3 #15.",
    ),
    (
        r"sendInvitationMessage\s*[:=]\s*\$true",
        "B2B invitation sendInvitationMessage:$true must only appear in "
        "launch-mode scripts under explicit human approval. Playbook §4.2.",
    ),
    (
        r'"sendInvitationMessage"\s*:\s*[Tt]rue',
        "B2B invitation sendInvitationMessage: True (Python) must only "
        "appear in launch-mode scripts. Playbook §4.2.",
    ),
    (
        r"-UnifiedGroupWelcomeMessageEnabled\s*:?\s*\$true",
        "Re-enabling welcome mail must only happen in a separate launch script. "
        "Playbook §4.1.",
    ),
    (
        r"-UpdateType\s+UpdateOverwriteVersion",
        "UpdateOverwriteVersion TRIGGERS Power Automate flows despite the name. "
        "Use -UpdateType SystemUpdate. Playbook §3 #18.",
    ),
]


def test_no_forbidden_opt_ins():
    """No provisioning script may contain a notification opt-in pattern."""
    violations: list[str] = []
    for path in _provisioning_files():
        # Launch-mode scripts are explicitly allowed to opt in.
        if "launch" in path.name.lower():
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        for lineno, line in enumerate(text.splitlines(), 1):
            code = _strip_line_comments(line, path.suffix)
            for pattern, reason in FORBIDDEN_OPT_INS:
                if re.search(pattern, code):
                    rel = path.relative_to(REPO_ROOT)
                    violations.append(
                        f"{rel}:{lineno}: matched /{pattern}/\n"
                        f"    {reason}\n"
                        f"    LINE: {line.strip()}"
                    )
    assert not violations, (
        "ADR-011 violations — notification opt-ins detected in scaffold-mode files:\n\n"
        + "\n\n".join(violations)
    )


# ============================================================================
# Group 2 — suppression mechanisms MUST be present at create time
# ============================================================================


def test_graph_group_creates_include_welcome_email_disabled():
    """Every Graph POST /groups in repo scripts must set WelcomeEmailDisabled.

    resourceBehaviorOptions is creation-only — cannot PATCH later. Playbook §4.1.
    """
    violations: list[str] = []
    # Match bodies that look like a Graph groups POST: contain `"groupTypes"`
    # and `"Unified"` in some form. We scan for the pattern and check if
    # `WelcomeEmailDisabled` appears within ~20 lines of it.
    for path in _provisioning_files():
        if "launch" in path.name.lower():
            continue
        if _is_in_grace_period(path):
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        # Heuristic: a Graph groups POST will mention "Unified" in groupTypes
        # AND "members@odata.bind" or "displayName" body shape.
        if '"Unified"' not in text or "members@odata.bind" not in text:
            continue
        if "WelcomeEmailDisabled" not in text:
            rel = path.relative_to(REPO_ROOT)
            violations.append(
                f"{rel}: looks like a Graph POST /groups body "
                f"(contains 'Unified' + 'members@odata.bind') but does NOT "
                f"include 'WelcomeEmailDisabled' in resourceBehaviorOptions. "
                f"Playbook §4.1 — this is creation-only; add it to the body."
            )
    assert not violations, "\n".join(violations)


def test_pnp_group_team_creates_include_welcome_email_disabled():
    """Every New-PnPMicrosoft365Group / New-PnPTeamsTeam must set
    -ResourceBehaviorOptions WelcomeEmailDisabled. Playbook §4.1, §4.5."""
    violations: list[str] = []
    pattern = re.compile(
        r"New-PnP(?:Microsoft365Group|TeamsTeam)\b[^\n]*(?:\n\s+[^\n]+)*",
        re.MULTILINE,
    )
    for path in _provisioning_files():
        if path.suffix != ".ps1":
            continue
        if "launch" in path.name.lower():
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        for call in pattern.findall(text):
            if "WelcomeEmailDisabled" not in call:
                rel = path.relative_to(REPO_ROOT)
                violations.append(
                    f"{rel}: New-PnP* call missing "
                    f"-ResourceBehaviorOptions WelcomeEmailDisabled:\n"
                    f"    {call.strip()[:200]}"
                )
    assert not violations, "\n".join(violations)


def test_b2b_invitation_explicitly_suppresses():
    """Every B2B invitation (Graph /invitations or New-MgInvitation) must
    explicitly set sendInvitationMessage:false. Defends against SDK drift.
    Playbook §4.2."""
    violations: list[str] = []
    for path in _provisioning_files():
        if "launch" in path.name.lower():
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        # Check the Python POST /invitations pattern (used in tools/invite-htt-users-to-dce.py)
        if re.search(r'["\']?/invitations["\']?', text) or "New-MgInvitation" in text:
            has_explicit_suppression = (
                re.search(r'"sendInvitationMessage"\s*:\s*[Ff]alse', text)
                or re.search(r"-SendInvitationMessage\s*:\s*\$false", text)
                or re.search(r"sendInvitationMessage\s*=\s*False", text)
            )
            if not has_explicit_suppression:
                rel = path.relative_to(REPO_ROOT)
                violations.append(
                    f"{rel}: file references /invitations or New-MgInvitation "
                    f"but does NOT explicitly set sendInvitationMessage to false. "
                    f"Playbook §4.2 — pin explicitly to defend against SDK drift."
                )
    assert not violations, "\n".join(violations)


# ============================================================================
# Group 3 — every provisioning script signals its mode
# ============================================================================


def test_scripts_declare_mode_parameter():
    """Every PowerShell/Python provisioning script declares a Mode parameter
    (scaffold|launch, default scaffold) and logs PROVISIONING-MODE: at startup.

    Read-only / forensic scripts are exempt (see READ_ONLY_SCRIPT_NAMES).
    Playbook §2."""
    violations: list[str] = []
    for path in _provisioning_files():
        if path.name in READ_ONLY_SCRIPT_NAMES:
            continue
        if _is_in_grace_period(path):
            continue
        if path.suffix not in {".ps1", ".py", ".sh"}:
            continue
        # JSON config files have no params.
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        # Skip scripts that have no provisioning verbs at all (pure helpers,
        # documentation generators, etc.) — heuristic: must mention a
        # provisioning verb to qualify.
        if not re.search(
            r"(POST|PATCH|Add-PnP|New-PnP|New-MgInvitation|/groups|/teams|/invitations|/invite)",
            text,
        ):
            continue
        has_mode_param = ("scaffold" in text.lower() and "launch" in text.lower()) or (
            "--mode" in text
        )
        has_audit_log = "PROVISIONING-MODE" in text
        rel = path.relative_to(REPO_ROOT)
        if not has_mode_param:
            violations.append(
                f"{rel}: missing -Mode/--mode parameter with values "
                f"'scaffold' (default) and 'launch'. Playbook §2.1."
            )
        if not has_audit_log:
            violations.append(
                f"{rel}: missing 'PROVISIONING-MODE:' audit log line at "
                f"startup. Playbook §2.2."
            )
    assert not violations, "\n".join(violations)


# ============================================================================
# Group 4 — launch scripts are clearly separated and marked
# ============================================================================


LAUNCH_MARKER = "DCE-LAUNCH-MODE: APPROVED"


def test_launch_scripts_carry_marker():
    """Files matching **/*launch*.{ps1,py,sh} must carry the
    '# DCE-LAUNCH-MODE: APPROVED' marker in their first 20 lines.

    This is a defense-in-depth signal: scaffolded scripts cannot be silently
    renamed to *launch*.ps1 without also adding the marker, which would surface
    in PR review. Playbook §2.3."""
    violations: list[str] = []
    launch_globs = [
        "**/*launch*.ps1",
        "**/*launch*.py",
        "**/*launch*.sh",
    ]
    launch_files: list[Path] = []
    for glob in launch_globs:
        launch_files.extend(REPO_ROOT.glob(glob))
    # Exclude this test module and the playbook/ADR docs (which mention the marker)
    launch_files = [
        f for f in launch_files
        if f.is_file()
        and "test_notification_suppression" not in f.name
        and f.suffix in {".ps1", ".py", ".sh"}
    ]
    for path in launch_files:
        try:
            head = path.read_text(encoding="utf-8").splitlines()[:20]
        except (UnicodeDecodeError, OSError):
            continue
        if not any(LAUNCH_MARKER in line for line in head):
            rel = path.relative_to(REPO_ROOT)
            violations.append(
                f"{rel}: launch-mode script must carry "
                f"'# {LAUNCH_MARKER}' in the first 20 lines. Playbook §2.3."
            )
    assert not violations, "\n".join(violations)


# ============================================================================
# Group 5 — the legacy footgun is forbidden entirely
# ============================================================================


def test_no_legacy_share_object_endpoint():
    """The _api/SP.Web.ShareObject endpoint defaults sendEmail to TRUE — the
    opposite of every modern API. Forbid the endpoint entirely; use Graph
    /invite instead. Playbook §3 #15."""
    violations: list[str] = []
    pattern = re.compile(r"_api/SP\.Web\.ShareObject", re.IGNORECASE)
    for path in _provisioning_files():
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        for lineno, line in enumerate(text.splitlines(), 1):
            code = _strip_line_comments(line, path.suffix)
            if pattern.search(code):
                rel = path.relative_to(REPO_ROOT)
                violations.append(
                    f"{rel}:{lineno}: forbidden legacy endpoint "
                    f"_api/SP.Web.ShareObject (defaults sendEmail:true). "
                    f"Use Graph /drives/.../invite instead. Playbook §3 #15."
                )
    assert not violations, "\n".join(violations)


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
