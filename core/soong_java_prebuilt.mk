# Java prebuilt coming from Soong.
# Extra inputs:
# LOCAL_SOONG_HEADER_JAR
# LOCAL_SOONG_DEX_JAR
# LOCAL_SOONG_JACOCO_REPORT_CLASSES_JAR

ifneq ($(LOCAL_MODULE_MAKEFILE),$(SOONG_ANDROID_MK))
  $(call pretty-error,soong_java_prebuilt.mk may only be used from Soong)
endif

LOCAL_MODULE_SUFFIX := .jar
LOCAL_BUILT_MODULE_STEM := javalib.jar

#######################################
include $(BUILD_SYSTEM)/base_rules.mk
#######################################

full_classes_jar := $(intermediates.COMMON)/classes.jar
full_classes_pre_proguard_jar := $(intermediates.COMMON)/classes-pre-proguard.jar
full_classes_header_jar := $(intermediates.COMMON)/classes-header.jar
common_javalib.jar := $(intermediates.COMMON)/javalib.jar

$(eval $(call copy-one-file,$(LOCAL_PREBUILT_MODULE_FILE),$(full_classes_jar)))
$(eval $(call copy-one-file,$(LOCAL_PREBUILT_MODULE_FILE),$(full_classes_pre_proguard_jar)))

ifdef LOCAL_SOONG_JACOCO_REPORT_CLASSES_JAR
  $(eval $(call copy-one-file,$(LOCAL_SOONG_JACOCO_REPORT_CLASSES_JAR),\
    $(intermediates.COMMON)/jacoco-report-classes.jar))
  $(call add-dependency,$(common_javalib.jar),\
    $(intermediates.COMMON)/jacoco-report-classes.jar)
endif

ifneq ($(TURBINE_DISABLED),false)
ifdef LOCAL_SOONG_HEADER_JAR
$(eval $(call copy-one-file,$(LOCAL_SOONG_HEADER_JAR),$(full_classes_header_jar)))
else
$(eval $(call copy-one-file,$(full_classes_jar),$(full_classes_header_jar)))
endif
endif # TURBINE_DISABLED != false

ifdef LOCAL_SOONG_DEX_JAR
  ifndef LOCAL_IS_HOST_MODULE
    $(eval $(call copy-one-file,$(LOCAL_SOONG_DEX_JAR),$(common_javalib.jar)))
    $(eval $(call add-dependency,$(common_javalib.jar),$(full_classes_jar) $(full_classes_header_jar)))

    dex_preopt_profile_src_file := $(common_javalib.jar)

    # defines built_odex along with rule to install odex
    include $(BUILD_SYSTEM)/dex_preopt_odex_install.mk

    dex_preopt_profile_src_file :=

    ifdef LOCAL_DEX_PREOPT
      ifneq ($(dexpreopt_boot_jar_module),) # boot jar
        # boot jar's rules are defined in dex_preopt.mk
        dexpreopted_boot_jar := $(DEXPREOPT_BOOT_JAR_DIR_FULL_PATH)/$(dexpreopt_boot_jar_module)_nodex.jar
        $(eval $(call copy-one-file,$(dexpreopted_boot_jar),$(LOCAL_BUILT_MODULE)))

        # For libart boot jars, we don't have .odex files.
      else # ! boot jar
        $(built_odex): PRIVATE_MODULE := $(LOCAL_MODULE)
        # Use pattern rule - we may have multiple built odex files.
$(built_odex) : $(dir $(LOCAL_BUILT_MODULE))% : $(common_javalib.jar)
	@echo "Dexpreopt Jar: $(PRIVATE_MODULE) ($@)"
	$(call dexpreopt-one-file,$<,$@)

       $(eval $(call dexpreopt-copy-jar,$(common_javalib.jar),$(LOCAL_BUILT_MODULE),$(LOCAL_DEX_PREOPT)))
      endif # ! boot jar
    else # LOCAL_DEX_PREOPT
      $(eval $(call copy-one-file,$(common_javalib.jar),$(LOCAL_BUILT_MODULE)))
    endif # LOCAL_DEX_PREOPT
  else # LOCAL_IS_HOST_MODULE
    $(eval $(call copy-one-file,$(LOCAL_SOONG_DEX_JAR),$(LOCAL_BUILT_MODULE)))
    $(eval $(call add-dependency,$(LOCAL_BUILT_MODULE),$(full_classes_jar) $(full_classes_header_jar)))
  endif

  java-dex : $(LOCAL_BUILT_MODULE)
else
  $(eval $(call copy-one-file,$(full_classes_jar),$(LOCAL_BUILT_MODULE)))
endif

javac-check : $(full_classes_jar)
javac-check-$(LOCAL_MODULE) : $(full_classes_jar)

ifndef LOCAL_IS_HOST_MODULE
ifeq ($(LOCAL_SDK_VERSION),system_current)
my_link_type := java:system
my_warn_types := java:platform
my_allowed_types := java:core java:sdk java:system
else ifneq (,$(call has-system-sdk-version,$(LOCAL_SDK_VERSION)))
my_link_type := java:system
my_warn_types := java:platform
my_allowed_types := java:core java:sdk java:system
else ifneq ($(LOCAL_SDK_VERSION),)
my_link_type := java:sdk
my_warn_types := java:system java:platform
my_allowed_types := java:core java:sdk
else ifeq ($(LOCAL_NO_FRAMEWORK_LIBRARIES),true)
my_link_type := java:core
my_warn_types := java:sdk java:system java:platform
my_allowed_types := java:core
else
my_link_type := java:platform
my_warn_types :=
my_allowed_types := java:core java:sdk java:system java:platform
endif

my_link_deps :=
my_2nd_arch_prefix := $(LOCAL_2ND_ARCH_VAR_PREFIX)
my_common := COMMON
include $(BUILD_SYSTEM)/link_type.mk
endif # !LOCAL_IS_HOST_MODULE
