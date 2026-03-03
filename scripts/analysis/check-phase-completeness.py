#!/usr/bin/env python3
"""
Phase 29-53 Implementation Completeness Checker
Analyzes phase specifications vs actual implementation
"""

import re
import yaml
from pathlib import Path
from typing import Dict, List, Tuple
from dataclasses import dataclass


@dataclass
class PhaseInfo:
    phase_num: int
    title: str
    status: str
    backend_required: bool
    frontend_required: bool
    spec_files: List[str]
    manifest_files: List[str]
    missing_files: List[str]
    extra_files: List[str]


def parse_phase_spec(spec_path: Path) -> Tuple[bool, bool, List[str]]:
    """Parse phase spec file to extract backend/frontend requirements and scope"""
    with open(spec_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Extract YAML frontmatter
    match = re.search(r"^---\n(.*?)\n---", content, re.DOTALL | re.MULTILINE)
    if not match:
        return False, False, []

    try:
        frontmatter = yaml.safe_load(match.group(1))
        backend = frontmatter.get("targets", {}).get("backend", False)
        frontend = frontmatter.get("targets", {}).get("frontend", False)
        scope = frontmatter.get("scope", [])
        return backend, frontend, scope
    except Exception:
        return False, False, []


def parse_manifest() -> Dict[int, Tuple[str, str, List[str]]]:
    """Parse PHASE_MANIFEST.txt to extract phase info"""
    manifest_path = Path(
        "/Users/brunogao/work/codes/ljwx/ljwx-platform/PHASE_MANIFEST.txt"
    )
    phases = {}

    with open(manifest_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Split by phase sections
    phase_sections = re.split(r"\n## PHASE (\d+)\n", content)

    for i in range(1, len(phase_sections), 2):
        phase_num = int(phase_sections[i])
        if phase_num < 29 or phase_num > 53:
            continue

        section = phase_sections[i + 1]

        # Extract title
        title_match = re.search(r"Title: (.+)", section)
        title = title_match.group(1) if title_match else "Unknown"

        # Extract status
        status_match = re.search(r"Status: (\w+)", section)
        status = status_match.group(1) if status_match else "UNKNOWN"

        # Extract files
        files = []
        in_files_section = False
        for line in section.split("\n"):
            if line.startswith("Files:"):
                in_files_section = True
                continue
            if in_files_section:
                if (
                    line.startswith("Status:")
                    or line.startswith("Gate:")
                    or line.startswith("##")
                ):
                    break
                if line.strip().startswith("- "):
                    # Remove quotes and leading dash
                    file_path = line.strip()[2:].strip('"')
                    if file_path and file_path != "--":
                        files.append(file_path)

        phases[phase_num] = (title, status, files)

    return phases


def check_file_exists(file_path: str, base_dir: Path) -> bool:
    """Check if a file exists relative to base directory"""
    full_path = base_dir / file_path
    return full_path.exists()


def analyze_phase(phase_num: int, base_dir: Path) -> PhaseInfo:
    """Analyze a single phase for completeness"""
    spec_path = base_dir / f"spec/phase/phase-{phase_num}.md"

    # Parse spec file
    if not spec_path.exists():
        return PhaseInfo(
            phase_num=phase_num,
            title="SPEC NOT FOUND",
            status="NOT_STARTED",
            backend_required=False,
            frontend_required=False,
            spec_files=[],
            manifest_files=[],
            missing_files=[],
            extra_files=[],
        )

    backend_req, frontend_req, spec_files = parse_phase_spec(spec_path)

    # Parse manifest
    manifest_data = parse_manifest()
    if phase_num not in manifest_data:
        return PhaseInfo(
            phase_num=phase_num,
            title="NOT IN MANIFEST",
            status="NOT_STARTED",
            backend_required=backend_req,
            frontend_required=frontend_req,
            spec_files=spec_files,
            manifest_files=[],
            missing_files=spec_files,
            extra_files=[],
        )

    title, status, manifest_files = manifest_data[phase_num]

    # Check file existence
    spec_set = set(spec_files)
    manifest_set = set(manifest_files)

    missing_files = []
    for file_path in spec_set:
        if not check_file_exists(file_path, base_dir):
            missing_files.append(file_path)

    extra_files = list(manifest_set - spec_set)

    return PhaseInfo(
        phase_num=phase_num,
        title=title,
        status=status,
        backend_required=backend_req,
        frontend_required=frontend_req,
        spec_files=spec_files,
        manifest_files=manifest_files,
        missing_files=missing_files,
        extra_files=extra_files,
    )


def main():
    base_dir = Path("/Users/brunogao/work/codes/ljwx/ljwx-platform")

    print("=" * 80)
    print("Phase 29-53 Implementation Completeness Analysis")
    print("=" * 80)
    print()

    complete_count = 0
    partial_count = 0
    not_started_count = 0

    for phase_num in range(29, 54):
        info = analyze_phase(phase_num, base_dir)

        # Determine completeness
        if info.status == "NOT_STARTED":
            status_symbol = "❌"
            completeness = "NOT_STARTED"
            not_started_count += 1
        elif len(info.missing_files) == 0:
            status_symbol = "✅"
            completeness = "COMPLETE"
            complete_count += 1
        else:
            status_symbol = "⚠️"
            completeness = "INCOMPLETE"
            partial_count += 1

        print(f"Phase {phase_num}: {status_symbol} {info.title}")
        print(f"  Status: {info.status}")
        print(f"  Backend: {'required' if info.backend_required else 'not required'}")
        print(f"  Frontend: {'required' if info.frontend_required else 'not required'}")
        print(
            f"  Files: {len(info.spec_files)} specified, {len(info.manifest_files)} in manifest"
        )

        if info.missing_files:
            print(f"  ⚠️  Missing files ({len(info.missing_files)}):")
            for f in info.missing_files[:5]:  # Show first 5
                print(f"      - {f}")
            if len(info.missing_files) > 5:
                print(f"      ... and {len(info.missing_files) - 5} more")

        if info.extra_files:
            print(f"  ℹ️  Extra files in manifest ({len(info.extra_files)}):")
            for f in info.extra_files[:3]:
                print(f"      - {f}")
            if len(info.extra_files) > 3:
                print(f"      ... and {len(info.extra_files) - 3} more")

        print(f"  Completeness: {completeness}")
        print()

    print("=" * 80)
    print("Summary")
    print("=" * 80)
    print(f"✅ Complete phases: {complete_count}/25")
    print(f"⚠️  Incomplete phases: {partial_count}/25")
    print(f"❌ Not started phases: {not_started_count}/25")
    print()

    if complete_count == 25:
        print("🎉 All phases 29-53 are fully implemented!")
    elif partial_count > 0:
        print(f"⚠️  {partial_count} phases need attention - some files are missing")
    if not_started_count > 0:
        print(f"❌ {not_started_count} phases have not been started")


if __name__ == "__main__":
    main()
