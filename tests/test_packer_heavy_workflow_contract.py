#!/usr/bin/env python3
"""Contract tests for the SHA-pinned reusable Packer heavy workflow."""

from __future__ import annotations

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github" / "workflows" / "packer-heavy-nested-esxi.yml"


class PackerHeavyWorkflowContractTests(unittest.TestCase):
    def test_reusable_workflow_pin_matches_declared_validation_sha(self) -> None:
        source = WORKFLOW.read_text(encoding="utf-8")
        workflow_pin = re.search(
            r"uses: lightning-it/modulix-validation/"
            r"\.github/workflows/packer-nested-esxi-profile\.yml@([0-9a-f]{40})",
            source,
        )
        declared_sha = re.search(r"^\s+validation-sha: ([0-9a-f]{40})$", source, re.MULTILINE)

        self.assertIsNotNone(workflow_pin)
        self.assertIsNotNone(declared_sha)
        self.assertEqual(workflow_pin.group(1), declared_sha.group(1))

    def test_oidc_permission_is_available_to_reusable_workflow(self) -> None:
        source = WORKFLOW.read_text(encoding="utf-8")
        self.assertRegex(source, r"(?m)^  id-token: write$")


if __name__ == "__main__":
    unittest.main()
