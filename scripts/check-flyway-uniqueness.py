#!/usr/bin/env python3
"""
Flyway Migration Uniqueness Check - 检查 Flyway 版本号唯一性
"""

import sys
import yaml
from pathlib import Path
from collections import defaultdict


# 颜色输出
class Colors:
    RED = "\033[91m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    BLUE = "\033[94m"
    END = "\033[0m"


def log_error(msg: str):
    print(f"{Colors.RED}❌ ERROR: {msg}{Colors.END}")


def log_warning(msg: str):
    print(f"{Colors.YELLOW}⚠️  WARNING: {msg}{Colors.END}")


def log_success(msg: str):
    print(f"{Colors.GREEN}✅ {msg}{Colors.END}")


def log_info(msg: str):
    print(f"{Colors.BLUE}ℹ️  {msg}{Colors.END}")


def main():
    # 项目根目录
    root_dir = Path(__file__).parent.parent
    registry_file = root_dir / "spec" / "registry" / "migrations.yml"
    migration_dir = (
        root_dir
        / "ljwx-platform-app"
        / "src"
        / "main"
        / "resources"
        / "db"
        / "migration"
    )

    # 加载 migrations.yml
    try:
        with open(registry_file, "r", encoding="utf-8") as f:
            registry = yaml.safe_load(f)
    except Exception as e:
        log_error(f"Failed to load {registry_file}: {e}")
        sys.exit(1)

    migrations = registry.get("migrations", [])
    log_info(f"Found {len(migrations)} migrations in registry")

    # 检查版本号唯一性
    version_map = defaultdict(list)
    for migration in migrations:
        version = migration["version"]
        version_map[version].append(migration)

    errors = []
    warnings = []

    # 检查重复版本号
    for version, migs in version_map.items():
        if len(migs) > 1:
            descriptions = [m["description"] for m in migs]
            errors.append(f"Duplicate Flyway version 'V{version}': {descriptions}")

    # 检查版本号与 Phase 编号是否对应
    for migration in migrations:
        version = migration["version"]
        phase = migration.get("phase")
        if phase and version != f"{phase:03d}":
            warnings.append(
                f"Version 'V{version}' does not match Phase {phase} (expected V{phase:03d})"
            )

    # 检查迁移文件是否存在 (如果 migration_dir 存在)
    if migration_dir.exists():
        for migration in migrations:
            version = migration["version"]
            description = migration["description"]
            # 查找匹配的迁移文件 (V{version}__{description}.sql)
            pattern = f"V{version}__*.sql"
            matching_files = list(migration_dir.glob(pattern))
            if not matching_files:
                warnings.append(
                    f"Migration file not found for V{version} ({description})"
                )

    # 汇总结果
    print("\n" + "=" * 60)
    if errors:
        for err in errors:
            log_error(err)
        log_error("Flyway uniqueness check failed!")
        sys.exit(1)

    if warnings:
        for warn in warnings:
            log_warning(warn)

    log_success("Flyway uniqueness check passed!")
    sys.exit(0)


if __name__ == "__main__":
    main()
