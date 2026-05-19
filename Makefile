SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c

MAKEFLAGS += --no-print-directory --silent # or '-s'

.PHONY: run auto task-wrapper task update-repo ensure-root install install-auto update upgrade pull pull-force reclone help
.DEFAULT_GOAL := run

COLOR_RED	:=\033[0;31m
COLOR_GREEN	:=\033[0;32m
COLOR_YELLOW:=\033[1;33m
COLOR_BLUE	:=\033[0;34m
COLOR_END	:=\033[0m

export OS_TYPE := $(shell \
	if [ -f /etc/os-release ]; then \
		grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]'; \
	elif [ -f /etc/debian_version ]; then echo "debian"; \
	elif [ -f /etc/redhat-release ]; then echo "rhel"; \
	elif uname -s | grep -q "Darwin"; then echo "macos"; \
	else echo "unknown"; fi \
)

ifneq ($(filter auto install-auto,$(MAKECMDGOALS)),)
    AUTO := 1
#     override ARGS := -y
else ifeq ($(ARGS),-y)
    AUTO := 1
else ifeq ($(AUTO),1)
    AUTO := 1
else
	AUTO := 0
endif

ifeq ($(AUTO),1)
    override ARGS := -y
else
    override ARGS :=
endif

export AUTO
export ARGS

ifneq ($(MAKECMDGOALS),)
    run: update-repo task-wrapper
else ifeq ($(filter run,$(MAKECMDGOALS)),)
    run: update-repo task-wrapper
endif


help: ## - show all targets of makefile
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sed 's/^.*Makefile://g' | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m make %-15s\033[0m %s\n", $$1, $$2}'


run: task-wrapper ## - main run target (default: INTERACTIVE, method: DIRECT)

auto: install-auto ## - alias for install-auto target (default: AUTO, method: INSTALL)

update: update-repo ## - alias for update-repo target

upgrade: update-repo ## - alias for update-repo target


task-wrapper: task ## - (helper) wrapper of 'task' target
	@printf "$(COLOR_GREEN)End of task!$(COLOR_END)\n"

update-repo: ## - manual fetch updates from remote and show changes
	@ans="Y"; \
	if [ "$(ARGS)" != "-y" ] || [ "$(AUTO)" != "1" ]; then \
		printf "$(COLOR_BLUE)[?] Do you want to check and pull updates from remote repository? [Y/n]: $(COLOR_END)"; \
		read -r ans; \
		ans=$${ans:-Y}; \
	fi; \
	if [[ "$$ans" =~ ^[Yy]$$ ]]; then \
		printf "$(COLOR_GREEN)Updating repo from remote...$(COLOR_END)\n"; \
		OLD_HEAD=$$(git rev-parse HEAD 2>/dev/null || echo ""); \
		git pull; \
		NEW_HEAD=$$(git rev-parse HEAD 2>/dev/null || echo ""); \
		if [ "$$OLD_HEAD" != "$$NEW_HEAD" ] && [ -n "$$OLD_HEAD" ]; then \
			printf "$(COLOR_BLUE)[NEW COMMITS DOWNLOADED]:$(COLOR_END)\n"; \
			git log --format="%C(yellow)%h%C(reset) - %an, %ar : %s" "$$OLD_HEAD..$$NEW_HEAD"; \
		else \
			printf "$(COLOR_BLUE)[ALREADY UP TO DATE]. Current commit:$(COLOR_END)\n"; \
			git log -1 --format="%C(yellow)%h%C(reset) - %an, %ar : %s" 2>/dev/null || echo "No commits yet."; \
		fi; \
	else \
		printf "$(COLOR_YELLOW)[SKIPPED] Repository update skipped by user. Current local commit:$(COLOR_END)\n"; \
		git log -1 --format="%C(yellow)%h%C(reset) - %an, %ar : %s" 2>/dev/null || echo "No commits yet."; \
	fi

ensure-root: ## - (helper) root gainer target
	@if [ "$$(id -u)" -ne 0 ]; then \
		printf "$(COLOR_YELLOW)Root privileges are needed. Authentication needed...$(COLOR_END)\n"; \
		export ORIGINAL_USER=$$(whoami); \
		if [ -n "$$DISPLAY" ] && command -v pkexec >/dev/null 2>&1; then \
			pkexec env PATH="$$PATH" ORIGINAL_USER="$$ORIGINAL_USER" AUTO="$(AUTO)" ARGS="$(ARGS)" $(MAKE) -C "$$PWD" task; \
		elif command -v sudo >/dev/null 2>&1; then \
			sudo -E env ORIGINAL_USER="$$ORIGINAL_USER" AUTO="$(AUTO)" ARGS="$(ARGS)" $(MAKE) -C "$$PWD" task; \
		elif command -v su >/dev/null 2>&1; then \
			printf "$(COLOR_YELLOW)[WARNING]: 'pkexec' and 'sudo' are missing. Falling back to 'su'...\nEnvironment variables might not be preserved! Exporting environment variables manually...$(COLOR_END)\n"; \
			su -c "export ORIGINAL_USER='$$ORIGINAL_USER'; export AUTO='$(AUTO)'; export ARGS='$(ARGS)'; $(MAKE) -C '$$PWD' task"; \
		else \
			printf "$(COLOR_RED)[ERROR]: None of 'pkexec', 'sudo' or 'su' packages were found (for gaining privileges).$(COLOR_END)\n"; \
			exit 1; \
		fi; \
		exit $$?; \
	fi

task: ## - core task
	@if [ "$$(id -u)" -ne 0 ]; then \
		$(MAKE) ensure-root; \
	else \
		printf "$(COLOR_GREEN)Current user: $$(whoami) (UID: $$(id -u))$(COLOR_END)\n"; \
		chmod +x "$$PWD/scripts/start.sh"; \
		printf "$(COLOR_GREEN)Made '$$PWD/scripts/start.sh' executable.$(COLOR_END)\n"; \
		printf "$(COLOR_GREEN)Running ./scripts/start.sh...$(COLOR_END)\n"; \
		if command -v bash >/dev/null 2>&1; then \
			AUTO="$(AUTO)" bash "$$PWD/scripts/start.sh"; \
		else \
			AUTO="$(AUTO)" sh "$$PWD/scripts/start.sh"; \
		fi; \
	fi

install: ## - install with helper 'install.sh' in 'INTERACTIVE mode'
	@chmod +x "$$PWD/install.sh"
	@printf "$(COLOR_GREEN)Made '$$PWD/install.sh' executable.$(COLOR_END)\n"
	@printf "$(COLOR_GREEN)Running ./install.sh in interactive mode...$(COLOR_END)\n"
	@if command -v bash >/dev/null 2>&1; then \
		AUTO="0" bash "$$PWD/install.sh"; \
	else \
		AUTO="0" sh "$$PWD/install.sh"; \
	fi

install-auto: ## - install with helper 'install.sh' in 'AUTO mode' (-y)
	@chmod +x "$$PWD/install.sh"
	@printf "$(COLOR_GREEN)Made '$$PWD/install.sh' executable.$(COLOR_END)\n"
	@printf "$(COLOR_GREEN)Running ./install.sh in auto mode...$(COLOR_END)\n"
	@if command -v bash >/dev/null 2>&1; then \
		AUTO="1" bash "$$PWD/install.sh" -y; \
	else \
		AUTO="1" sh "$$PWD/install.sh" -y; \
	fi

pull: ## - pull from remote to local (soft)
	@git pull

pull-force: ## - hard pull from remote to local (overwrite)
	@git fetch --all
	@git reset --hard origin/$$(git branch --show-current)

reclone: ## - delete cloned repo and clone again
	@REPO_NAME=$$(basename "$$(git rev-parse --show-toplevel 2>/dev/null || echo "")") ; \
	REPO_URL=$$(git config --get remote.origin.url 2>/dev/null || echo "") ; \
	if [ -z "$$REPO_NAME" ] || [ -z "$$REPO_URL" ]; then \
		printf "$(COLOR_RED)[ERROR] Nor a git repository or remote URL is missing!$(COLOR_END)\n"; \
		exit 1; \
	fi; \
	echo "1: Data collected. Name: $$REPO_NAME" ; \
	cd ../ && \
	echo "2: Moved to parent directory" && \
	rm -rf "./$$REPO_NAME" && \
	echo "3: Old directory removed safely" && \
	git clone "$$REPO_URL" "$$REPO_NAME" && \
	echo "4: Clone completed successfully!"
