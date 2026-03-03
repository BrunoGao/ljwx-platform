#!/usr/bin/env python3
"""
Spec Quality Gate - 检查 Phase spec 是否符合 Registry 约束
"""

import re
import sys
import yaml
from pathlib import Path
from typing import List


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


def is_label_context(content: str, label: str) -> bool:
    """Match blacklisted tokens only in label-like context, not generic prose/DB fields."""
    escaped = re.escape(label)
    patterns = [
        rf"`{escaped}`\s*(?:label|labels)\b",
        rf"\blabels?\s*[:=]\s*[^\n]{{0,120}}\b{escaped}\b",
        rf"\b(?:label|labels)\b[^\n]{{0,60}}\b{escaped}\b",
    ]
    return any(re.search(p, content, re.IGNORECASE) for p in patterns)
# 加载 Registry 文件
def load_registry(registry_path: str) -> dict:
    """加载 YAML registry 文件"""
    try:
        with open(registry_path, "r", encoding="utf-8") as f:
            return yaml.safe_load(f)
    except Exception as e:
        log_error(f"Failed to load {registry_path}: {e}")
        sys.exit(1)


# 检查权限字符串
def check_permissions(spec_files: List[Path], permissions_registry: dict) -> bool:
    """检查 spec 中的权限是否在 permissions.yml 中注册"""
    log_info("Checking permissions...")

    # 提取所有注册的权限
    registered_permissions = set()
    for perm in permissions_registry.get("permissions", []):
        registered_permissions.add(perm["code"])

    errors = []
    # 扫描所有 spec 文件
    for spec_file in spec_files:
        with open(spec_file, "r", encoding="utf-8") as f:
            content = f.read()

            # 匹配权限字符串 (格式: resource:action)
            # 例如: system:user:list, tenant:config:edit
            perm_pattern = r"`([a-z_]+:[a-z_]+:[a-z_]+)`"
            matches = re.findall(perm_pattern, content)

            for perm in matches:
                if perm not in registered_permissions:
                    errors.append(
                        f"{spec_file.name}: Permission '{perm}' not registered in permissions.yml"
                    )

    if errors:
        for err in errors:
            log_error(err)
        return False
    else:
        log_success(
            f"All permissions are registered ({len(registered_permissions)} total)"
        )
        return True


# 检查 Flyway 版本号
def check_flyway_versions(spec_files: List[Path], migrations_registry: dict) -> bool:
    """检查 spec 中的 Flyway 版本号是否在 migrations.yml 中注册"""
    log_info("Checking Flyway versions...")

    # 提取所有注册的版本号
    registered_versions = set()
    for migration in migrations_registry.get("migrations", []):
        registered_versions.add(migration["version"])

    errors = []

    # 扫描所有 spec 文件
    for spec_file in spec_files:
        with open(spec_file, "r", encoding="utf-8") as f:
            content = f.read()

            # 匹配 Flyway 版本号 (格式: V033, V034)
            version_pattern = r"V(\d{3})"
            matches = re.findall(version_pattern, content)

            for version in matches:
                if version not in registered_versions:
                    errors.append(
                        f"{spec_file.name}: Flyway version 'V{version}' not registered in migrations.yml"
                    )

    if errors:
        for err in errors:
            log_error(err)
        return False
    else:
        log_success(
            f"All Flyway versions are registered ({len(registered_versions)} total)"
        )
        return True


# 检查可观测性 label
def check_observability_labels(
    spec_files: List[Path], observability_registry: dict
) -> bool:
    """检查 spec 中的 Loki/Prometheus label 是否符合白名单"""
    log_info("Checking observability labels...")

    # 提取白名单和黑名单
    loki_blacklist = set(observability_registry["loki"]["labels_blacklist"])
    prom_blacklist = set(observability_registry["prometheus"]["labels_blacklist"])

    errors = []

    # 扫描所有 spec 文件
    for spec_file in spec_files:
        with open(spec_file, "r", encoding="utf-8") as f:
            content = f.read()

            # 检查 Loki labels
            if "Loki" in content or "loki" in content:
                for label in loki_blacklist:
                    if is_label_context(content, label):
                        errors.append(
                            f"{spec_file.name}: Loki label '{label}' is blacklisted (high cardinality)"
                        )

            # 检查 Prometheus labels
            if "Prometheus" in content or "prometheus" in content:
                for label in prom_blacklist:
                    if is_label_context(content, label):
                        errors.append(
                            f"{spec_file.name}: Prometheus label '{label}' is blacklisted (high cardinality)"
                        )

    if errors:
        for err in errors:
            log_error(err)
        return False
    else:
        log_success("All observability labels are compliant")
        return True


def main():
    # 项目根目录
    root_dir = Path(__file__).parent.parent
    spec_dir = root_dir / "spec"
    registry_dir = spec_dir / "registry"

    # 加载 Registry 文件
    permissions_registry = load_registry(registry_dir / "permissions.yml")
    migrations_registry = load_registry(registry_dir / "migrations.yml")
    observability_registry = load_registry(registry_dir / "observability.yml")

    # 扫描所有 Phase spec 文件
    spec_files = list(spec_dir.glob("phase/*.md"))
    log_info(f"Found {len(spec_files)} spec files")

    # 执行检查
    checks = [
        check_permissions(spec_files, permissions_registry),
        check_flyway_versions(spec_files, migrations_registry),
        check_observability_labels(spec_files, observability_registry),
    ]

    # 汇总结果
    print("\n" + "=" * 60)
    if all(checks):
        log_success("All spec quality checks passed!")
        sys.exit(0)
    else:
        log_error("Some spec quality checks failed!")
        sys.exit(1)


if __name__ == "__main__":
    main()
