#############################################################################
## Standard rules for installing runtime resouce overlay APKs.
##
## Set LOCAL_RRO_THEME to the theme name if the package should apply only to
## a particular theme as set by ro.boot.vendor.overlay.theme system property.
##
## If LOCAL_RRO_THEME is not set, the package will apply always, independent
## of themes.
##
#############################################################################

LOCAL_IS_RUNTIME_RESOURCE_OVERLAY := true

ifneq ($(LOCAL_SRC_FILES),)
  $(error runtime resource overlay package should not contain sources)
endif

ifeq (true,$(LOCAL_VENDOR_MODULE))
  my_target_out := $(TARGET_OUT_VENDOR)
else ifeq (true,$(LOCAL_PROPRIETARY_MODULE))
  my_target_out := $(TARGET_OUT_VENDOR)
else ifeq (true,$(LOCAL_OEM_MODULE))
  $(error runtime resource overlay package should not be installed in oem/overlay)
else ifeq (true,$(LOCAL_ODM_MODULE))
  $(error runtime resource overlay package should not be installed in odm/overlay)
else ifeq (true,$(LOCAL_PRODUCT_MODULE))
  my_target_out := $(TARGET_OUT_PRODUCT)
else
  my_target_out := $(TARGET_OUT_VENDOR)
endif

ifeq ($(LOCAL_RRO_THEME),)
  LOCAL_MODULE_PATH := $(my_target_out)/overlay
else
  LOCAL_MODULE_PATH := $(my_target_out)/overlay/$(LOCAL_RRO_THEME)
endif

include $(BUILD_SYSTEM)/package.mk

