GO_EASY_ON_ME = 1

THEOS_DEVICE_IP = 192.168.1.2

target = iphone::7.0
ARCHS = armv7 arm64

include theos/makefiles/common.mk

TWEAK_NAME = CCModifier
CCModifier_FILES = Tweak.xm DDSystemMediaControlsViewController.xm  DDCornerView.m DDControlsToggleView.m DDSwitchesScrollView.m
CCModifier_FRAMEWORKS = UIKit QuartzCore CoreGraphics
CCModifier_LIBRARIES = flipswitch

BUNDLE_NAME = CCModifierResources
CCModifierResources_INSTALL_PATH = /Library/Application Support/CCModifier/

SUBPROJECTS = CCModifierSettings

include $(THEOS_MAKE_PATH)/aggregate.mk
include $(THEOS_MAKE_PATH)/library.mk
include $(THEOS_MAKE_PATH)/bundle.mk
include $(THEOS_MAKE_PATH)/tweak.mk


after-stage::
	find $(THEOS_STAGING_DIR) -iname '*.plist' -exec plutil -convert binary1 {} \;
	dot_clean $(THEOS_STAGING_DIR);
	cd $(THEOS_STAGING_DIR); find . -name '*.DS_Store' -type f -delete;

after-install::
	install.exec "killall -9 SpringBoard"
