target = iphone:clang:9.0
ARCHS = armv7 arm64

GO_EASY_ON_ME = 1

include /opt/theos/makefiles/common.mk

BUNDLE_NAME = ExtensionLoaderSettings
ExtensionLoaderSettings_FILES = ExtensionLoaderSettings.mm
ExtensionLoaderSettings_INSTALL_PATH = /Library/PreferenceBundles
ExtensionLoaderSettings_FRAMEWORKS = UIKit SystemConfiguration CoreGraphics
ExtensionLoaderSettings_PRIVATE_FRAMEWORKS = Preferences AppSupport
ExtensionLoaderSettings_LIBRARIES = rocketbootstrap
ExtensionLoaderSettings_LDFLAGS += -Wl,-segalign,4000

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/ExtensionLoaderSettings.plist$(ECHO_END)
