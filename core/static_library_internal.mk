###########################################################
## Standard rules for building a static library.
##
## Additional inputs from base_rules.make:
## None.
##
## LOCAL_MODULE_SUFFIX will be set for you.
###########################################################

ifeq ($(strip $(LOCAL_MODULE_CLASS)),)
LOCAL_MODULE_CLASS := STATIC_LIBRARIES
endif
ifeq ($(strip $(LOCAL_MODULE_SUFFIX)),)
LOCAL_MODULE_SUFFIX := .a
endif
LOCAL_UNINSTALLABLE_MODULE := true
ifneq ($(strip $(LOCAL_MODULE_STEM)$(LOCAL_BUILT_MODULE_STEM)),)
$(error $(LOCAL_PATH): Cannot set module stem for a library)
endif

include $(BUILD_SYSTEM)/binary.mk

ifneq ($(my_create_source_abi_dump),false)
ifneq ($(strip $(all_sdump_objects)),)
sabi_lsdump := $(LOCAL_BUILT_MODULE).lsdump
$(sabi_lsdump): $(all_sdump_objects) $(PRIVATE_HEADER_ABI_LINKER)
	$(transform-sdumps-to-lsdump)
$(LOCAL_BUILT_MODULE): $(sabi_lsdump)
zipped_ref_sabi_lsdump := $(VNDK_REF_ABI_DUMP_DIR)/current/$(TARGET_$(LOCAL_2ND_ARCH_VAR_PREFIX)ARCH)/source-based/$(LOCAL_MODULE).a.lsdump.gz
ifneq ($(wildcard $(zipped_ref_sabi_dump)),)
$(eval $(call create-sabi-diff-report,LOCAL_BUILT_MODULE,$(zipped_ref_sabi_lsdump), sabi_lsdump, $(LOCAL_MODULE), $(TARGET_$(LOCAL_2ND_ARCH_VAR_PREFIX)ARCH)))
endif
endif
endif

$(LOCAL_BUILT_MODULE) : $(built_whole_libraries)
$(LOCAL_BUILT_MODULE) : $(all_objects)
	$(transform-o-to-static-lib)

ifeq ($(NATIVE_COVERAGE),true)
gcno_suffix := .gcnodir

built_whole_gcno_libraries := \
    $(foreach lib,$(my_whole_static_libraries), \
      $(call intermediates-dir-for, \
        STATIC_LIBRARIES,$(lib),$(my_kind),,$(LOCAL_2ND_ARCH_VAR_PREFIX), \
        $(my_host_cross))/$(lib)$(gcno_suffix))

GCNO_ARCHIVE := $(LOCAL_MODULE)$(gcno_suffix)

$(intermediates)/$(GCNO_ARCHIVE) : PRIVATE_ALL_OBJECTS := $(strip $(LOCAL_GCNO_FILES))
$(intermediates)/$(GCNO_ARCHIVE) : PRIVATE_ALL_WHOLE_STATIC_LIBRARIES := $(strip $(built_whole_gcno_libraries))
$(intermediates)/$(GCNO_ARCHIVE) : PRIVATE_PREFIX := $(my_prefix)
$(intermediates)/$(GCNO_ARCHIVE) : PRIVATE_2ND_ARCH_VAR_PREFIX := $(LOCAL_2ND_ARCH_VAR_PREFIX)
$(intermediates)/$(GCNO_ARCHIVE) : PRIVATE_INTERMEDIATES_DIR := $(intermediates)
$(intermediates)/$(GCNO_ARCHIVE) : $(LOCAL_GCNO_FILES) $(built_whole_gcno_libraries)
	$(transform-o-to-static-lib)
endif
