GO_EASY_ON_ME = 1

THEOS_DEVICE_IP = 192.168.0.133

target = iphone::7.0
ARCHS = armv7 arm64


include theos/makefiles/common.mk

TWEAK_NAME = NCModifier
NCModifier_FILES = Tweak.xm
NCModifier_FRAMEWORKS = Foundation CoreGraphics UIKit QuartzCore

BUNDLE_NAME = NCModifierResources
NCModifierResources_INSTALL_PATH = /Library/Application Support/

SUBPROJECTS = NCModifierSettings


include $(THEOS_MAKE_PATH)/aggregate.mk
include $(THEOS_MAKE_PATH)/library.mk
include $(THEOS_MAKE_PATH)/bundle.mk
include $(THEOS_MAKE_PATH)/tweak.mk

after-stage::
	find $(THEOS_STAGING_DIR) -iname '*.plist' -exec plutil -convert binary1 {} \;
	dot_clean $(THEOS_STAGING_DIR)

after-install::
	install.exec "killall -9 SpringBoard"