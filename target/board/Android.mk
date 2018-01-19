#
# Set up product-global definitions and include product-specific rules.
#

LOCAL_PATH := $(call my-dir)

-include $(TARGET_DEVICE_DIR)/AndroidBoard.mk

# Generate a file that contains various information about the
# device we're building for.  This file is typically packaged up
# with everything else.
#
# If TARGET_BOARD_INFO_FILE (which can be set in BoardConfig.mk) is
# defined, it is used, otherwise board-info.txt is looked for in
# $(TARGET_DEVICE_DIR).
#
INSTALLED_ANDROID_INFO_TXT_TARGET := $(PRODUCT_OUT)/android-info.txt
board_info_txt := $(TARGET_BOARD_INFO_FILE)
ifndef board_info_txt
board_info_txt := $(wildcard $(TARGET_DEVICE_DIR)/board-info.txt)
endif
$(INSTALLED_ANDROID_INFO_TXT_TARGET): $(board_info_txt)
	$(hide) build/make/tools/check_radio_versions.py $< $(BOARD_INFO_CHECK)
	$(call pretty,"Generated: ($@)")
ifdef board_info_txt
	$(hide) grep -v '#' $< > $@
else
	$(hide) echo "board=$(TARGET_BOOTLOADER_BOARD_NAME)" > $@
endif

# Copy compatibility metadata to the device.

# Device Manifest
ifdef DEVICE_MANIFEST_FILE
# $(DEVICE_MANIFEST_FILE) can be a list of files
include $(CLEAR_VARS)
LOCAL_MODULE        := device_manifest.xml
LOCAL_MODULE_STEM   := manifest.xml
LOCAL_MODULE_CLASS  := ETC
LOCAL_MODULE_PATH   := $(TARGET_OUT_VENDOR)/etc/vintf

GEN := $(local-generated-sources-dir)/manifest.xml
$(GEN): PRIVATE_DEVICE_MANIFEST_FILE := $(DEVICE_MANIFEST_FILE)
$(GEN): $(DEVICE_MANIFEST_FILE) $(HOST_OUT_EXECUTABLES)/assemble_vintf
	BOARD_SEPOLICY_VERS=$(BOARD_SEPOLICY_VERS) \
	PRODUCT_ENFORCE_VINTF_MANIFEST=$(PRODUCT_ENFORCE_VINTF_MANIFEST) \
	PRODUCT_SHIPPING_API_LEVEL=$(PRODUCT_SHIPPING_API_LEVEL) \
	$(HOST_OUT_EXECUTABLES)/assemble_vintf -o $@ \
		-i $(call normalize-path-list,$(PRIVATE_DEVICE_MANIFEST_FILE))

LOCAL_PREBUILT_MODULE_FILE := $(GEN)
include $(BUILD_PREBUILT)
BUILT_VENDOR_MANIFEST := $(LOCAL_BUILT_MODULE)
endif

# Device Compatibility Matrix
ifdef DEVICE_MATRIX_FILE
include $(CLEAR_VARS)
LOCAL_MODULE        := device_compatibility_matrix.xml
LOCAL_MODULE_STEM   := compatibility_matrix.xml
LOCAL_MODULE_CLASS  := ETC
LOCAL_MODULE_PATH   := $(TARGET_OUT_VENDOR)/etc/vintf

GEN := $(local-generated-sources-dir)/compatibility_matrix.xml
$(GEN): $(DEVICE_MATRIX_FILE) $(HOST_OUT_EXECUTABLES)/assemble_vintf
	# TODO(b/37342627): put BOARD_VNDK_VERSION & BOARD_VNDK_LIBRARIES into device matrix.
	$(HOST_OUT_EXECUTABLES)/assemble_vintf -i $< -o $@

LOCAL_PREBUILT_MODULE_FILE := $(GEN)
include $(BUILD_PREBUILT)
BUILT_VENDOR_MATRIX := $(LOCAL_BUILT_MODULE)
endif

# Framework Manifest
include $(CLEAR_VARS)
LOCAL_MODULE        := framework_manifest.xml
LOCAL_MODULE_STEM   := manifest.xml
LOCAL_MODULE_CLASS  := ETC
LOCAL_MODULE_PATH   := $(TARGET_OUT)/etc/vintf

GEN := $(local-generated-sources-dir)/manifest.xml

$(GEN): PRIVATE_FLAGS :=

ifeq ($(PRODUCT_ENFORCE_VINTF_MANIFEST),true)
ifdef BUILT_VENDOR_MATRIX
$(GEN): $(BUILT_VENDOR_MATRIX)
$(GEN): PRIVATE_FLAGS += -c "$(BUILT_VENDOR_MATRIX)"
endif
endif

$(GEN): PRIVATE_FRAMEWORK_MANIFEST_INPUT_FILES := $(FRAMEWORK_MANIFEST_INPUT_FILES)
$(GEN): $(FRAMEWORK_MANIFEST_INPUT_FILES) $(HOST_OUT_EXECUTABLES)/assemble_vintf
	BOARD_SEPOLICY_VERS=$(BOARD_SEPOLICY_VERS) $(HOST_OUT_EXECUTABLES)/assemble_vintf \
		-i $(call normalize-path-list,$(PRIVATE_FRAMEWORK_MANIFEST_INPUT_FILES)) \
		-o $@ $(PRIVATE_FLAGS)

LOCAL_PREBUILT_MODULE_FILE := $(GEN)
include $(BUILD_PREBUILT)
BUILT_SYSTEM_MANIFEST := $(LOCAL_BUILT_MODULE)

