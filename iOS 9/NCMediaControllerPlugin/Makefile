GO_EASY_ON_ME = 1

THEOS_DEVICE_IP = 192.168.1.12

target = iphone:clang:9.0
ARCHS = armv7 arm64
ADDITIONAL_OBJCFLAGS = -fobjc-arc

include /opt/theos/makefiles/common.mk

BUNDLE_NAME = NCMediaControllerPlugin
NCMediaControllerPlugin_FILES = NCMediaControllerPlugin.mm FXBlurView.m DDLyricsView.m
NCMediaControllerPlugin_INSTALL_PATH = /Library/ExtensionLoader/Plugins
NCMediaControllerPlugin_FRAMEWORKS = UIKit MediaPlayer QuartzCore Accelerate CoreGraphics AVFoundation
NCMediaControllerPlugin_LDFLAGS += -Wl,-segalign,4000

include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"

include $(THEOS_MAKE_PATH)/aggregate.mk
