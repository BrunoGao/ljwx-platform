#!/usr/bin/env python3
"""Validate overall and diff coverage thresholds from JaCoCo XML report."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Set
from xml.etree import ElementTree as ET


@dataclass(frozen=True)
class CoverageResult:
    covered: int
    total: int

    @property
    def ratio(self) -> float:
        if self.total == 0:
            return 100.0
        return (self.covered / self.total) * 100.0


def run_git_diff(base_sha: str, head_sha: str) -> str:
    cmd = [
        "git",
        "diff",
        "--unified=0",
        "--no-color",
        base_sha,
        head_sha,
        "--",
        "*.java",
    ]
    completed = subprocess.run(cmd, check=True, capture_output=True, text=True)
    return completed.stdout


def parse_changed_lines(diff_text: str) -> Dict[str, Set[int]]:
    file_to_lines: Dict[str, Set[int]] = {}
    current_file = ""
    new_line_no = 0

    for raw_line in diff_text.splitlines():
        if raw_line.startswith("+++ b/"):
            current_file = raw_line[6:]
            continue

        if raw_line.startswith("@@"):
            match = re.search(r"\+(\d+)(?:,(\d+))?", raw_line)
            if not match:
                continue
            new_line_no = int(match.group(1))
            continue

        if not current_file:
            continue

        if raw_line.startswith("+") and not raw_line.startswith("+++"):
            file_to_lines.setdefault(current_file, set()).add(new_line_no)
            new_line_no += 1
            continue

        if raw_line.startswith(" "):
            new_line_no += 1
            continue

        if raw_line.startswith("-") and not raw_line.startswith("---"):
            continue

    return file_to_lines


def parse_jacoco_lines(jacoco_xml: Path) -> Dict[str, Dict[int, int]]:
    tree = ET.parse(jacoco_xml)
    root = tree.getroot()

    coverage_map: Dict[str, Dict[int, int]] = {}

    for package in root.findall("package"):
        package_name = package.attrib.get("name", "")
        for sourcefile in package.findall("sourcefile"):
            source_name = sourcefile.attrib.get("name", "")
            relative_source = (
                f"{package_name}/{source_name}" if package_name else source_name
            )
            line_hits: Dict[int, int] = {}
            for line in sourcefile.findall("line"):
                line_no = int(line.attrib["nr"])
                covered_instructions = int(line.attrib.get("ci", "0"))
                line_hits[line_no] = covered_instructions
            coverage_map[relative_source] = line_hits

    return coverage_map


def parse_overall_line_coverage(jacoco_xml: Path) -> CoverageResult:
    tree = ET.parse(jacoco_xml)
    root = tree.getroot()

    for counter in root.findall("counter"):
        if counter.attrib.get("type") == "LINE":
            missed = int(counter.attrib.get("missed", "0"))
            covered = int(counter.attrib.get("covered", "0"))
            return CoverageResult(covered=covered, total=missed + covered)

    return CoverageResult(covered=0, total=0)


def to_source_key(file_path: str) -> str:
    marker = "/src/main/java/"
    if marker not in file_path:
        return ""
    return file_path.split(marker, maxsplit=1)[1]


def evaluate_diff_coverage(
    changed_lines: Dict[str, Set[int]], jacoco_lines: Dict[str, Dict[int, int]]
) -> CoverageResult:
    covered = 0
    total = 0

    for file_path, lines in changed_lines.items():
        source_key = to_source_key(file_path)
        if not source_key:
            continue
        line_hits = jacoco_lines.get(source_key)
        if not line_hits:
            continue
        for line_no in sorted(lines):
            if line_no not in line_hits:
                continue
            total += 1
            if line_hits[line_no] > 0:
                covered += 1

    return CoverageResult(covered=covered, total=total)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Check JaCoCo coverage thresholds")
    parser.add_argument("--jacoco-xml", required=True, help="Path to jacoco.xml")
    parser.add_argument(
        "--min-line",
        type=float,
        required=True,
        help="Minimum overall line coverage percentage",
    )
    parser.add_argument(
        "--min-diff", type=float, required=True, help="Minimum diff coverage percentage"
    )
    parser.add_argument("--base-sha", default="", help="Base git SHA for diff coverage")
    parser.add_argument("--head-sha", default="", help="Head git SHA for diff coverage")
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    jacoco_xml = Path(args.jacoco_xml)
    if not jacoco_xml.exists():
        print(f"[错误] JaCoCo 报告不存在: {jacoco_xml}", file=sys.stderr)
        return 1

    overall = parse_overall_line_coverage(jacoco_xml)
    print(
        "[信息] 全量行覆盖率: "
        f"{overall.ratio:.2f}% (covered={overall.covered}, total={overall.total}, threshold={args.min_line:.2f}%)"
    )

    violations: list[str] = []
    if overall.ratio < args.min_line:
        violations.append(
            f"全量行覆盖率不足: {overall.ratio:.2f}% < {args.min_line:.2f}%"
        )

    if args.base_sha and args.head_sha:
        try:
            diff_text = run_git_diff(args.base_sha, args.head_sha)
        except subprocess.CalledProcessError as exc:
            print(f"[错误] 计算 git diff 失败: {exc}", file=sys.stderr)
            return 1

        changed_lines = parse_changed_lines(diff_text)
        jacoco_lines = parse_jacoco_lines(jacoco_xml)
        diff_result = evaluate_diff_coverage(changed_lines, jacoco_lines)

        if diff_result.total == 0:
            print("[信息] 未检测到可计算的 diff 覆盖率行，跳过 diff 阈值判定")
        else:
            print(
                "[信息] Diff 行覆盖率: "
                f"{diff_result.ratio:.2f}% (covered={diff_result.covered}, total={diff_result.total}, threshold={args.min_diff:.2f}%)"
            )
            if diff_result.ratio < args.min_diff:
                violations.append(
                    f"Diff 行覆盖率不足: {diff_result.ratio:.2f}% < {args.min_diff:.2f}%"
                )
    else:
        print("[信息] 缺少 base/head SHA，跳过 diff 覆盖率判定")

    if violations:
        print("[结论] 覆盖率阈值校验失败:", file=sys.stderr)
        for violation in violations:
            print(f"  - {violation}", file=sys.stderr)
        return 1

    print("[结论] 覆盖率阈值校验通过")
    return 0


if __name__ == "__main__":
    sys.exit(main())
