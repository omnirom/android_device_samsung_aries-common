#
# Copyright (C) 2008 The Android Open-Source Project
# Copyright (C) 2013 OmniROM Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

ifeq ($(BOARD_USES_OWN_CHARGER),true)

LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

LOCAL_SRC_FILES := \
	charger.c

LOCAL_MODULE := device_healthd
LOCAL_MODULE_TAGS := optional
LOCAL_FORCE_STATIC_EXECUTABLE := true
LOCAL_MODULE_PATH := $(TARGET_ROOT_OUT_SBIN)
LOCAL_UNSTRIPPED_PATH := $(TARGET_ROOT_OUT_SBIN_UNSTRIPPED)

ifeq ($(strip $(BOARD_CHARGER_DISABLE_INIT_BLANK)),true)
	LOCAL_CFLAGS := -DCHARGER_DISABLE_INIT_BLANK
endif

ifeq ($(strip $(BOARD_CHARGER_ENABLE_SUSPEND)),true)
LOCAL_CFLAGS += -DCHARGER_ENABLE_SUSPEND
endif

ifneq ($(BOARD_BATTERY_SYSFS_PATH),)
	LOCAL_CFLAGS += -DBATTERY_SYSFS=\"$(BOARD_BATTERY_SYSFS_PATH)\"
endif

ifneq ($(BOARD_AC_SYSFS_PATH),)
	LOCAL_CFLAGS += -DAC_SYSFS=\"$(BOARD_AC_SYSFS_PATH)\"
endif

ifneq ($(BOARD_USB_SYSFS_PATH),)
	LOCAL_CFLAGS += -DUSB_SYSFS=\"$(BOARD_USB_SYSFS_PATH)\"
endif

ifeq ($(BOARD_CHARGER_DIM_SCREEN_BRIGHTNESS),true)
	LOCAL_CFLAGS += -DDIM_SCREEN=\"$(BOARD_CHARGER_DIM_SCREEN_BRIGHTNESS)\"
endif

LOCAL_C_INCLUDES := bootable/recovery

LOCAL_STATIC_LIBRARIES := \
	libminui \
	libpixelflinger_static \
	libpng \
	libz \
	libstdc++ \
	libcutils \
	liblog \
	libm \
	libc

ifeq ($(strip $(BOARD_CHARGER_ENABLE_SUSPEND)),true)
	LOCAL_STATIC_LIBRARIES += libsuspend
endif
ifneq ($(TW_BRIGHTNESS_PATH),)
	LOCAL_CFLAGS += -DBRIGHTNESS_PATH=\"$(TW_BRIGHTNESS_PATH)\"
ifeq ($(TW_MAX_BRIGHTNESS),)
	LOCAL_CFLAGS += -DMAX_BRIGHTNESS=\"255\"
else
	LOCAL_CFLAGS += -DMAX_BRIGHTNESS=\"$(TW_MAX_BRIGHTNESS)\"
endif
endif

include $(BUILD_EXECUTABLE)

define _add-charger-image
include $$(CLEAR_VARS)
LOCAL_MODULE := device_healthd_$(notdir $(1))
LOCAL_MODULE_STEM := $(notdir $(1))
_img_modules += $$(LOCAL_MODULE)
LOCAL_SRC_FILES := $1
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := $$(TARGET_ROOT_OUT)/res/images/charger
include $$(BUILD_PREBUILT)
endef

_img_modules :=
_images :=
$(foreach _img, $(call find-subdir-subdir-files, "images", "*.png"), \
  $(eval $(call _add-charger-image,$(_img))))

include $(CLEAR_VARS)
LOCAL_MODULE := device_healthd_images
LOCAL_MODULE_TAGS := optional
LOCAL_REQUIRED_MODULES := $(_img_modules)
include $(BUILD_PHONY_PACKAGE)

_add-charger-image :=
_img_modules :=

endif
