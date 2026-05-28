.DEFAULT_GOAL := help

.PHONY: help install uninstall validate ci test-helpers shellcheck vhs vhs-check vhs-validate vhs-one vhs-new demo-check demo-validate demo-record demo-record-one demo-clean

help:
	@printf 'Usage: make <target>\n\n'
	@printf 'Targets:\n'
	@printf '  install          Install the local Git skills\n'
	@printf '  uninstall        Uninstall the local Git skills\n'
	@printf '  validate         Run script syntax, skill routing, skill, and helper tests\n'
	@printf '  ci               Run GitHub Actions-safe validation\n'
	@printf '  test-helpers     Run local helper tests\n'
	@printf '  shellcheck       Run shellcheck across scripts\n'
	@printf '  vhs              Render all VHS demos\n'
	@printf '  vhs-check        Check VHS demo outputs\n'
	@printf '  vhs-validate     Validate VHS demos\n'
	@printf '  vhs-one          Render one VHS demo with DEMO=<name>\n'
	@printf '  vhs-new          Create one VHS demo with DEMO=<name>\n'
	@printf '  demo-check       Check rendered demo outputs\n'
	@printf '  demo-validate    Validate demos\n'
	@printf '  demo-record      Record all demos\n'
	@printf '  demo-record-one  Record one demo with DEMO=<name>\n'
	@printf '  demo-clean       Remove generated demo outputs\n'

install:
	ASSUME_YES=1 ./scripts/install.sh

uninstall:
	ASSUME_YES=1 ./scripts/uninstall.sh

validate:
	find scripts -type f -name '*.sh' -exec sh -n {} \;
	./scripts/validate-skill-routing.sh
	for skill in skills/*; do ~/.codex/codex-python ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py "$$skill"; done
	./scripts/tests/test-local-helpers.sh

ci:
	find scripts -type f -name '*.sh' -exec sh -n {} \;
	./scripts/validate-skill-routing.sh
	./scripts/tests/test-local-helpers.sh
	$(MAKE) shellcheck

test-helpers:
	./scripts/tests/test-local-helpers.sh

shellcheck:
	find scripts -type f -name '*.sh' -exec shellcheck {} +

vhs:
	./scripts/vhs/render.sh --all

vhs-check:
	./scripts/vhs/render.sh --check

vhs-validate:
	./scripts/vhs/render.sh --validate

vhs-one:
	./scripts/vhs/render.sh --demo "$(DEMO)"

vhs-new:
	./scripts/vhs/new-demo.sh "$(DEMO)"

demo-check:
	./scripts/demos/render-demo.sh --check

demo-validate:
	./scripts/demos/render-demo.sh --validate

demo-record:
	./scripts/demos/render-demo.sh --all

demo-record-one:
	./scripts/demos/render-demo.sh --demo "$(DEMO)"

demo-clean:
	rm -f docs/demos/output/*
