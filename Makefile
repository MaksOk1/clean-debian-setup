SHELL := /usr/bin/bash

MAKEFLAGS += --no-print-directory --silent # or '-s'

.PHONY: run task-wrapper task update-repo ensure-root install install-auto

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
# 		VARS=$$(env | grep -vE '^(HOME|USER|LOGNAME|SHELL|PATH|MAIL|LS_COLORS|MFLAGS|MAKEFLAGS|MAKELEVEL|_)=');
	@if [ "$$(id -u)" -ne 0 ]; then \
		printf "$(COLOR_YELLOW)Root privileges are needed. Authentication needed...$(COLOR_END)\n"; \
		export ORIGINAL_USER=$$(whoami); \
		if [ -n "$$DISPLAY" ] && command -v pkexec >/dev/null 2>&1; then \
			pkexec env PATH="$$PATH" ORIGINAL_USER="$$ORIGINAL_USER" AUTO="$(AUTO)" ARGS="$(ARGS)" $(MAKE) -C "$$PWD" task AUTO="$(AUTO)" ARGS="$(ARGS)"; \
		elif command -v sudo >/dev/null 2>&1; then \
			sudo -E env ORIGINAL_USER="$$ORIGINAL_USER" AUTO="$(AUTO)" ARGS="$(ARGS)" $(MAKE) -C "$$PWD" task AUTO="$(AUTO)" ARGS="$(ARGS)"; \
		elif command -v su >/dev/null 2>&1; then \
			printf "$(COLOR_YELLOW)[WARNING]: 'pkexec' and 'sudo' are missing. Falling back to 'su'. Environment variables might not be preserved! Exporting environment variables manually...$(COLOR_END)\n"; \
			VARS=$$(env | grep -vE '^(HOME|USER|LOGNAME|SHELL|PATH|MAIL|LS_COLORS|_)='); \
			su -c "export ORIGINAL_USER='$$ORIGINAL_USER'; export AUTO='$(AUTO)'; export ARGS='$(ARGS)'; $(MAKE) -C '$$PWD' task AUTO='$(AUTO)' ARGS='$(ARGS)'"; \
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

install:
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

install-auto:
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

pull:
	@git pull

pull-force:
	@git fetch --all
	@git reset --hard origin/$$(git branch --show-current)

reclone:
	@export REPO_NAME=$$(basename `git rev-parse --show-toplevel`) ; \
	export REPO_URL=$$(git config --get remote.origin.url) ; \
	cd ../ ; \
	rm -rf ./$$REPO_NAME ; \
	git clone $$REPO_URL $$REPO_NAME ; \
	cd ./$$REPO_NAME