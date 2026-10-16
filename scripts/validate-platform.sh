#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

YAML_PYTHON="${YAML_PYTHON:-python3}"

for tool in kubectl helm find; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: Required tool not found: $tool" >&2
    exit 1
  fi
done

if ! "$YAML_PYTHON" -c 'import yaml' >/dev/null 2>&1; then
  cat >&2 <<'MSG'
ERROR: PyYAML is required for YAML syntax validation.

Create a temporary virtual environment and install it:
  python3 -m venv /tmp/kubeforge-ci-venv
  /tmp/kubeforge-ci-venv/bin/python -m pip install PyYAML==6.0.2
  YAML_PYTHON=/tmp/kubeforge-ci-venv/bin/python ./scripts/validate-platform.sh
MSG
  exit 1
fi

echo "========== 1. YAML SYNTAX =========="
"$YAML_PYTHON" - <<'PY'
from pathlib import Path
import sys
import yaml

root = Path("platform")
files = sorted(
    path for path in root.rglob("*")
    if path.is_file()
    and path.suffix in {".yaml", ".yml"}
    and "templates" not in path.parts
)

if not files:
    print("ERROR: No platform YAML files found")
    sys.exit(1)

errors = []
for path in files:
    try:
        with path.open(encoding="utf-8") as stream:
            list(yaml.safe_load_all(stream))
        print(f"YAML OK: {path}")
    except Exception as exc:
        errors.append((path, exc))
        print(f"YAML FAIL: {path}: {exc}", file=sys.stderr)

if errors:
    print(f"FAILED: {len(errors)} YAML file(s)")
    sys.exit(1)

print(f"PASS: {len(files)} YAML files parsed")
PY

echo
echo "========== 2. KUSTOMIZE RENDERING =========="
kustomize_count=0

while IFS= read -r -d '' file; do
  dir="${file%/*}"
  echo "Rendering: $dir"
  kubectl kustomize "$dir" >/dev/null
  echo "PASS: $dir"
  kustomize_count=$((kustomize_count + 1))
done < <(find platform -name kustomization.yaml -type f -print0 | sort -z)

if [ "$kustomize_count" -eq 0 ]; then
  echo "ERROR: No Kustomize roots found" >&2
  exit 1
fi

echo "PASS: $kustomize_count Kustomize root(s)"

echo
echo "========== 3. HELM CHART VALIDATION =========="
chart_count=0

while IFS= read -r -d '' chart_file; do
  chart_dir="${chart_file%/*}"
  echo "Chart: $chart_dir"

  helm lint "$chart_dir" -f "$chart_dir/values-dev.yaml"
  helm lint "$chart_dir" -f "$chart_dir/values-prod.yaml"

  helm template release-demo "$chart_dir" \
    --namespace kubeforge-helm-lab \
    -f "$chart_dir/values-dev.yaml" >/dev/null

  helm template release-demo "$chart_dir" \
    --namespace kubeforge-helm-lab \
    -f "$chart_dir/values-prod.yaml" >/dev/null

  echo "PASS: Helm lint and template rendering"
  chart_count=$((chart_count + 1))
done < <(find platform -name Chart.yaml -type f -print0 | sort -z)

if [ "$chart_count" -eq 0 ]; then
  echo "ERROR: No Helm charts found" >&2
  exit 1
fi

echo "PASS: $chart_count Helm chart(s)"

echo
echo "========== VALIDATION SUCCEEDED =========="
echo "No Kubernetes resources were applied or changed."
