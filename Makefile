HOST ?= 0
KILL ?= 0
ROOTLESS ?= 0

ifeq ($(HOST),0)
	THEOS_DEVICE_IP = 192.168.3.67
else ifeq ($(HOST),1)
	THEOS_DEVICE_IP = 192.168.3.116
else
	THEOS_DEVICE_IP = 127.0.0.1
	export THEOS_DEVICE_PORT = 2222
endif

ifeq ($(ROOTLESS),1)
export THEOS_PACKAGE_SCHEME=rootless
endif

DEBUG = 0
PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)

export ARCHS = arm64 arm64e
export SYSROOT = $(THEOS)/sdks/iPhoneOS16.5.sdk
export TARGET = iphone:clang:latest:15.0

SUBPROJECTS += Tweak Prefs

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/aggregate.mk




