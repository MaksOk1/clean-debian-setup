SHELL := /usr/bin/env bash

MAKEFLAGS += --no-print-directory --silent # or '-s'

.PHONY: run task-wrapper task update-repo ensure-root install install-auto
.DEFAULT_GOAL := run

COLOR_RED=\\e[31m
COLOR_GREEN=\\e[32m
COLOR_YELLOW=\\e[33m
COLOR_BLUE=\\e[34m
COLOR_END=\\e[0m

ifeq ($(ARGS),-y)
    override AUTO := 1
endif
ifeq ($(AUTO),1)
    override ARGS := -y
else
override AUTO := 0
override ARGS :=
endif

help: ## - show all targets of makefile
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sed 's/^.*Makefile://g' | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m make %-15s\033[0m %s\n", $$1, $$2}'

run: update-repo task-wrapper ## - main run target (INTERACTIVE)

auto: install-auto ## - alias (1) for install-auto target (AUTO)

update: update-repo ## - alias (1) for update-repo target

upgrade: update-repo ## - alias (2) for update-repo target


task-wrapper: task ## - (helper) wrapper of 'task' target
	@printf "$(COLOR_GREEN)End of task!$(COLOR_END)\n"

update-repo: ## - manual fetch updates from remote and show changes
	@if [ "$(ARGS)" = "-y" ] || [ "$(AUTO)" = "1" ]; then \
		ans="Y"; \
	else \
		printf "$(COLOR_BLUE)[?] Do you want to check and pull updates from remote repository? [Y/n]: $(COLOR_END)"; \
		read -r ans; \
		ans=$${ans:-Y}; \
	fi; \
	if [[ "$$ans" =~ ^[Yy]$$ ]]; then \
		printf "$(COLOR_GREEN)Updating repo from remote...$(COLOR_END)\n"; \
		OLD_HEAD=$$(git rev-parse HEAD 2>/dev/null); \
		git pull; \
		NEW_HEAD=$$(git rev-parse HEAD 2>/dev/null); \
		if [ "$$OLD_HEAD" != "$$NEW_HEAD" ]; then \
			printf "$(COLOR_BLUE)[NEW COMMITS DOWNLOADED]:$(COLOR_END)\n"; \
			git log --format="%C(yellow)%h%C(reset) - %an, %ar : %s" $$OLD_HEAD..$$NEW_HEAD; \
		else \
			printf "$(COLOR_BLUE)[ALREADY UP TO DATE]. Current commit:$(COLOR_END)\n"; \
			git log -1 --format="%C(yellow)%h%C(reset) - %an, %ar : %s"; \
		fi; \
	else \
		printf "$(COLOR_YELLOW)[SKIPPED] Repository update skipped by user. Current local commit:$(COLOR_END)\n"; \
		git log -1 --format="%C(yellow)%h%C(reset) - %an, %ar : %s"; \
	fi

ensure-root: ## - (helper) root gainer target
	@if [ "$$(id -u)" -ne 0 ]; then \
		printf "$(COLOR_YELLOW)Root privileges are needed. Authentication needed...$(COLOR_END)\n"; \
		export ORIGINAL_USER=$$(whoami); \
		if [ -n "$$DISPLAY" ] && command -v pkexec >/dev/null 2>&1; then \
			pkexec env PATH="$$PATH" ORIGINAL_USER="$$ORIGINAL_USER" AUTO="$(AUTO)" ARGS="$(ARGS)" $(MAKE) -C "$$PWD" task AUTO="$(AUTO)" ARGS="$(ARGS)"; \
		elif command -v sudo >/dev/null 2>&1; then \
			sudo -E env ORIGINAL_USER="$$ORIGINAL_USER" AUTO="$(AUTO)" ARGS="$(ARGS)" $(MAKE) -C "$$PWD" task AUTO="$(AUTO)" ARGS="$(ARGS)"; \
		elif command -v su >/dev/null 2>&1; then \
			printf "$(COLOR_YELLOW)[WARNING]: 'pkexec' and 'sudo' are missing. Falling back to 'su'. Environment variables might not be preserved! Exporting environment variables manually...$(COLOR_END)\n"; \
			su -c "export ORIGINAL_USER='$$ORIGINAL_USER'; export AUTO='$(AUTO)'; export ARGS='$(ARGS)'; $(MAKE) -C '$$PWD' task AUTO='$(AUTO)' ARGS='$(ARGS)'"; \
		else \
			printf "$(COLOR_RED)[ERROR]: None of 'pkexec', 'sudo' or 'su' packages were found for gaining privileges.$(COLOR_END)\n"; \
			exit 1; \
		fi; \
		exit $$?; \
	fi

task: ## - core task
	@if [ "$$(id -u)" -ne 0 ]; then \
		$(MAKE) ensure-root AUTO="$(AUTO)" ARGS='$(ARGS)'; \
	else \
		printf "$(COLOR_GREEN)Current user: $$(whoami) (UID: $$(id -u))$(COLOR_END)\n"; \
		chmod +x "$$PWD/scripts/start.sh"; \
		printf "$(COLOR_GREEN)Made '$$PWD/scripts/start.sh' executable. Running it...$(COLOR_END)\n"; \
		IS_AUTO=0; if [ "$(AUTO)" = "1" ] || [ "$(ARGS)" = "-y" ]; then IS_AUTO=1; fi; \
		if command -v bash >/dev/null 2>&1; then \
			AUTO="$$IS_AUTO" bash "$$PWD/scripts/start.sh"; \
		else \
			AUTO="$$IS_AUTO" sh "$$PWD/scripts/start.sh"; \
		fi; \
	fi

install: ## - install with helper 'install.sh' in 'INTERACTIVE mode'
	@$(MAKE) update-repo
	@$(MAKE) ensure-root AUTO="0" ARGS=""
	@printf "$(COLOR_GREEN)Current user: $$(whoami) (UID: $$(id -u))$(COLOR_END)\n"
	@chmod +x "$$PWD/install.sh"
	@printf "$(COLOR_GREEN)Made '$$PWD/install.sh' executable. Running it...$(COLOR_END)\n"
	@if command -v bash >/dev/null 2>&1; then \
		AUTO="0" bash "$$PWD/install.sh"; \
	else \
		AUTO="0" sh "$$PWD/install.sh"; \
	fi

install-auto: ## - install with helper 'install.sh' in 'AUTO mode'
	@$(MAKE) update-repo
	@$(MAKE) ensure-root AUTO="1" ARGS="-y"
	@printf "$(COLOR_GREEN)Current user: $$(whoami) (UID: $$(id -u))$(COLOR_END)\n"
	@chmod +x "$$PWD/install.sh"
	@printf "$(COLOR_GREEN)Made '$$PWD/install.sh' executable. Running it...$(COLOR_END)\n"
	@if command -v bash >/dev/null 2>&1; then \
		AUTO="1" bash "$$PWD/install.sh -y"; \
	else \
		AUTO="1" sh "$$PWD/install.sh -y"; \
	fi

pull: ## - pull from remote to local (soft)
	@git pull

pull-force: ## - pull from remote to local (overwrite)
	@git fetch --all
	@git reset --hard origin/$$(git branch --show-current)

reclone: ## - delete cloned repo and clone again
	@export REPO_NAME=$$(basename `git rev-parse --show-toplevel 2>/dev/null`) ; \
	export REPO_URL=$$(git config --get remote.origin.url 2>/dev/null) ; \
	if [ -z "$$REPO_NAME" ] || [ -z "$$REPO_URL" ]; then \
		printf "$(COLOR_RED)[ERROR] Nor a git repository or remote URL is missing!$(COLOR_END)\n"; \
		exit 1; \
	fi; \
	echo "1: Data collected. Name: $$REPO_NAME" ; \
	cd ../ ; \
	echo "2: Moved to parent directory" ; \
	rm -rf "./$$REPO_NAME" ; \
	echo "3: Old directory removed safely" ; \
	git clone "$$REPO_URL" "$$REPO_NAME" ; \
	echo "4: Clone completed successfully!"
