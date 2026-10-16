#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

YAML_PYTHON="${YAML_PYTHON:-python3}"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

for tool in kubectl helm kubeconform find; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: Required tool not found: $tool" >&2
    echo "See README.md for local prerequisites." >&2
    exit 1
  fi
done

if ! "$YAML_PYTHON" -c 'import yaml' >/dev/null 2>&1; then
  echo "ERROR: PyYAML is required. See README.md." >&2
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
echo "========== 2. KUSTOMIZE + SCHEMA VALIDATION =========="
kustomize_count=0

while IFS= read -r -d '' file; do
  dir="${file%/*}"
  output="$TEMP_DIR/kustomize-${kustomize_count}.yaml"

  echo "Rendering: $dir"
  kubectl kustomize "$dir" > "$output"

  kubeconform \
    -strict \
    -ignore-missing-schemas \
    -summary \
    "$output"

  echo "PASS: $dir"
  kustomize_count=$((kustomize_count + 1))
done < <(find platform -name kustomization.yaml -type f -print0 | sort -z)

if [ "$kustomize_count" -eq 0 ]; then
  echo "ERROR: No Kustomize roots found" >&2
  exit 1
fi

echo "PASS: $kustomize_count Kustomize root(s)"

echo
echo "========== 3. HELM + SCHEMA VALIDATION =========="
chart_count=0

while IFS= read -r -d '' chart_file; do
  chart_dir="${chart_file%/*}"
  echo "Chart: $chart_dir"

  for environment in dev prod; do
    values_file="$chart_dir/values-${environment}.yaml"
    rendered="$TEMP_DIR/helm-${chart_count}-${environment}.yaml"

    if [ ! -f "$values_file" ]; then
      echo "ERROR: Missing values file: $values_file" >&2
      exit 1
    fi

    helm lint "$chart_dir" -f "$values_file"

    helm template release-demo "$chart_dir" \
      --namespace kubeforge-helm-lab \
      -f "$values_file" > "$rendered"

    kubeconform \
      -strict \
      -ignore-missing-schemas \
      -summary \
      "$rendered"

    echo "PASS: Helm $environment rendering and schemas"
  done

  chart_count=$((chart_count + 1))
done < <(find platform -name Chart.yaml -type f -print0 | sort -z)

if [ "$chart_count" -eq 0 ]; then
  echo "ERROR: No Helm charts found" >&2
  exit 1
fi

echo "PASS: $chart_count Helm chart(s)"

echo
echo "========== 4. PRODUCTION SECURITY POLICY =========="
prod_render="$TEMP_DIR/production-overlay.yaml"

kubectl kustomize \
  platform/gitops/kustomize/release-demo/overlays/prod \
  > "$prod_render"

"$YAML_PYTHON" scripts/check-production-policy.py "$prod_render"

echo
echo "========== 5. POLICY NEGATIVE TEST =========="
"$YAML_PYTHON" scripts/check-production-policy.py --self-test

echo
echo "========== VALIDATION SUCCEEDED =========="
echo "No Kubernetes resources were applied or changed."
