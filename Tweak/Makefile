TWEAK_NAME = CAHighFPS

$(TWEAK_NAME)_FILES = Tweak.x
$(TWEAK_NAME)_CFLAGS = -fobjc-arc

ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

$(TWEAK_NAME)_EXTRA_FRAMEWORKS +=  AltList 
ADDITIONAL_OBJCFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
