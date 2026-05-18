.PHONY: run task-wrapper task update-repo ensure-root

run: task-wrapper

task-wrapper: task
	@echo -e "\e[32mEnd of task!\e[0"

update-repo:
	@echo "Updating repo from remote..."
	@git pull

ensure-root:
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo -e "\e[31mRoot previleges are needed. Authentication needed...\e[0m"; \
		if [ -n "$$DISPLAY" ] && command -v pkexec >/dev/null 2>&1; then \
			pkexec env PATH="$$PATH" $(MAKE) $(MAKECMDGOALS); \
		elif command -v sudo >/dev/null 2>&1; then \
			sudo -E $(MAKE) $(MAKECMDGOALS); \
		else \
			echo -e "\e[31mERROR: not found 'pkexec' or 'sudo' packages for gaining previleges.\e[0m"; \
			exit 1; \
		fi; \
		exit $$?; \
	fi

task: update-repo ensure-root
# 	@if [ "$$(id -u)" -ne 0 ]; then \
# 		 \
# 		if command -v sudo >/dev/null 2>&1; then \
# 			sudo $(MAKE) $(MAKECMDGOALS); \
# 		else \
# 			su -c "$(MAKE) $(MAKECMDGOALS)"; \
# 		fi; \
# 		exit $$?; \
# 	fi
	@echo -e "\e[32mCurrent user: $$(whoami) (UID: $$(id -u))\e[0m"
	@chmod +x "$$PWD/start.sh"
	@echo -e "\e[32mMade '$$PWD/start.sh' executable. Running it...\e[0m"
	@"$(which bash)" "$$PWD/start.sh"