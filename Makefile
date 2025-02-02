# Executables (local)
DOCKER = docker
DOCKER_COMP = docker compose

# Docker containers
PHP_CONT = $(DOCKER_COMP) exec php

# Executables
PHP      = $(PHP_CONT) php
COMPOSER = $(PHP_CONT) composer
SYMFONY  = $(PHP) bin/console

SHELL = sh
.DEFAULT_GOAL = help

# change your prod domain here
DOMAIN = microsymfony.ovh

# modify the code coverage threshold here
COVERAGE_THRESHOLD = 100

## —— 🎶 The MicroSymfony Makefile 🎶 ——————————————————————————————————————————
help: ## Outputs this help screen
	@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'
.PHONY: help start stop go-prod go-dev purge test test-api test-e2e test-functional test-integration test-unit coverage cov-report stan fix-php lint-php lint-container lint-twig lint-yaml fix lint ci deploy
.PHONY: version-php version-composer version-symfony version-phpunit version-phpstan version-php-cs-fixer check-requirements le-renew


## —— Symfony binary 💻 ————————————————————————————————————————————————————————
start: ## Start all services using Docker
	@$(DOCKER_COMP) up -d

stop: ## Stop all running Docker containers
	@$(DOCKER_COMP) down


## —— Symfony 🎶  ——————————————————————————————————————————————————————————————
go-prod: ## Switch to the production environment
	@$(DOCKER_COMP) exec php cp .env.local.dist .env.local
	# uncomment this line to optimize the auto-loading of classes in the prod env
	#@$(COMPOSER) dump-autoload --no-dev --classmap-authoritative
	@$(SYMFONY) asset-map:compile

