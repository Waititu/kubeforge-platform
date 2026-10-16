#!/usr/bin/env python3
"""Validate security properties of rendered production workloads."""

from pathlib import Path
import sys

import yaml

WORKLOAD_KINDS = {
    "Deployment",
    "StatefulSet",
    "DaemonSet",
    "Job",
    "CronJob",
}


def check_documents(documents):
    errors = []
    workload_count = 0

    for doc in documents:
        if not isinstance(doc, dict):
            continue

        kind = doc.get("kind")
        if kind not in WORKLOAD_KINDS:
            continue

        metadata = doc.get("metadata") or {}
        name = metadata.get("name", "<unnamed>")

        spec = doc.get("spec") or {}
        if kind == "CronJob":
            pod_spec = (
                ((spec.get("jobTemplate") or {}).get("spec") or {})
                .get("template", {})
                .get("spec", {})
            )
        else:
            pod_spec = (
                (spec.get("template") or {}).get("spec") or {}
            )

        containers = pod_spec.get("containers") or []
        if not containers:
            errors.append(f"{kind}/{name}: no containers found")
            continue

        workload_count += 1
        pod_security = pod_spec.get("securityContext") or {}

        for container in containers:
            cname = container.get("name", "<unnamed-container>")
            prefix = f"{kind}/{name} container/{cname}"
            security = container.get("securityContext") or {}

            image = container.get("image", "")
            if not image:
                errors.append(f"{prefix}: image is missing")
            elif "@sha256:" not in image:
                tag = image.rsplit("/", 1)[-1].rsplit(":", 1)
                if len(tag) == 1 or tag[-1] in {"", "latest"}:
                    errors.append(
                        f"{prefix}: image must use a non-latest tag "
                        "or a sha256 digest"
                    )

            run_as_non_root = security.get(
                "runAsNonRoot", pod_security.get("runAsNonRoot")
            )
            run_as_user = security.get(
                "runAsUser", pod_security.get("runAsUser")
            )
            if run_as_non_root is not True and not (
                isinstance(run_as_user, int) and run_as_user > 0
            ):
                errors.append(
                    f"{prefix}: must enforce a non-root user"
                )

            if security.get("allowPrivilegeEscalation") is not False:
                errors.append(
                    f"{prefix}: allowPrivilegeEscalation must be false"
                )

            if security.get("readOnlyRootFilesystem") is not True:
                errors.append(
                    f"{prefix}: readOnlyRootFilesystem must be true"
                )

            capabilities = security.get("capabilities") or {}
            dropped = capabilities.get("drop") or []
            if "ALL" not in dropped:
                errors.append(
                    f"{prefix}: capabilities.drop must include ALL"
                )

    if workload_count == 0:
        errors.append("No supported production workloads were found")

    return errors


def main():
    if len(sys.argv) == 2 and sys.argv[1] == "--self-test":
        insecure_fixture = [{
            "apiVersion": "apps/v1",
            "kind": "Deployment",
            "metadata": {"name": "intentionally-insecure"},
            "spec": {
                "template": {
                    "spec": {
                        "containers": [{
                            "name": "app",
                            "image": "example.invalid/app:latest",
                        }]
                    }
                }
            },
        }]

        errors = check_documents(insecure_fixture)
        if not errors:
            print("FAIL: insecure fixture was incorrectly accepted")
            return 1

        print(
            "PASS: insecure fixture rejected "
            f"({len(errors)} policy violation(s))"
        )
        return 0

    if len(sys.argv) != 2:
        print(
            "Usage: check-production-policy.py "
            "<rendered-production.yaml> | --self-test",
            file=sys.stderr,
        )
        return 2

    path = Path(sys.argv[1])
    try:
        with path.open(encoding="utf-8") as stream:
            documents = list(yaml.safe_load_all(stream))
    except (OSError, yaml.YAMLError) as exc:
        print(f"ERROR: unable to read rendered YAML: {exc}", file=sys.stderr)
        return 2

    errors = check_documents(documents)
    if errors:
        for error in errors:
            print(f"POLICY FAIL: {error}", file=sys.stderr)
        print(f"FAIL: {len(errors)} policy violation(s)", file=sys.stderr)
        return 1

    print("PASS: production workload security policy")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
