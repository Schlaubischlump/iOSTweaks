THEOS_DEVICE_IP=192.168.1.12

GO_EASY_ON_ME = 1

target = iphone:clang:9.0
ARCHS = armv7 arm64

include theos/makefiles/common.mk

TWEAK_NAME = ExtensionLoader
ExtensionLoader_FILES = Tweak.xm  DD_Custom_SBNCColumnViewController.x DD_ExtensionLoader.m DD_NotificationCenter_ExtensionLoader.m
ExtensionLoader_FRAMEWORKS = Foundation UIKit 
ExtensionLoader_PRIVATE_FRAMEWORKS = AppSupport
ExtensionLoader_LIBRARIES = rocketbootstrap
ExtensionLoader_LDFLAGS += -Wl,-segalign,4000

SUBPROJECTS = extensionloadersettings

include $(THEOS_MAKE_PATH)/aggregate.mk
include $(THEOS_MAKE_PATH)/library.mk
include $(THEOS_MAKE_PATH)/tweak.mk


after-install::
	install.exec "killall -9 SpringBoard"
