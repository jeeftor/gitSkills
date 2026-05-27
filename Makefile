.PHONY: install uninstall validate

install:
	ASSUME_YES=1 ./scripts/install.sh

uninstall:
	ASSUME_YES=1 ./scripts/uninstall.sh

validate:
	sh -n scripts/install.sh
	sh -n scripts/uninstall.sh
	for skill in skills/*; do ~/.codex/codex-python ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py "$$skill"; done

