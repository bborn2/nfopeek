.PHONY: build install clean open test

DEVELOPER_DIR = /Applications/Xcode.app/Contents/Developer
DERIVED_DATA = build
APP_PATH = $(DERIVED_DATA)/Build/Products/Release/NFOPeek.app
INSTALL_PATH = ~/Applications/NFOPeek.app

build:
	@echo "🔨 Generating Xcode project..."
	xcodegen generate
	@echo "🏗️  Building Release..."
	DEVELOPER_DIR=$(DEVELOPER_DIR) xcodebuild -project NFOPeek.xcodeproj -scheme NFOPeek \
		-configuration Release -derivedDataPath $(DERIVED_DATA) build

install: build
	@echo "📦 Installing to ~/Applications..."
	mkdir -p ~/Applications
	rm -rf $(INSTALL_PATH)
	cp -R $(APP_PATH) $(INSTALL_PATH)
	@echo "🚀 Opening app to activate extension..."
	open $(INSTALL_PATH)
	@sleep 2
	@echo "✅ Extension registered:"
	@pluginkit -m -p com.apple.quicklook.preview | grep NFOPeek || echo "❌ Extension not found"

clean:
	rm -rf $(DERIVED_DATA) NFOPeek.xcodeproj

open:
	open $(APP_PATH)

test:
	@echo "🧪 Testing preview generation..."
	@qlmanage -p sample/STARS-974.nfo > /tmp/ql.log 2>&1 & \
		sleep 3 && echo "✅ Preview window opened" || echo "❌ Failed"
