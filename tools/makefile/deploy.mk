BUILD_NAME=$(shell grep '^version: ' pubspec.yaml | cut -d+ -f1 | sed 's/version: //')
BUILD_NUMBER=$(shell grep '^version: ' pubspec.yaml | cut -d+ -f2)


.PHONY: help-deploy
help-deploy:
	@echo 'Usage: make <OPTIONS> ... <TARGETS>'
	@echo ''
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: increment-build
increment-build: ## Increment build number in pubspec.yaml
	@sed -i '' 's/\(^version: *[0-9.]*\)+\([0-9]*\)/\1+'"$$(($$(grep '^version:' pubspec.yaml | cut -d+ -f2) + 1))"'/' pubspec.yaml
	@echo "\r"
	@echo "Build number incremented to $$(($(BUILD_NUMBER) + 1))"

.PHONY: apk
apk: increment-build clean_all gen ## Release build APK with build-name and build-number
	@flutter build apk --release --build-name=$(BUILD_NAME) --build-number=$(BUILD_NUMBER)
	@open build/app/outputs/apk/release/

.PHONY: ipa
ipa: ## Release build IPA with build-name and build-number
	@echo 'Starting upload process at $$(date "+%H:%M:%S")'
	@make increment-build
	@start_time=$$(date +%s)
	@$(MAKE) clean_all gen
	@echo '\n🚀 IPA build started'
	@flutter build ipa --build-name=$(BUILD_NAME) --build-number=$(BUILD_NUMBER)
	@chmod +x tools/script/internal-upload-ios.sh
	@tools/script/internal-upload-ios.sh
	@make publish
	@end_time=$$(date +%s)
	@duration_sec=$$((end_time - start_time))
	@duration_min=$$((duration_sec / 60))
	@duration_sec=$$((duration_sec % 60))
	@echo "\n✅ Total upload process took ${duration_min}m ${duration_sec}s (completed at $$(date '+%H:%M:%S'))"

.PHONY: ipa-apk
ipa-apk: ## Release build IPA and APK with build-name and build-number
	@make ipa
	@flutter build apk --release --build-name=$(BUILD_NAME) --build-number=$(BUILD_NUMBER) 
	@open build/app/outputs/apk/release/

.PHONY: aab
aab: ## Release build AAB with build-name and build-number
	@flutter build appbundle
	@open build/app/outputs/bundle/release/

.PHONY: apk-prod
apk-prod: fcg clean codegen format ## Build the android app
	@flutter build apk --release --build-name=$(BUILD_NAME) --build-number=$(BUILD_NUMBER)
	@open build/app/outputs/bundle/release/

.PHONY: ipa-prod
ipa-prod: fcg clean codegen ## Build the ios app
	@flutter build ipa --build-name=$(BUILD_NAME) --build-number=$(BUILD_NUMBER)
	@open build/ios/archive/Runner.xcarchive

.PHONY: ilvi
ilvi: ## Find the last iOS build version in the archive
	@echo "Finding the last iOS build version in the archive..."
	@LAST_ARCHIVE=$(shell ls -td $(ARCHIVE_DIR)/* | head -n 1) && \
	BUILD_VERSION=$$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleVersion" "$$LAST_ARCHIVE"/Info.plist) && \
	APP_VERSION=$$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleShortVersionString" "$$LAST_ARCHIVE"/Info.plist) && \
	echo "Last Version Info: $$APP_VERSION - $$BUILD_VERSION"

.PHONY: alvi
alvi: ## Find the last Android build version and app version from local.properties
	@echo "Finding the last Android build version and app version from local.properties..."
	@ANDROID_BUILD_VERSION=$$(grep "versionCode" $(LOCAL_PROPERTIES_FILE) | awk -F '=' '{print $$2}' | xargs) && \
	ANDROID_APP_VERSION=$$(grep "versionName" $(LOCAL_PROPERTIES_FILE) | awk -F '=' '{print $$2}' | xargs) && \
	echo "Last Version Info: $$ANDROID_APP_VERSION" - $$ANDROID_BUILD_VERSION

.PHONY: publish
publish: ## Publish the app to TestFlight
	@dart run tools/dart/test_flight_publisher.dart
