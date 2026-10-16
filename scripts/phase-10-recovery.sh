#!/usr/bin/env bash
set -Eeuo pipefail

NS="kubeforge-dr-lab"
PHASE="platform/kubernetes/recovery/phase-10-disaster-recovery"
SCENARIO="${1:-help}"

die() { echo "FAIL: $*" >&2; exit 1; }
need_lab() {
  kubectl get namespace "$NS" >/dev/null 2>&1 ||
    die "Namespace $NS does not exist. Deploy the lab first."
}
assert_lab_deployment() {
  local actual
  actual="$(kubectl -n "$NS" get deployment dr-web \
    -o jsonpath='{.metadata.labels.kubeforge\.io/phase}' 2>/dev/null || true)"
  [[ "$actual" == "10" ]] ||
    die "Refusing to act: dr-web is not labelled as a Phase 10 resource."
}
case "$SCENARIO" in
  self-heal)
    need_lab
    assert_lab_deployment
    kubectl -n "$NS" rollout status deployment/dr-web --timeout=120s
    before="$(kubectl -n "$NS" get pods -l app.kubernetes.io/name=dr-web \
      -o jsonpath='{.items[*].metadata.name}')"
    [[ -n "$before" ]] || die "No lab pods found."
    victim="$(printf '%s\n' $before | head -n 1)"
    echo "Deleting lab pod only: $victim"
    started="$(date +%s)"
    kubectl -n "$NS" delete pod "$victim" --wait=true
    kubectl -n "$NS" rollout status deployment/dr-web --timeout=120s
    kubectl -n "$NS" wait --for=condition=Ready pod \
      -l app.kubernetes.io/name=dr-web --timeout=120s
    kubectl -n "$NS" get deployment dr-web
    echo "Recovery elapsed seconds: $(( $(date +%s) - started ))"
    echo "PASS: the lab Deployment is ready after pod deletion."
    ;;
  rollback)
    need_lab
    assert_lab_deployment
    kubectl -n "$NS" rollout status deployment/dr-web --timeout=120s
    old_image="$(kubectl -n "$NS" get deployment dr-web \
      -o jsonpath='{.spec.template.spec.containers[?(@.name=="nginx")].image}')"
    [[ -n "$old_image" ]] || die "Could not read the original image."
    echo "Known-good image: $old_image"
    started="$(date +%s)"
    # A deliberately nonexistent tag, isolated to the Phase 10 Deployment.
    kubectl -n "$NS" set image deployment/dr-web \
      nginx=nginx:kubeforge-phase10-intentionally-missing
    if kubectl -n "$NS" rollout status deployment/dr-web --timeout=75s; then
      echo "WARNING: rollout unexpectedly succeeded; no rollback needed."
      exit 1
    fi
    echo "Expected failure observed. Rolling back lab Deployment."
    kubectl -n "$NS" rollout undo deployment/dr-web
    kubectl -n "$NS" rollout status deployment/dr-web --timeout=150s
    restored="$(kubectl -n "$NS" get deployment dr-web \
      -o jsonpath='{.spec.template.spec.containers[?(@.name=="nginx")].image}')"
    [[ "$restored" == "$old_image" ]] ||
      die "Rollback image mismatch: expected $old_image, got $restored"
    kubectl -n "$NS" get deployment dr-web
    echo "Recovery elapsed seconds: $(( $(date +%s) - started ))"
    echo "PASS: the known-good image was restored."
    ;;
  data-recovery)
    need_lab
    # Only this explicitly named Job in the Phase 10 namespace is replaced.
    kubectl -n "$NS" delete job dr-data-recovery --ignore-not-found=true
    kubectl -n "$NS" apply -f "$PHASE/data-recovery-job.yaml"
    started="$(date +%s)"
    kubectl -n "$NS" wait --for=condition=Complete job/dr-data-recovery \
      --timeout=180s
    kubectl -n "$NS" logs job/dr-data-recovery
    echo "Recovery elapsed seconds: $(( $(date +%s) - started ))"
    echo "PASS: backup/restore integrity test completed."
    ;;
  status)
    need_lab
    kubectl -n "$NS" get all,pvc
    kubectl -n "$NS" get events --sort-by=.lastTimestamp | tail -20
    ;;
  help|*)
    cat <<'HELP'
Phase 10 recovery scenarios:
  self-heal       Delete one lab pod and verify controller recovery.
  rollback        Inject a bad image and roll back the lab Deployment.
  data-recovery   Back up, remove, and restore a test record.
  status          Show lab resources and recent events.
Run from the repository root. All destructive actions are restricted to
named resources in kubeforge-dr-lab.
HELP
    [[ "$SCENARIO" == "help" ]] || exit 2
    ;;
esac
