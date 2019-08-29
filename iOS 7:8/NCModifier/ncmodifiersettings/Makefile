target = iphone::7.0
ARCHS = armv7 arm64

GO_EASY_ON_ME = 1

include /opt/theos/makefiles/common.mk

BUNDLE_NAME = NCModifierSettings
NCModifierSettings_FILES = NCModifierSettingsListController.mm
NCModifierSettings_INSTALL_PATH = /Library/PreferenceBundles
NCModifierSettings_FRAMEWORKS = UIKit SystemConfiguration CoreGraphics
NCModifierSettings_PRIVATE_FRAMEWORKS = Preferences AppSupport

include $(THEOS_MAKE_PATH)/bundle.mk