go-dev: ## Switch to the development environment
	@$(DOCKER_COMP) exec php rm -f .env.local
	@$(DOCKER_COMP) exec php rm -rf ./public/assets/*
	#@$(COMPOSER) dump-autoload

warmup: ## Warmup the dev cache for the static analysis
	@$(SYMFONY) c:w --env=dev

purge: ## Purge all Symfony cache and logs
	@$(DOCKER_COMP) exec php rm -rf ./var/cache/* ./var/logs/* ./var/coverage/*


## —— Tests ✅ —————————————————————————————————————————————————————————————————
test: ## Run tests with optional suite, filter and options (to debug use "make test options=--debug")
	@$(eval testsuite ?= 'api,e2e,functional,integration,unit') # Run all suites by default, to run a specific suite see other "test-*" targets, eg: "make test-unit"
	@$(eval filter ?= '.')                                      # Use this parameter to spot a given test,                                       eg: "make test filter=testSlugify"
	@$(eval options ?= --stop-on-failure)                       # Use this use other options,                                                    eg: "make test options=--testdox"
	@$(PHP) vendor/bin/phpunit --testsuite=$(testsuite) --filter=$(filter) $(options)

test-api: ## Run API tests only
test-api: testsuite=api
test-api: test

test-e2e: ## Run E2E tests only
test-e2e: testsuite=e2e
test-e2e: test

test-functional: ## Run functional tests only
test-functional: testsuite=functional
test-functional: test

test-integration: ## Run integration tests only
test-integration: testsuite=integration
test-integration: test

test-unit: ## Run unit tests only
test-unit: testsuite=unit
test-unit: test

coverage: ## Generate the HTML PHPUnit code coverage report (stored in var/coverage)
coverage: purge
	@$(DOCKER_COMP) exec php XDEBUG_MODE=coverage php -d xdebug.enable=1 -d memory_limit=-1 vendor/bin/phpunit --coverage-html=var/coverage --coverage-clover=var/coverage/clover.xml
	@$(PHP) bin/coverage-checker.php var/coverage/clover.xml $(COVERAGE_THRESHOLD)


cov-report: var/coverage/index.html ## Open the PHPUnit code coverage report (var/coverage/index.html)
	@open var/coverage/index.html


## —— Coding standards/lints ✨ ————————————————————————————————————————————————
stan: var/cache/dev/App_KernelDevDebugContainer.xml ## Run the PHPStan static analysis
	@$(PHP) vendor/bin/phpstan analyse -c phpstan.neon --memory-limit 1G -vv

# PHPStan needs the dev/debug cache
var/cache/dev/App_KernelDevDebugContainer.xml:
	@$(DOCKER_COMP) exec php APP_DEBUG=1 APP_ENV=dev $(SYMFONY) cache:warmup

fix-php: ## Fix PHP files with php-cs-fixer (ignore PHP version warning)
	@$(DOCKER_COMP) exec php PHP_CS_FIXER_IGNORE_ENV=1 vendor/bin/php-cs-fixer fix $(PHP_CS_FIXER_ARGS)

lint-php: ## Lint PHP files with php-cs-fixer (report only)
lint-php: PHP_CS_FIXER_ARGS=--dry-run
lint-php: fix-php

lint-container: ## Lint the Symfony DI container
	@$(SYMFONY) lint:container

lint-twig: ## Lint Twig files
	@$(SYMFONY) lint:twig templates/

lint-yaml: ## Lint YAML files
	@$(SYMFONY) lint:yaml --parse-tags config/

fix: ## Run all fixers
fix: fix-php

lint: ## Run all linters
lint: stan lint-php lint-container lint-twig lint-yaml

ci: ## Run CI locally
ci: coverage warmup lint


## —— Other tools and helpers 🔨 ———————————————————————————————————————————————
versions: version-make version-php version-composer version-symfony version-phpunit version-phpstan version-php-cs-fixer ## Output current stack versions
version-make:
	@echo   '—— Make ———————————————————————————————————————————————————————————'
	@$(MAKE) --version
version-php:
	@echo   '\n—— PHP ——————————————————————————————————————————————————————————'
	@$(PHP) -v
version-composer:
	@echo '\n—— Composer ———————————————————————————————————————————————————————'
	@$(COMPOSER) --version
version-symfony:
	@echo '\n—— Symfony ————————————————————————————————————————————————————————'
	@$(SYMFONY) --version
version-phpunit:
	@echo '\n—— PHPUnit ————————————————————————————————————————————————————————'
	@$(PHP) vendor/bin/phpunit --version
version-phpstan:
	@echo '—— PHPStan ——————————————————————————————————————————————————————————'
	@$(PHP) vendor/bin/phpstan --version
version-php-cs-fixer:
	@echo '\n—— php-cs-fixer ———————————————————————————————————————————————————'
	@$(DOCKER_COMP) exec php PHP_CS_FIXER_IGNORE_ENV=1 vendor/bin/php-cs-fixer --version
	@echo

check-requirements: ## Checks requirements for running Symfony
	@$(PHP) vendor/bin/requirements-checker


## —— Deploy & Prod 🚀 —————————————————————————————————————————————————————————
deploy: ## Simple manual deploy on a VPS (this is to update the demo site https://microsymfony.ovh/)
	@$(DOCKER_COMP) exec php git pull
	@$(COMPOSER) install -n
	@$(DOCKER_COMP) exec php chown -R www-data: ./var/*
	@$(DOCKER_COMP) exec php cp .env.local.dist .env.local
	@$(COMPOSER) dump-env prod -n
	@$(SYMFONY) asset-map:compile

le-renew: ## Renew Let's Encrypt HTTPS certificates
	@$(DOCKER) run --rm -v /etc/letsencrypt:/etc/letsencrypt certbot/certbot renew --apache -d $(DOMAIN) -d www.$(DOMAIN)

## —— Utils 🔌 ————————————————————————————————————————————————————————————————————————
trust-tls: ## Trust the TLS certificates
	@$(DOCKER) cp $(shell $(DOCKER_COMP) ps -q php):/data/caddy/pki/authorities/local/root.crt /tmp/root.crt && sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain /tmp/root.crt

