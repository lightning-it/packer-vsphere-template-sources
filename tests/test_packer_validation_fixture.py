#!/usr/bin/env python3
"""Regression tests for the disposable Packer validation SSH key fixture."""

from __future__ import annotations

import json
import os
import stat
import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TEST_SCRIPT = ROOT / "scripts" / "test-packer.sh"


class PackerValidationFixtureTests(unittest.TestCase):
    def test_each_validate_uses_matching_ephemeral_key_and_cleanup_removes_it(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            temporary = Path(temporary_directory)
            fake_bin = temporary / "bin"
            fake_bin.mkdir()
            log_path = temporary / "packer-validate.jsonl"
            fake_packer = fake_bin / "packer"
            fake_packer.write_text(
                textwrap.dedent("""\
                    #!/usr/bin/env python3
                    import json
                    import os
                    import subprocess
                    import sys
                    from pathlib import Path

                    arguments = sys.argv[1:]
                    if arguments == ["version"]:
                        print("Packer v1.15.4")
                        raise SystemExit(0)
                    if arguments and arguments[0] in {"init", "fmt"}:
                        raise SystemExit(0)
                    if not arguments or arguments[0] != "validate":
                        raise SystemExit(f"unexpected packer invocation: {arguments!r}")

                    private_prefix = "-var=installer_private_key_file="
                    authorized_prefix = "-var=installer_authorized_keys=[\\\""
                    private_arguments = [
                        value.removeprefix(private_prefix)
                        for value in arguments
                        if value.startswith(private_prefix)
                    ]
                    authorized_arguments = [
                        value.removeprefix(authorized_prefix).removesuffix("\\\"]")
                        for value in arguments
                        if value.startswith(authorized_prefix) and value.endswith("\\\"]")
                    ]
                    if len(private_arguments) != 1 or len(authorized_arguments) != 1:
                        raise SystemExit(f"missing validation key overrides: {arguments!r}")

                    private_key = Path(private_arguments[0])
                    if not private_key.is_file():
                        raise SystemExit(f"validation private key is missing: {private_key}")
                    derived_public_key = subprocess.check_output(
                        ["ssh-keygen", "-y", "-f", str(private_key)],
                        text=True,
                    ).strip()
                    if authorized_arguments[0].split()[:2] != derived_public_key.split()[:2]:
                        raise SystemExit(
                            "validation public key does not match its private key: "
                            f"{authorized_arguments[0]!r} != {derived_public_key!r}"
                        )

                    with Path(os.environ["PACKER_FIXTURE_TEST_LOG"]).open(
                        "a", encoding="utf-8"
                    ) as log:
                        log.write(json.dumps({"private_key": str(private_key)}) + "\\n")
                    """),
                encoding="utf-8",
            )
            fake_packer.chmod(
                fake_packer.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH
            )

            environment = os.environ.copy()
            environment["PATH"] = f"{fake_bin}{os.pathsep}{environment['PATH']}"
            environment["PACKER_FIXTURE_TEST_LOG"] = str(log_path)
            result = subprocess.run(
                [str(TEST_SCRIPT)],
                cwd=ROOT,
                env=environment,
                text=True,
                capture_output=True,
            )
            self.assertEqual(
                result.returncode,
                0,
                msg=f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}",
            )

            records = [
                json.loads(line)
                for line in log_path.read_text(encoding="utf-8").splitlines()
            ]
            self.assertEqual(len(records), 5)
            private_keys = {Path(record["private_key"]) for record in records}
            self.assertEqual(len(private_keys), 1)
            private_key = private_keys.pop()
            self.assertFalse(private_key.exists())
            self.assertFalse(private_key.parent.exists())


if __name__ == "__main__":
    unittest.main()
