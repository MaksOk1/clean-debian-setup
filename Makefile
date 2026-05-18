.PHONY: run task-wrapper task update-repo ensure-root

run: task-wrapper

task-wrapper: task
	@echo -e "\e[32mEnd of task!\e[0m"

update-repo:
	@echo "Updating repo from remote..."
	@git pull

ensure-root:
	@if [ "$$(id -u)" -ne 0 ]; then \
		printf "\e[31mRoot privileges are needed. Authentication needed...\e[0m\n"; \
		if [ -n "$$DISPLAY" ] && command -v pkexec >/dev/null 2>&1; then \
			pkexec env PATH="$$PATH" $(MAKE) task; \
		elif command -v sudo >/dev/null 2>&1; then \
			sudo -E $(MAKE) task; \
		elif command -v su >/dev/null 2>&1; then \
			printf "\e[33m[WARNING]: 'pkexec' and 'sudo' are missing. Falling back to 'su'. Environment variables might not be preserved!\e[0m\n"; \
			su -c "$(MAKE) task"; \
		else \
			printf "\e[31m[ERROR]: None of 'pkexec', 'sudo' or 'su' packages were found for gaining privileges.\e[0m\n"; \
			exit 1; \
		fi; \
		exit $$?; \
	fi

task: update-repo
	@$(MAKE) ensure-root
	@printf "\e[32mCurrent user: $$(whoami) (UID: $$(id -u))\e[0m\n"
	@chmod +x "$$PWD/start.sh"
	@printf "\e[32mMade '$$PWD/start.sh' executable. Running it...\e[0m\n"
	@"$(which bash)" "$$PWD/start.sh"