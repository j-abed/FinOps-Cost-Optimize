from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
from pathlib import Path


DESTRUCTIVE_SCRIPTS = (
    "DeleteIdleAppGW_v2.ps1",
    "DeleteIdleDisk_v2.ps1",
    "DeleteIdleLB_v2.ps1",
    "DeleteIdlePIP_v2.ps1",
    "DeleteIdleWebApp_v2.ps1",
    "DeprovisionStoppedVM_v2.ps1",
)


def strip_json_comments(content: str) -> str:
    result: list[str] = []
    index = 0
    in_string = False
    escaped = False

    while index < len(content):
        character = content[index]
        following = content[index + 1] if index + 1 < len(content) else ""

        if in_string:
            result.append(character)
            if escaped:
                escaped = False
            elif character == "\\":
                escaped = True
            elif character == '"':
                in_string = False
            index += 1
            continue

        if character == '"':
            in_string = True
            result.append(character)
            index += 1
        elif character == "/" and following == "/":
            index += 2
            while index < len(content) and content[index] not in "\r\n":
                index += 1
        elif character == "/" and following == "*":
            index += 2
            while index + 1 < len(content) and content[index : index + 2] != "*/":
                if content[index] in "\r\n":
                    result.append(content[index])
                index += 1
            if index + 1 >= len(content):
                raise ValueError("Unterminated JSON block comment")
            index += 2
        else:
            result.append(character)
            index += 1

    return "".join(result)


def load_jsonc(path: Path) -> dict:
    content = path.read_text(encoding="utf-8-sig")
    return json.loads(strip_json_comments(content))


def validate_json_assets(root: Path) -> int:
    paths = sorted(root.rglob("*.json"))
    for path in paths:
        load_jsonc(path)
    return len(paths)


def validate_tag_policies(root: Path) -> None:
    policy_dir = root / "Cost Transparency"
    for name in ("Policy-Audit-Tags.json", "Policy-Enforce-Cost-Tags.json"):
        rule = load_jsonc(policy_dir / name)["properties"]["policyRule"]
        assert len(rule["if"]["anyOf"]) == 5, f"{name} must detect any missing tag"

    modify_rule = load_jsonc(policy_dir / "Policy-Append-Cost-Tags.json")["properties"]["policyRule"]
    assert modify_rule["then"]["effect"] == "modify", "Cost tags must use the modify effect"
    details = modify_rule["then"]["details"]
    assert details["roleDefinitionIds"], "Modify policy requires a remediation role"
    assert len(details["operations"]) == 5, "Modify policy must configure all five tags"
    assert all(operation["operation"] == "addOrReplace" for operation in details["operations"])


def validate_budget_templates(root: Path) -> None:
    for path in sorted((root / "Financial Controls" / "Budget").glob("*.json")):
        parameters = load_jsonc(path)["parameters"]
        assert parameters["amount"]["type"].lower() == "int"
        assert parameters["amount"]["minValue"] == 1
        assert parameters["categoryType"]["defaultValue"] in {"Cost", "Usage"}
        for name in ("firstThreshold", "secondThreshold"):
            threshold = parameters[name]
            assert threshold["type"].lower() == "int"
            assert threshold["minValue"] == 0
            assert threshold["maxValue"] == 1000


def validate_execution_gates(root: Path) -> None:
    script_dir = root / "Usage Optimize" / "PowerShell-Scripts"
    for name in DESTRUCTIVE_SCRIPTS:
        content = (script_dir / name).read_text(encoding="utf-8-sig")
        assert "[switch]$Execute" in content, f"{name} is missing the Execute switch"
        assert "if (-not $Execute)" in content, f"{name} is missing the execution guard"

    aks_content = (script_dir / "StopAksCluster.ps1").read_text(encoding="utf-8-sig")
    for parameter in ("$ResourceGroupName", "$Name", "$Execute"):
        assert parameter in aks_content, f"StopAksCluster.ps1 is missing {parameter}"
    assert "if (-not $Execute)" in aks_content


def validate_powershell(root: Path) -> int:
    executable = shutil.which("pwsh")
    if executable is None:
        raise RuntimeError("PowerShell (pwsh) is required for script parsing")

    command = r"""
$failed = $false
$count = 0
Get-ChildItem -LiteralPath $env:FINOPS_VALIDATION_ROOT -Recurse -Filter *.ps1 | ForEach-Object {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
        $_.FullName,
        [ref]$tokens,
        [ref]$errors
    ) | Out-Null
    $count++
    foreach ($parseError in $errors) {
        $isAutomationWorkflow = $_.Name -eq 'StopAksCluster.ps1' -and
            $parseError.Message -eq 'Workflow is not supported in PowerShell 6+.'
        if (-not $isAutomationWorkflow) {
            $failed = $true
            Write-Error ("{0}: {1}" -f $_.FullName, $parseError.Message)
        }
    }
}
if ($failed) { exit 1 }
Write-Output $count
"""
    environment = os.environ.copy()
    environment["FINOPS_VALIDATION_ROOT"] = str(root)
    completed = subprocess.run(
        [executable, "-NoProfile", "-NonInteractive", "-Command", command],
        check=True,
        capture_output=True,
        env=environment,
        text=True,
    )
    return int(completed.stdout.strip())


def validate_repository(root: Path, *, skip_powershell: bool = False) -> None:
    json_count = validate_json_assets(root)
    validate_tag_policies(root)
    validate_budget_templates(root)
    validate_execution_gates(root)
    print(f"Validated {json_count} JSON/JSONC assets and repository invariants.")

    if not skip_powershell:
        powershell_count = validate_powershell(root)
        print(f"Parsed {powershell_count} PowerShell scripts.")


def main() -> None:
    parser = argparse.ArgumentParser(description="Validate FinOps repository assets")
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--skip-powershell", action="store_true")
    arguments = parser.parse_args()
    validate_repository(arguments.root.resolve(), skip_powershell=arguments.skip_powershell)


if __name__ == "__main__":
    main()