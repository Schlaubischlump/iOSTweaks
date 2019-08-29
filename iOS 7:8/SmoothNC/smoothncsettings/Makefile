target = iphone::7.0
ARCHS = armv7 arm64

GO_EASY_ON_ME = 1

include /opt/theos/makefiles/common.mk

BUNDLE_NAME = SmoothNCSettings
SmoothNCSettings_FILES = SmoothNCSettingsListController.mm
SmoothNCSettings_INSTALL_PATH = /Library/PreferenceBundles
SmoothNCSettings_FRAMEWORKS = UIKit SystemConfiguration CoreGraphics
SmoothNCSettings_PRIVATE_FRAMEWORKS = Preferences AppSupport

include $(THEOS_MAKE_PATH)/bundle.mk