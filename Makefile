SRC_DIRS=Hem HemTests
PROJECT=Hem.xcodeproj
SCHEME=Hem
SIMULATOR?=iPhone 17

build:
	@xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug -destination 'platform=iOS Simulator,name=$(SIMULATOR)' build

test:
	@xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug -destination 'platform=iOS Simulator,name=$(SIMULATOR)' test

format:
	@synx -q Hem.xcodeproj
	@swift format format -r -i $(SRC_DIRS)

lint:
	@swift format lint -r $(SRC_DIRS)

.DEFAULT_GOAL := build
.PHONY: build test format lint
