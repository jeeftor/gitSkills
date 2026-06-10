.DEFAULT_GOAL := help

.PHONY: help install uninstall legacy-install legacy-uninstall validate ci test-helpers plugin-install plugin-refresh plugin-validate plugin-smoke shellcheck vhs vhs-check vhs-validate vhs-one vhs-new demo-check demo-validate demo-record demo-record-one demo-clean

help:
	@printf 'Codex Git Workflow plugin\n'
	@printf '\n'
	@printf 'Usage:\n'
	@printf '  make <target>\n'
	@printf '\n'
	@printf 'Normal plugin workflow:\n'
	@printf '  make plugin-install\n'
	@printf '      Install this checkout as git-skills@git-skills-local through a local\n'
	@printf '      marketplace at ~/.agents/git-skills-marketplace.\n'
	@printf '  make plugin-refresh\n'
	@printf '      After changing skills, docs, helpers, or plugin metadata, bump the Codex\n'
	@printf '      cachebuster, reinstall the plugin, then start a new Codex thread.\n'
	@printf '  SKIP_CACHEBUSTER=1 make plugin-refresh\n'
	@printf '      Reinstall without changing the manifest version.\n'
	@printf '  MARKETPLACE_ROOT=/path/to/root make plugin-install\n'
	@printf '      Use a custom local marketplace root.\n'
	@printf '  MARKETPLACE_NAME=name make plugin-install\n'
	@printf '      Use a custom marketplace name for the local install.\n'
	@printf '\n'
	@printf 'Validation:\n'
	@printf '  make validate         Run full local validation for this repo\n'
	@printf '  make ci               Run GitHub Actions-safe validation\n'
	@printf '  make plugin-validate  Validate plugin metadata and packaging\n'
	@printf '  make plugin-smoke     Install into a temporary Codex home\n'
	@printf '  make test-helpers     Run local helper JSON smoke tests\n'
	@printf '  make shellcheck       Run shellcheck across scripts\n'
	@printf '\n'
	@printf 'Legacy direct skill install:\n'
	@printf '  make legacy-install   Copy raw skills to ~/.agents/skills\n'
	@printf '  make legacy-uninstall Remove raw skills and ~/.agents/gitSkills assets\n'
	@printf '  make install          Compatibility alias for legacy-install\n'
	@printf '  make uninstall        Compatibility alias for legacy-uninstall\n'
	@printf '      Prefer plugin-install unless you intentionally need the old direct\n'
	@printf '      skill-folder layout.\n'
	@printf '\n'
	@printf 'Demos and recordings:\n'
	@printf '  make vhs              Render all VHS demos\n'
	@printf '  make vhs-check        Check VHS demo outputs\n'
	@printf '  make vhs-validate     Validate VHS demos\n'
	@printf '  make vhs-one DEMO=<name>\n'
	@printf '      Render one VHS demo.\n'
	@printf '  make vhs-new DEMO=<name>\n'
	@printf '      Create one VHS demo.\n'
	@printf '  make demo-check       Check rendered demo outputs\n'
	@printf '  make demo-validate    Validate demos\n'
	@printf '  make demo-record      Record all demos\n'
	@printf '  make demo-record-one DEMO=<name>\n'
	@printf '      Record one demo.\n'
	@printf '  make demo-clean       Remove generated demo outputs\n'

install:
	$(MAKE) legacy-install

uninstall:
	$(MAKE) legacy-uninstall

legacy-install:
	ASSUME_YES=1 ./scripts/install.sh

legacy-uninstall:
	ASSUME_YES=1 ./scripts/uninstall.sh

validate:
	find scripts -type f -name '*.sh' -exec sh -n {} \;
	./scripts/validate-skill-routing.sh
	./scripts/validate-plugin-packaging.sh
	sh ./scripts/tests/test-validate-skill-routing.sh
	~/.codex/codex-python ~/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py .
	for skill in skills/*; do ~/.codex/codex-python ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py "$$skill"; done
	./scripts/tests/test-local-helpers.sh

ci:
	find scripts -type f -name '*.sh' -exec sh -n {} \;
	./scripts/validate-skill-routing.sh
	./scripts/validate-plugin-packaging.sh
	sh ./scripts/tests/test-validate-skill-routing.sh
	./scripts/tests/test-local-helpers.sh
	$(MAKE) shellcheck

test-helpers:
	./scripts/tests/test-local-helpers.sh

plugin-install:
	./scripts/plugin/install-local.sh

plugin-refresh:
	./scripts/plugin/refresh-local.sh

plugin-validate:
	./scripts/validate-plugin-packaging.sh
	~/.codex/codex-python ~/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py .

plugin-smoke:
	./scripts/tests/test-plugin-smoke-install.sh

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
