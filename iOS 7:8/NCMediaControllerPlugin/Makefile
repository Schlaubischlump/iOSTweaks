GO_EASY_ON_ME = 1

THEOS_DEVICE_IP = 192.168.0.133

target = iphone::7.0
ARCHS = armv7 arm64
ADDITIONAL_OBJCFLAGS = -fobjc-arc

include /opt/theos/makefiles/common.mk

BUNDLE_NAME = NCMediaControllerPlugin
NCMediaControllerPlugin_FILES = NCMediaControllerPlugin.mm FXBlurView.m DDLyricsView.m
NCMediaControllerPlugin_INSTALL_PATH = /Library/ExtensionLoader/Plugins
NCMediaControllerPlugin_FRAMEWORKS = UIKit MediaPlayer QuartzCore Accelerate CoreGraphics AVFoundation

include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"

include $(THEOS_MAKE_PATH)/aggregate.mk
