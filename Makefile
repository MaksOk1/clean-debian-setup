MAKEFLAGS += --no-print-directory --silent # or '-s'

.PHONY: run task-wrapper task update-repo ensure-root

run: update-repo task-wrapper

task-wrapper: task
	@printf "\e[32mEnd of task!\e[0m\n"

update-repo:
	@if [ "$(AUTO)" = "1" ]; then \
		ans="Y"; \
	else \
		printf "\e[34m[?] Do you want to check and pull updates from remote repository? [Y/n]: \e[0m"; \
		read -r ans; \
		ans=$${ans:-Y}; \
	fi; \
	if [[ "$$ans" =~ ^[Yy]$ ]]; then \
		printf "\e[32mUpdating repo from remote...\e[0m\n"; \
		OLD_HEAD=$$(git rev-parse HEAD 2>/dev/null); \
		git pull; \
		NEW_HEAD=$$(git rev-parse HEAD 2>/dev/null); \
		if [ "$$OLD_HEAD" != "$$NEW_HEAD" ]; then \
			printf "\e[34m[NEW COMMITS DOWNLOADED]:\e[0m\n"; \
			git log --format="%C(yellow)%h%C(reset) - %an, %ar : %s" $$OLD_HEAD..$$NEW_HEAD; \
		else \
			printf "\e[34m[ALREADY UP TO DATE]. Current commit:\e[0m\n"; \
			git log -1 --format="%C(yellow)%h%C(reset) - %an, %ar : %s"; \
		fi; \
	else \
		printf "\e[33m[SKIPPED] Repository update skipped by user. Current local commit:\e[0m\n"; \
		git log -1 --format="%C(yellow)%h%C(reset) - %an, %ar : %s"; \
	fi

ensure-root:
	@if [ "$$(id -u)" -ne 0 ]; then \
		printf "\e[33mRoot privileges are needed. Authentication needed...\e[0m\n"; \
		export ORIGINAL_USER=$$(whoami); \
		VARS=$$(env | grep -vE '^(HOME|USER|LOGNAME|SHELL|PATH|MAIL|LS_COLORS|_)='); \
		if [ -n "$$DISPLAY" ] && command -v pkexec >/dev/null 2>&1; then \
			pkexec env PATH="$$PATH" ORIGINAL_USER="$$ORIGINAL_USER" AUTO="$(AUTO)" $$VARS $(MAKE) -C "$$PWD" task AUTO="$(AUTO)"; \
		elif command -v sudo >/dev/null 2>&1; then \
			sudo -E env ORIGINAL_USER="$$ORIGINAL_USER" AUTO="$(AUTO)" $$VARS $(MAKE) -C "$$PWD" task AUTO="$(AUTO)"; \
		elif command -v su >/dev/null 2>&1; then \
			printf "\e[33m[WARNING]: 'pkexec' and 'sudo' are missing. Falling back to 'su'. Environment variables might not be preserved! Exporting environment variables manually...\e[0m\n"; \
			VARS=$$(env | grep -vE '^(HOME|USER|LOGNAME|SHELL|PATH|MAIL|LS_COLORS|_)='); \
			su -c "export ORIGINAL_USER='$$ORIGINAL_USER'; export AUTO='$(AUTO)'; export $$VARS; $(MAKE) -C '$$PWD' task AUTO='$(AUTO)'"; \
		else \
			printf "\e[31m[ERROR]: None of 'pkexec', 'sudo' or 'su' packages were found for gaining privileges.\e[0m\n"; \
			exit 1; \
		fi; \
		exit $$?; \
	fi

task:
	@$(MAKE) ensure-root AUTO="$(AUTO)"
	@printf "\e[32mCurrent user: $$(whoami) (UID: $$(id -u))\e[0m\n"
	@chmod +x "$$PWD/start.sh"
	@printf "\e[32mMade '$$PWD/start.sh' executable. Running it...\e[0m\n"
	@if command -v bash >/dev/null 2>&1; then \
		AUTO="$(AUTO)" bash "$$PWD/start.sh"; \
	else \
		AUTO="$(AUTO)" sh "$$PWD/start.sh"; \
	fi