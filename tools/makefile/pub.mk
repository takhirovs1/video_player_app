
.PHONY: help-pub
help-pub: ## Help for pub commands
	@echo 'Usage: make <OPTIONS> ... <TARGETS>'
	@echo ''
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: version
version: ## Check flutter version
	######## ##       ##     ## ######## ######## ######## ########
	##       ##       ##     ##    ##       ##    ##       ##     ##
	##       ##       ##     ##    ##       ##    ##       ##     ##
	######   ##       ##     ##    ##       ##    ######   ########
	##       ##       ##     ##    ##       ##    ##       ##   ##
	##       ##       ##     ##    ##       ##    ##       ##    ##
	##       ########  #######     ##       ##    ######## ##     ##
	@flutter --version

.PHONY: doctor
doctor: ## Check flutter doctor
	@flutter doctor

.PHONY: clean_all
clean_all: ## Clean the project and remove all generated files
	@echo "🗑️ Cleaning the project..."
	@flutter clean
	@rm -f coverage.*
	@rm -rf dist bin out build
	@rm -rf coverage .dart_tool .packages pubspec.lock
	@echo "✅ Project successfully cleaned"

.PHONY: get
get: ## Get dependencies
	@flutter pub get

.PHONY: f_clean
f_clean: ## Clean the project
	@flutter clean

.PHONY: fluttergen
fluttergen: ## Generate assets
	@dart pub global activate flutter_gen
	@fluttergen -c pubspec.yaml


fix: format ## Fix the code
	@dart fix --apply lib

build_runner: ## Build runner
	@dart run build_runner build --delete-conflicting-outputs --release

.PHONY: codegen
codegen:  ## Generate code
	@echo "🔄 Generating code..."
	@make get
	@make fluttergen
	@make build_runner
	@make format
	@clear
	@echo "✅ Code generated successfully"

gen: codegen ## Generate all

.PHONY: upgrade
upgrade: ## Upgrade dependencies
	@flutter pub upgrade

.PHONY: upgrade-major
upgrade-major: get ## Upgrade to major versions
	@flutter pub upgrade --major-versions

.PHONY: outdated
outdated: get ## Check outdated dependencies
	@flutter pub outdated

.PHONY: dependencies
dependencies: get ## Check outdated dependencies
	@flutter pub outdated --dependency-overrides \
		--dev-dependencies --prereleases --show-all --transitive

.PHONY: format
format: ## Format code
	@dart format -l 120 lib/ test/ data/ packages/

.PHONY: add
add: ## add new package or plugin
	@flutter pub add $(p)

.PHONY: fcg
fcg: ## flutter clean, get dependencies and format
	@flutter clean
	@flutter pub get
	@make format

.PHONY: c_get
c_get: clean_all get

.PHONY: build_vec
build_vec: ## build vector graphics from svg and run flutter gens
	@dart run tools/dart/vector_generator.dart $(r)

vec: r ?= false
vec: build_vec fluttergen format ## build vector graphics from svg and run flutter gens

# https://pub.dev/packages/flutter_launcher_icons
.PHONY: generate-icons
generate-icons: ## Generate icons for the app
	@dart run flutter_launcher_icons -f flutter_launcher_icons.yaml

# https://pub.dev/packages/flutter_native_splash
.PHONY: generate-splash
generate-splash: ## Generate splash screen for the app
	@dart run flutter_native_splash:create --path=flutter_native_splash.yaml

.PHONY: pod-restart
pod-restart: ## restart pods
	@cd ios && \
	rm -rf Pods && \
	rm Podfile.lock && \
	pod deintegrate && \
	pod install
	@cd ..
	@make fcg
