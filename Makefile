BUILD_DIR = .build/debug
ENTITLEMENTS = Resources/msa.entitlements
BIN_DEST = /opt/homebrew/bin/msa
APP_DEST = /Applications/MSA.app

all: build sign install

build:
	swift build

sign:
	codesign -s - --entitlements $(ENTITLEMENTS) --force $(BUILD_DIR)/msa-cli
	codesign -s - --entitlements $(ENTITLEMENTS) --force $(BUILD_DIR)/msa-daemon
	codesign -s - --entitlements $(ENTITLEMENTS) --force $(BUILD_DIR)/msa-app

install:
	cp $(BUILD_DIR)/msa-cli $(BIN_DEST)
	@mkdir -p "$(APP_DEST)/Contents/MacOS" "$(APP_DEST)/Contents/Resources"
	@cp $(BUILD_DIR)/msa-app "$(APP_DEST)/Contents/MacOS/MSA"
	@echo '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>CFBundleExecutable</key><string>MSA</string><key>CFBundleIdentifier</key><string>com.apple.msa</string><key>CFBundleName</key><string>MSA</string><key>CFBundlePackageType</key><string>APPL</string><key>CFBundleShortVersionString</key><string>1.0</string></dict></plist>' > "$(APP_DEST)/Contents/Info.plist"
	@codesign -s - --entitlements $(ENTITLEMENTS) --force "$(APP_DEST)"
	@echo "✅ 'msa' CLI installed to $(BIN_DEST)"
	@echo "✅ 'MSA.app' (Liquid Glass macOS App) installed to $(APP_DEST)"

clean:
	swift package clean
