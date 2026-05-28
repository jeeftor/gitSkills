.PHONY: install uninstall validate shellcheck vhs vhs-check vhs-validate vhs-one vhs-new demo-check demo-validate demo-record demo-record-one demo-clean

install:
	ASSUME_YES=1 ./scripts/install.sh

uninstall:
	ASSUME_YES=1 ./scripts/uninstall.sh

validate:
	find scripts -type f -name '*.sh' -exec sh -n {} \;
	./scripts/validate-skill-routing.sh
	for skill in skills/*; do ~/.codex/codex-python ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py "$$skill"; done

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
