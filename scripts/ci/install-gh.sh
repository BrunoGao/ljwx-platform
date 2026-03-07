#!/usr/bin/env bash
set -euo pipefail

# Ensure gh CLI is available without requiring sudo.
if command -v gh >/dev/null 2>&1; then
  gh --version | head -n1
  exit 0
fi

for cmd in curl jq tar; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "缺少命令: $cmd" >&2
    exit 1
  }
done

os="$(uname -s | tr '[:upper:]' '[:lower:]')"
arch="$(uname -m)"

if [[ "$os" != "linux" ]]; then
  echo "不支持的系统: $os" >&2
  exit 1
fi

case "$arch" in
  x86_64|amd64) gh_arch="amd64" ;;
  aarch64|arm64) gh_arch="arm64" ;;
  *)
    echo "不支持的架构: $arch" >&2
    exit 1
    ;;
esac

base_tmp="${RUNNER_TEMP:-/tmp}"
bin_dir="${base_tmp}/bin"
mkdir -p "$bin_dir"

tmp_dir="$(mktemp -d "${base_tmp}/gh-install-XXXXXX")"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

api_token="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
api_args=(-fsSL --retry 3 --retry-delay 2 --retry-all-errors)
if [[ -n "$api_token" ]]; then
  api_args+=(-H "Authorization: Bearer ${api_token}" -H "Accept: application/vnd.github+json")
fi
release_json="$(curl "${api_args[@]}" "https://api.github.com/repos/cli/cli/releases/latest")"
tag="$(jq -r '.tag_name // empty' <<<"$release_json")"
if [[ -z "$tag" ]]; then
  echo "无法获取 gh 最新版本标签" >&2
  exit 1
fi

version="${tag#v}"
archive="gh_${version}_${os}_${gh_arch}.tar.gz"
url="https://github.com/cli/cli/releases/download/${tag}/${archive}"

echo "[信息] 安装 gh ${tag} (${os}/${gh_arch})"
curl -fsSL --retry 3 --retry-delay 2 --retry-all-errors -o "${tmp_dir}/${archive}" "$url"
tar -xzf "${tmp_dir}/${archive}" -C "$tmp_dir"
cp "${tmp_dir}/gh_${version}_${os}_${gh_arch}/bin/gh" "${bin_dir}/gh"
chmod +x "${bin_dir}/gh"

if [[ -n "${GITHUB_PATH:-}" ]]; then
  echo "$bin_dir" >> "$GITHUB_PATH"
fi

"${bin_dir}/gh" --version | head -n1
