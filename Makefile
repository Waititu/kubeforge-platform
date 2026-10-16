SHELL := /bin/bash
.DEFAULT_GOAL := help

YAML_PYTHON ?= python3
export YAML_PYTHON

.PHONY: help validate policy-test

help:
	@echo "KubeForge development commands:"
	@echo "  make validate     Run all local validation gates"
	@echo "  make policy-test  Test that insecure configuration is rejected"
	@echo "  make help         Show this help"

validate:
	bash scripts/validate-platform.sh

policy-test:
	$(YAML_PYTHON) scripts/check-production-policy.py --self-test
