THEOS_PACKAGE_SCHEME = rootless

DEBUG = 1
PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)

export ARCHS = arm64 arm64e
export SYSROOT = $(THEOS)/sdks/iPhoneOS15.5.sdk
export TARGET = iphone:clang:latest:15.0


include $(THEOS)/makefiles/common.mk

SUBPROJECTS += Tweak Prefs


include $(THEOS_MAKE_PATH)/aggregate.mk
