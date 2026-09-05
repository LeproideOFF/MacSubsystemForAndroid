BUILD_DIR = .build/debug
ENTITLEMENTS = Resources/msa.entitlements
BIN_DEST = /opt/homebrew/bin/msa

all: build sign install

build:
	swift build

sign:
	codesign -s - --entitlements $(ENTITLEMENTS) --force $(BUILD_DIR)/msa-cli
	codesign -s - --entitlements $(ENTITLEMENTS) --force $(BUILD_DIR)/msa-daemon

install:
	cp $(BUILD_DIR)/msa-cli $(BIN_DEST)
	@echo "✅ 'msa' command installed to $(BIN_DEST)"

clean:
	swift package clean
