# Funnel Server Makefile
# Usage: make [command]

# Colors for output
GREEN = \033[0;32m
YELLOW = \033[0;33m
RED = \033[0;31m
NC = \033[0m # No Color

# Project settings
PROJECT_NAME = funnel-api
ENTRYPOINT = main.ts

.PHONY: help dev test deploy-prod deploy-preview clean format lint precommit logs log

# Default target
help:
	@echo "$(GREEN)Funnel Server - Available commands:$(NC)"
	@echo "  $(YELLOW)make dev$(NC)            - Run development server"
	@echo "  $(YELLOW)make test$(NC)           - Run tests"
	@echo "  $(YELLOW)make deploy-prod$(NC)    - Deploy to production"
	@echo "  $(YELLOW)make deploy-preview$(NC) - Deploy preview"
	@echo "  $(YELLOW)make logs$(NC)           - View production logs"
	@echo "  $(YELLOW)make format$(NC)         - Format code"
	@echo "  $(YELLOW)make lint$(NC)           - Run linter"
	@echo "  $(YELLOW)make precommit$(NC)      - Run format and lint"
	@echo "  $(YELLOW)make clean$(NC)          - Clean build artifacts"

# Run development server
dev:
	@echo "$(GREEN)Starting development server...$(NC)"
	@mkdir -p logs
	@LOG_FILE="logs/server-$(shell date +%Y%m%d-%H%M%S).log" && \
	deno task dev 2>&1 | tee $$LOG_FILE & \
	echo $$! > logs/server.pid && \
	ln -sf $$(basename $$LOG_FILE) logs/latest.log && \
	echo "$(GREEN)Server logging to: $$LOG_FILE$(NC)" && \
	echo "$(GREEN)Latest log symlink: logs/latest.log$(NC)" && \
	wait

# Run tests
test:
	@echo "$(GREEN)Running tests...$(NC)"
	@deno task test

# Deploy to production
# To include environment variables, add --env-file=.env to the deployctl command
deploy-prod:
	@echo "$(GREEN)Deploying to production...$(NC)"
	@deployctl deploy --project=$(PROJECT_NAME) --prod $(ENTRYPOINT)
	@echo "$(GREEN)✅ Production deployment complete!$(NC)"
	@echo "$(GREEN)View at: https://$(PROJECT_NAME).deno.dev$(NC)"

# Deploy preview (without --prod flag)
# To include environment variables, add --env-file=.env to the deployctl command
deploy-preview:
	@echo "$(GREEN)Deploying preview...$(NC)"
	@deployctl deploy --project=$(PROJECT_NAME) $(ENTRYPOINT)
	@echo "$(GREEN)✅ Preview deployment complete!$(NC)"

# View production logs
logs:
	@echo "$(GREEN)Fetching production logs...$(NC)"
	@deployctl logs --project=$(PROJECT_NAME)

# View latest local server log
log:
	@if [ -f logs/latest.log ]; then \
		echo "$(GREEN)Viewing latest server log:$(NC)"; \
		tail -f logs/latest.log; \
	else \
		echo "$(RED)No log file found. Run 'make dev' first.$(NC)"; \
	fi

# Format code
format:
	@echo "$(GREEN)Formatting code...$(NC)"
	@deno fmt
	@echo "$(GREEN)✅ Code formatted$(NC)"

# Run linter
lint:
	@echo "$(GREEN)Running linter...$(NC)"
	@deno lint
	@echo "$(GREEN)✅ Linting complete$(NC)"

# Run format and lint (precommit hook)
precommit: format lint
	@echo "$(GREEN)✅ Precommit checks passed$(NC)"

# Clean build artifacts
clean:
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	@rm -rf .deno_cache
	@echo "$(GREEN)✅ Clean complete$(NC)"