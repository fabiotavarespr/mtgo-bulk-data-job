PWD = $(shell pwd -L)
GO_CMD=go
DOCKER_CMD=docker
DOCKER_COMPOSE_CMD=docker-compose
GO_TEST=$(GO_CMD) test
PATH_DOCKER_COMPOSE_FILE=resources/docker-compose/docker-compose.yaml
MIGRATIONS_FOLDER=$(PWD)/resources/database/migrations
DATABASE_URL=postgres://root:mtgo-bulk-data@localhost:5432/mtgo-bulk-data?sslmode=disable

.PHONY: docker-compose-restart migrate-up

all: help

help: ## Display help screen
	@echo "Usage:"
	@echo "	make [COMMAND]"
	@echo "	make help \n"
	@echo "Commands: \n"
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

go-tidy: ## Go mod tidy
	$(GO_CMD) mod tidy

go-fmt: go-tidy ## Go mod tidy
	$(GO_CMD) fmt ./...

go-test: go-fmt go-test-clean  ## Go test all project
	$(GO_TEST) -cover -p=1 ./...

go-test-coverage: go-fmt ## Run the tests of the project and open the coverage in a Browser
	$(GO_TEST) -cover -p=1 -covermode=count -coverprofile=coverage.out ./...
	$(GO_CMD) tool cover -html=coverage.out

go-test-clean: go-fmt ## Run the clean cache tests of the project
	$(GO_CMD) clean -testcache

docker-compose-up: ## Run docker-compose services of project
	$(DOCKER_COMPOSE_CMD) -f $(PATH_DOCKER_COMPOSE_FILE) up -d

docker-compose-down: ## Stop docker-compose services of project
	$(DOCKER_COMPOSE_CMD) -f $(PATH_DOCKER_COMPOSE_FILE) down --remove-orphans

docker-compose-restart: docker-compose-down docker-compose-up ## Restart docker-compose services of project

docker-compose-logs: ## Logs docker-compose containers of project
	$(DOCKER_COMPOSE_CMD) -f $(PATH_DOCKER_COMPOSE_FILE) logs -f

docker-compose-ps: ## List docker-compose containers of project
	$(DOCKER_COMPOSE_CMD) -f $(PATH_DOCKER_COMPOSE_FILE) ps

migrate-create: ## Create Migrate
	$(DOCKER_CMD) run --rm -v $(MIGRATIONS_FOLDER):/migrations migrate/migrate -path=/migrations/ create -ext sql -dir /migrations/ -seq init_schema

migrate-up: ## Up Migrate
	$(DOCKER_CMD) run --rm -v $(MIGRATIONS_FOLDER):/migrations --network host migrate/migrate -path=/migrations/ -database $(DATABASE_URL) -verbose up

migrate-down: ## Down Migrate
	$(DOCKER_CMD) run --rm -v $(MIGRATIONS_FOLDER):/migrations --network host migrate/migrate -path=/migrations/ -database $(DATABASE_URL) -verbose down --all

migrate-force: ## Force Migrate
	$(DOCKER_CMD) run --rm -v $(MIGRATIONS_FOLDER):/migrations --network host migrate/migrate -path=/migrations/ -database $(DATABASE_URL) force $(version)

sqlc-init: ## Init Sqlc
	$(DOCKER_CMD) run --rm -v $(PWD):/src -w /src kjconroy/sqlc init

sqlc-generate: ## Generate Sqlc
	$(DOCKER_CMD) run --rm -v $(PWD):/src -w /src kjconroy/sqlc generate