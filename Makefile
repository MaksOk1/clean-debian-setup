.PHONY: run task-wrapper task

run: task-wrapper

task-wrapper: task
	@echo -e "\e[32mEnd of task!\e[0"

task:
	@echo "Updating repo from remote"
	@git pull && \
	if [ "$$(id -u)" -ne 0 ]; then \
		echo -e "\e[31mRoot previleges are needed. Authentication needed...\e[0m"; \
		if command -v sudo >/dev/null 2>&1; then \
			sudo $(MAKE) $(MAKECMDGOALS); \
		else \
			su -c "$(MAKE) $(MAKECMDGOALS)"; \
		fi; \
		exit $$?; \
	fi
	@echo -e "\e[32mCurrent user: $$(whoami) (UID: $$(id -u))\e[0m"
	@chmod +x "$(pwd)/start.sh"
	@echo -e "\e[32mMade '$(pwd)/start.sh' executable. Running it...\e[0m"
	@"$(which bash)" "$(pwd)/start.sh"