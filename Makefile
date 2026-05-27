.PHONY: install uninstall validate

install:
	ASSUME_YES=1 ./scripts/install.sh

uninstall:
	ASSUME_YES=1 ./scripts/uninstall.sh

validate:
	for script in scripts/*.sh scripts/git/*.sh; do sh -n "$$script"; done
	for skill in skills/*; do ~/.codex/codex-python ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py "$$skill"; done
