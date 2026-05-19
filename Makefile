SHELL := /usr/bin/bash

MAKEFLAGS += --no-print-directory --silent # or '-s'

.PHONY: run task-wrapper task update-repo ensure-root install install-auto

COLOR_RED=\\e[31m
COLOR_GREEN=\\e[32m
COLOR_YELLOW=\\e[33m
COLOR_BLUE=\\e[34m
COLOR_END=\\e[0m

run: update-repo task-wrapper

task-wrapper: task
	@printf "$(COLOR_GREEN)End of task!$(COLOR_END)\n"

update-repo:
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

ensure-root:
	@if [ "$$(id -u)" -ne 0 ]; then \
		printf "$(COLOR_YELLOW)Root privileges are needed. Authentication needed...$(COLOR_END)\n"; \
		export ORIGINAL_USER=$$(whoami); \
		VARS=$$(env | grep -vE '^(HOME|USER|LOGNAME|SHELL|PATH|MAIL|LS_COLORS|MFLAGS|MAKEFLAGS|MAKELEVEL|_)='); \
		if [ -n "$$DISPLAY" ] && command -v pkexec >/dev/null 2>&1; then \
			pkexec env PATH="$$PATH" ORIGINAL_USER="$$ORIGINAL_USER" AUTO="$(AUTO)" ARGS="$(ARGS)" $$VARS $(MAKE) -C "$$PWD" task AUTO="$(AUTO)" ARGS="$(ARGS)"; \
		elif command -v sudo >/dev/null 2>&1; then \
			sudo -E env ORIGINAL_USER="$$ORIGINAL_USER" AUTO="$(AUTO)" ARGS="$(ARGS)" $$VARS $(MAKE) -C "$$PWD" task AUTO="$(AUTO)" ARGS="$(ARGS)"; \
		elif command -v su >/dev/null 2>&1; then \
			printf "$(COLOR_YELLOW)[WARNING]: 'pkexec' and 'sudo' are missing. Falling back to 'su'. Environment variables might not be preserved! Exporting environment variables manually...$(COLOR_END)\n"; \
			VARS=$$(env | grep -vE '^(HOME|USER|LOGNAME|SHELL|PATH|MAIL|LS_COLORS|_)='); \
			su -c "export ORIGINAL_USER='$$ORIGINAL_USER'; export AUTO='$(AUTO)'; export ARGS='$(ARGS)'; export $$VARS; $(MAKE) -C '$$PWD' task AUTO='$(AUTO)' ARGS='$(ARGS)'"; \
		else \
			printf "$(COLOR_RED)[ERROR]: None of 'pkexec', 'sudo' or 'su' packages were found for gaining privileges.$(COLOR_END)\n"; \
			exit 1; \
		fi; \
		exit $$?; \
	fi

task:
	@if [ "$$(id -u)" -ne 0 ]; then \
		$(MAKE) ensure-root AUTO="$(AUTO)" ARGS='$(ARGS)'; \
	else \
		printf "$(COLOR_GREEN)Current user: $$(whoami) (UID: $$(id -u))$(COLOR_END)\n" \
		chmod +x "$$PWD/scripts/start.sh" \
		printf "$(COLOR_GREEN)Made '$$PWD/scripts/start.sh' executable. Running it...$(COLOR_END)\n" \
		IS_AUTO=0; if [ "$(AUTO)" = "1" ] || [ "$(ARGS)" = "-y" ]; then IS_AUTO=1; fi; \
		if command -v bash >/dev/null 2>&1; then \
			AUTO="$$IS_AUTO" bash "$$PWD/scripts/start.sh"; \
		else \
			AUTO="$$IS_AUTO" sh "$$PWD/scripts/start.sh"; \
		fi

install:
	@$(MAKE) ensure-root
	@printf "$(COLOR_GREEN)Current user: $$(whoami) (UID: $$(id -u))$(COLOR_END)\n"
	@chmod +x "$$PWD/install.sh"
	@printf "$(COLOR_GREEN)Made '$$PWD/install.sh' executable. Running it...$(COLOR_END)\n"
	@if command -v bash >/dev/null 2>&1; then \
		bash "$$PWD/install.sh"; \
	else \
		sh "$$PWD/install.sh"; \
	fi

install-auto:
	@$(MAKE) ensure-root
	@printf "$(COLOR_GREEN)Current user: $$(whoami) (UID: $$(id -u))$(COLOR_END)\n"
	@chmod +x "$$PWD/install.sh"
	@printf "$(COLOR_GREEN)Made '$$PWD/install.sh' executable. Running it...$(COLOR_END)\n"
	@if command -v bash >/dev/null 2>&1; then \
		bash "$$PWD/install.sh -y"; \
	else \
		sh "$$PWD/install.sh -y"; \
	fi