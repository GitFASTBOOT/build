# Only use ANDROID_BUILD_SHELL to wrap around bash.
# DO NOT use other shells such as zsh.
ifdef ANDROID_BUILD_SHELL
SHELL := $(ANDROID_BUILD_SHELL)
else
# Use bash, not whatever shell somebody has installed as /bin/sh
# This is repeated in config.mk, since envsetup.sh runs that file
# directly.
SHELL := /bin/bash
endif

ifndef KATI

host_prebuilts := linux-x86
ifeq ($(shell uname),Darwin)
host_prebuilts := darwin-x86
endif

.PHONY: run_soong_ui
run_soong_ui:
	+@prebuilts/build-tools/$(host_prebuilts)/bin/makeparallel --ninja build/soong/soong_ui.bash --make-mode $(MAKECMDGOALS)

.PHONY: $(MAKECMDGOALS)
$(sort $(MAKECMDGOALS)) : run_soong_ui
	@#empty

else # KATI

# Absolute path of the present working direcotry.
# This overrides the shell variable $PWD, which does not necessarily points to
# the top of the source tree, for example when "make -C" is used in m/mm/mmm.
PWD := $(shell pwd)

TOP := .
TOPDIR :=

BUILD_SYSTEM := $(TOPDIR)build/make/core

# This is the default target.  It must be the first declared target.
.PHONY: droid
DEFAULT_GOAL := droid
$(DEFAULT_GOAL): droid_targets

.PHONY: droid_targets
droid_targets:

# Set up various standard variables based on configuration
# and host information.
include $(BUILD_SYSTEM)/config.mk

ifneq ($(filter $(dont_bother_goals), $(MAKECMDGOALS)),)
dont_bother := true
endif

.KATI_READONLY := SOONG_CONFIG_NAMESPACES
.KATI_READONLY := $(foreach n,$(SOONG_CONFIG_NAMESPACES),SOONG_CONFIG_$(n))
.KATI_READONLY := $(foreach n,$(SOONG_CONFIG_NAMESPACES),$(foreach k,$(SOONG_CONFIG_$(n)),SOONG_CONFIG_$(n)_$(k)))

include $(SOONG_MAKEVARS_MK)

YACC :=$= $(BISON) -d

include $(BUILD_SYSTEM)/clang/config.mk

# Write the build number to a file so it can be read back in
# without changing the command line every time.  Avoids rebuilds
# when using ninja.
$(shell mkdir -p $(OUT_DIR) && \
    echo -n $(BUILD_NUMBER) > $(OUT_DIR)/build_number.txt)
BUILD_NUMBER_FILE := $(OUT_DIR)/build_number.txt

ifeq ($(HOST_OS),darwin)
DATE_FROM_FILE := date -r $(BUILD_DATETIME_FROM_FILE)
else
DATE_FROM_FILE := date -d @$(BUILD_DATETIME_FROM_FILE)
endif

# Pick a reasonable string to use to identify files.
ifeq ($(strip $(HAS_BUILD_NUMBER)),false)
  # BUILD_NUMBER has a timestamp in it, which means that
  # it will change every time.  Pick a stable value.
  FILE_NAME_TAG := eng.$(USER)
else
  FILE_NAME_TAG := $(file <$(BUILD_NUMBER_FILE))
endif

# Make an empty directory, which can be used to make empty jars
EMPTY_DIRECTORY := $(OUT_DIR)/empty
$(shell mkdir -p $(EMPTY_DIRECTORY) && rm -rf $(EMPTY_DIRECTORY)/*)

# CTS-specific config.
-include cts/build/config.mk
# VTS-specific config.
-include test/vts/tools/vts-tradefed/build/config.mk
# device-tests-specific-config.
-include tools/tradefederation/build/suites/device-tests/config.mk
# general-tests-specific-config.
-include tools/tradefederation/build/suites/general-tests/config.mk
# STS-specific config.
-include test/sts/tools/sts-tradefed/build/config.mk
# CTS-Instant-specific config
-include test/suite_harness/tools/cts-instant-tradefed/build/config.mk

# Clean rules
.PHONY: clean-dex-files
clean-dex-files:
	$(hide) find $(OUT_DIR) -name "*.dex" | xargs rm -f
	$(hide) for i in `find $(OUT_DIR) -name "*.jar" -o -name "*.apk"` ; do ((unzip -l $$i 2> /dev/null | \
				grep -q "\.dex$$" && rm -f $$i) || continue ) ; done
	@echo "All dex files and archives containing dex files have been removed."

# Include the google-specific config
-include vendor/google/build/config.mk

# These are the modifier targets that don't do anything themselves, but
# change the behavior of the build.
# (must be defined before including definitions.make)
INTERNAL_MODIFIER_TARGETS := all

# EMMA_INSTRUMENT_STATIC merges the static jacoco library to each
# jacoco-enabled module.
ifeq (true,$(EMMA_INSTRUMENT_STATIC))
EMMA_INSTRUMENT := true
endif

ifeq (true,$(EMMA_INSTRUMENT))
# Adding the jacoco library can cause the inclusion of
# some typically banned classes
# So if the user didn't specify SKIP_BOOT_JARS_CHECK, enable it here
ifndef SKIP_BOOT_JARS_CHECK
SKIP_BOOT_JARS_CHECK := true
endif
endif

ifdef TARGET_ARCH_SUITE
  # TODO(b/175577370): Enable this error.
  # $(error TARGET_ARCH_SUITE is not supported in kati/make builds)
endif

# ADDITIONAL_<partition>_PROPERTIES are properties that are determined by the
# build system itself. Don't let it be defined from outside of the core build
# system like Android.mk or <product>.mk files.
_additional_prop_var_names := \
    ADDITIONAL_SYSTEM_PROPERTIES \
    ADDITIONAL_VENDOR_PROPERTIES \
    ADDITIONAL_ODM_PROPERTIES \
    ADDITIONAL_PRODUCT_PROPERTIES

$(foreach name, $(_additional_prop_var_names),\
  $(if $($(name)),\
    $(error $(name) must not set before here. $($(name)))\
  ,)\
  $(eval $(name) :=)\
)
_additional_prop_var_names :=

<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
=======
$(KATI_obsolete_var ADDITIONAL_BUILD_PROPERTIES, Please use ADDITIONAL_SYSTEM_PROPERTIES)

>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])
#
# -----------------------------------------------------------------
# Add the product-defined properties to the build properties.
ifdef PRODUCT_SHIPPING_API_LEVEL
ADDITIONAL_SYSTEM_PROPERTIES += \
  ro.product.first_api_level=$(PRODUCT_SHIPPING_API_LEVEL)
endif

ifneq ($(BOARD_PROPERTY_OVERRIDES_SPLIT_ENABLED), true)
  ADDITIONAL_SYSTEM_PROPERTIES += $(PRODUCT_PROPERTY_OVERRIDES)
else
  ifndef BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE
    ADDITIONAL_SYSTEM_PROPERTIES += $(PRODUCT_PROPERTY_OVERRIDES)
  endif
endif


# Bring in standard build system definitions.
include $(BUILD_SYSTEM)/definitions.mk

ifneq ($(filter user userdebug eng,$(MAKECMDGOALS)),)
$(info ***************************************************************)
$(info ***************************************************************)
$(info Do not pass '$(filter user userdebug eng,$(MAKECMDGOALS))' on \
       the make command line.)
$(info Set TARGET_BUILD_VARIANT in buildspec.mk, or use lunch or)
$(info choosecombo.)
$(info ***************************************************************)
$(info ***************************************************************)
$(error stopping)
endif

ifneq ($(filter-out $(INTERNAL_VALID_VARIANTS),$(TARGET_BUILD_VARIANT)),)
$(info ***************************************************************)
$(info ***************************************************************)
$(info Invalid variant: $(TARGET_BUILD_VARIANT))
$(info Valid values are: $(INTERNAL_VALID_VARIANTS))
$(info ***************************************************************)
$(info ***************************************************************)
$(error stopping)
endif

# -----------------------------------------------------------------
# PDK builds are no longer supported, this is always platform
TARGET_BUILD_JAVA_SUPPORT_LEVEL :=$= platform

#
# -----------------------------------------------------------------
# Enable dynamic linker and hidden API developer warnings for
# userdebug, eng and non-REL builds
ifneq ($(TARGET_BUILD_VARIANT),user)
  ADDITIONAL_BUILD_PROPERTIES += ro.bionic.ld.warning=1 \
                                 ro.art.hiddenapi.warning=1
else
# Enable it for user builds as long as they are not final.
ifneq ($(PLATFORM_VERSION_CODENAME),REL)
  ADDITIONAL_BUILD_PROPERTIES += ro.bionic.ld.warning=1 \
                                 ro.art.hiddenapi.warning=1
endif
endif

ADDITIONAL_SYSTEM_PROPERTIES += ro.treble.enabled=${PRODUCT_FULL_TREBLE}

$(KATI_obsolete_var PRODUCT_FULL_TREBLE,\
	Code should be written to work regardless of a device being Treble or \
	variables like PRODUCT_SEPOLICY_SPLIT should be used until that is \
	possible.)

<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
# Sets ro.actionable_compatible_property.enabled to know on runtime whether the whitelist
# of actionable compatible properties is enabled or not.
ifeq ($(PRODUCT_ACTIONABLE_COMPATIBLE_PROPERTY_DISABLE),true)
ADDITIONAL_DEFAULT_PROPERTIES += ro.actionable_compatible_property.enabled=false
else
ADDITIONAL_DEFAULT_PROPERTIES += ro.actionable_compatible_property.enabled=${PRODUCT_COMPATIBLE_PROPERTY}
endif
=======
# Sets ro.actionable_compatible_property.enabled to know on runtime whether the
# allowed list of actionable compatible properties is enabled or not.
ADDITIONAL_SYSTEM_PROPERTIES += ro.actionable_compatible_property.enabled=true
>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])

<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
=======
# Add the system server compiler filter if they are specified for the product.
ifneq (,$(PRODUCT_SYSTEM_SERVER_COMPILER_FILTER))
ADDITIONAL_PRODUCT_PROPERTIES += dalvik.vm.systemservercompilerfilter=$(PRODUCT_SYSTEM_SERVER_COMPILER_FILTER)
endif

# Enable core platform API violation warnings on userdebug and eng builds.
ifneq ($(TARGET_BUILD_VARIANT),user)
ADDITIONAL_SYSTEM_PROPERTIES += persist.debug.dalvik.vm.core_platform_api_policy=just-warn
endif

# Define ro.sanitize.<name> properties for all global sanitizers.
ADDITIONAL_SYSTEM_PROPERTIES += $(foreach s,$(SANITIZE_TARGET),ro.sanitize.$(s)=true)

# Sets the default value of ro.postinstall.fstab.prefix to /system.
# Device board config should override the value to /product when needed by:
#
#     PRODUCT_PRODUCT_PROPERTIES += ro.postinstall.fstab.prefix=/product
#
# It then uses ${ro.postinstall.fstab.prefix}/etc/fstab.postinstall to
# mount system_other partition.
ADDITIONAL_SYSTEM_PROPERTIES += ro.postinstall.fstab.prefix=/system

# -----------------------------------------------------------------
# ADDITIONAL_VENDOR_PROPERTIES will be installed in vendor/build.prop if
# property_overrides_split_enabled is true. Otherwise it will be installed in
# /system/build.prop
ifdef BOARD_VNDK_VERSION
  ifeq ($(BOARD_VNDK_VERSION),current)
    ADDITIONAL_VENDOR_PROPERTIES := ro.vndk.version=$(PLATFORM_VNDK_VERSION)
  else
    ADDITIONAL_VENDOR_PROPERTIES := ro.vndk.version=$(BOARD_VNDK_VERSION)
  endif
endif

# Add cpu properties for bionic and ART.
ADDITIONAL_VENDOR_PROPERTIES += ro.bionic.arch=$(TARGET_ARCH)
ADDITIONAL_VENDOR_PROPERTIES += ro.bionic.cpu_variant=$(TARGET_CPU_VARIANT_RUNTIME)
ADDITIONAL_VENDOR_PROPERTIES += ro.bionic.2nd_arch=$(TARGET_2ND_ARCH)
ADDITIONAL_VENDOR_PROPERTIES += ro.bionic.2nd_cpu_variant=$(TARGET_2ND_CPU_VARIANT_RUNTIME)

ADDITIONAL_VENDOR_PROPERTIES += persist.sys.dalvik.vm.lib.2=libart.so
ADDITIONAL_VENDOR_PROPERTIES += dalvik.vm.isa.$(TARGET_ARCH).variant=$(DEX2OAT_TARGET_CPU_VARIANT_RUNTIME)
ifneq ($(DEX2OAT_TARGET_INSTRUCTION_SET_FEATURES),)
  ADDITIONAL_VENDOR_PROPERTIES += dalvik.vm.isa.$(TARGET_ARCH).features=$(DEX2OAT_TARGET_INSTRUCTION_SET_FEATURES)
endif

ifdef TARGET_2ND_ARCH
  ADDITIONAL_VENDOR_PROPERTIES += dalvik.vm.isa.$(TARGET_2ND_ARCH).variant=$($(TARGET_2ND_ARCH_VAR_PREFIX)DEX2OAT_TARGET_CPU_VARIANT_RUNTIME)
  ifneq ($($(TARGET_2ND_ARCH_VAR_PREFIX)DEX2OAT_TARGET_INSTRUCTION_SET_FEATURES),)
    ADDITIONAL_VENDOR_PROPERTIES += dalvik.vm.isa.$(TARGET_2ND_ARCH).features=$($(TARGET_2ND_ARCH_VAR_PREFIX)DEX2OAT_TARGET_INSTRUCTION_SET_FEATURES)
  endif
endif

# Although these variables are prefixed with TARGET_RECOVERY_, they are also needed under charger
# mode (via libminui).
ifdef TARGET_RECOVERY_DEFAULT_ROTATION
ADDITIONAL_VENDOR_PROPERTIES += \
    ro.minui.default_rotation=$(TARGET_RECOVERY_DEFAULT_ROTATION)
endif
ifdef TARGET_RECOVERY_OVERSCAN_PERCENT
ADDITIONAL_VENDOR_PROPERTIES += \
    ro.minui.overscan_percent=$(TARGET_RECOVERY_OVERSCAN_PERCENT)
endif
ifdef TARGET_RECOVERY_PIXEL_FORMAT
ADDITIONAL_VENDOR_PROPERTIES += \
    ro.minui.pixel_format=$(TARGET_RECOVERY_PIXEL_FORMAT)
endif

ifdef PRODUCT_USE_DYNAMIC_PARTITIONS
ADDITIONAL_VENDOR_PROPERTIES += \
    ro.boot.dynamic_partitions=$(PRODUCT_USE_DYNAMIC_PARTITIONS)
endif

ifdef PRODUCT_RETROFIT_DYNAMIC_PARTITIONS
ADDITIONAL_VENDOR_PROPERTIES += \
    ro.boot.dynamic_partitions_retrofit=$(PRODUCT_RETROFIT_DYNAMIC_PARTITIONS)
endif

ifdef PRODUCT_SHIPPING_API_LEVEL
ADDITIONAL_VENDOR_PROPERTIES += \
    ro.product.first_api_level=$(PRODUCT_SHIPPING_API_LEVEL)
endif

ADDITIONAL_VENDOR_PROPERTIES += \
    ro.vendor.build.security_patch=$(VENDOR_SECURITY_PATCH) \
    ro.vendor.product.cpu.abilist=$(TARGET_CPU_ABI_LIST) \
    ro.vendor.product.cpu.abilist32=$(TARGET_CPU_ABI_LIST_32_BIT) \
    ro.vendor.product.cpu.abilist64=$(TARGET_CPU_ABI_LIST_64_BIT) \
    ro.product.board=$(TARGET_BOOTLOADER_BOARD_NAME) \
    ro.board.platform=$(TARGET_BOARD_PLATFORM) \
    ro.hwui.use_vulkan=$(TARGET_USES_VULKAN)

ifdef TARGET_SCREEN_DENSITY
ADDITIONAL_VENDOR_PROPERTIES += \
    ro.sf.lcd_density=$(TARGET_SCREEN_DENSITY)
endif

ifdef AB_OTA_UPDATER
ADDITIONAL_VENDOR_PROPERTIES += \
    ro.build.ab_update=$(AB_OTA_UPDATER)
endif

ADDITIONAL_ODM_PROPERTIES += \
    ro.odm.product.cpu.abilist=$(TARGET_CPU_ABI_LIST) \
    ro.odm.product.cpu.abilist32=$(TARGET_CPU_ABI_LIST_32_BIT) \
    ro.odm.product.cpu.abilist64=$(TARGET_CPU_ABI_LIST_64_BIT)

# Set ro.product.vndk.version to know the VNDK version required by product
# modules. It uses the version in PRODUCT_PRODUCT_VNDK_VERSION. If the value
# is "current", use PLATFORM_VNDK_VERSION.
ifdef PRODUCT_PRODUCT_VNDK_VERSION
ifeq ($(PRODUCT_PRODUCT_VNDK_VERSION),current)
ADDITIONAL_PRODUCT_PROPERTIES += ro.product.vndk.version=$(PLATFORM_VNDK_VERSION)
else
ADDITIONAL_PRODUCT_PROPERTIES += ro.product.vndk.version=$(PRODUCT_PRODUCT_VNDK_VERSION)
endif
endif

ADDITIONAL_PRODUCT_PROPERTIES += ro.build.characteristics=$(TARGET_AAPT_CHARACTERISTICS)

ifeq ($(AB_OTA_UPDATER),true)
ADDITIONAL_PRODUCT_PROPERTIES += ro.product.ab_ota_partitions=$(subst $(space),$(comma),$(AB_OTA_PARTITIONS))
endif

>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])
# -----------------------------------------------------------------
###
### In this section we set up the things that are different
### between the build variants
###

is_sdk_build :=

ifneq ($(filter sdk win_sdk sdk_addon,$(MAKECMDGOALS)),)
is_sdk_build := true
endif

# Add build properties for ART. These define system properties used by installd
# to pass flags to dex2oat.
ADDITIONAL_BUILD_PROPERTIES += persist.sys.dalvik.vm.lib.2=libart.so
ADDITIONAL_BUILD_PROPERTIES += dalvik.vm.isa.$(TARGET_ARCH).variant=$(DEX2OAT_TARGET_CPU_VARIANT)
ifneq ($(DEX2OAT_TARGET_INSTRUCTION_SET_FEATURES),)
  ADDITIONAL_BUILD_PROPERTIES += dalvik.vm.isa.$(TARGET_ARCH).features=$(DEX2OAT_TARGET_INSTRUCTION_SET_FEATURES)
endif

ifdef TARGET_2ND_ARCH
  ADDITIONAL_BUILD_PROPERTIES += dalvik.vm.isa.$(TARGET_2ND_ARCH).variant=$($(TARGET_2ND_ARCH_VAR_PREFIX)DEX2OAT_TARGET_CPU_VARIANT)
  ifneq ($($(TARGET_2ND_ARCH_VAR_PREFIX)DEX2OAT_TARGET_INSTRUCTION_SET_FEATURES),)
    ADDITIONAL_BUILD_PROPERTIES += dalvik.vm.isa.$(TARGET_2ND_ARCH).features=$($(TARGET_2ND_ARCH_VAR_PREFIX)DEX2OAT_TARGET_INSTRUCTION_SET_FEATURES)
  endif
endif

# Add the system server compiler filter if they are specified for the product.
ifneq (,$(PRODUCT_SYSTEM_SERVER_COMPILER_FILTER))
ADDITIONAL_BUILD_PROPERTIES += dalvik.vm.systemservercompilerfilter=$(PRODUCT_SYSTEM_SERVER_COMPILER_FILTER)
endif

## user/userdebug ##

user_variant := $(filter user userdebug,$(TARGET_BUILD_VARIANT))
enable_target_debugging := true
tags_to_install :=
ifneq (,$(user_variant))
  # Target is secure in user builds.
  ADDITIONAL_SYSTEM_PROPERTIES += ro.secure=1
  ADDITIONAL_SYSTEM_PROPERTIES += security.perf_harden=1

  ifeq ($(user_variant),user)
    ADDITIONAL_SYSTEM_PROPERTIES += ro.adb.secure=1
  endif

  ifeq ($(user_variant),userdebug)
    # Pick up some extra useful tools
    tags_to_install += debug
  else
    # Disable debugging in plain user builds.
    enable_target_debugging :=
  endif

  # Disallow mock locations by default for user builds
  ADDITIONAL_SYSTEM_PROPERTIES += ro.allow.mock.location=0

else # !user_variant
  # Turn on checkjni for non-user builds.
  ADDITIONAL_SYSTEM_PROPERTIES += ro.kernel.android.checkjni=1
  # Set device insecure for non-user builds.
  ADDITIONAL_SYSTEM_PROPERTIES += ro.secure=0
  # Allow mock locations by default for non user builds
  ADDITIONAL_SYSTEM_PROPERTIES += ro.allow.mock.location=1
endif # !user_variant

ifeq (true,$(strip $(enable_target_debugging)))
  # Target is more debuggable and adbd is on by default
  ADDITIONAL_SYSTEM_PROPERTIES += ro.debuggable=1
  # Enable Dalvik lock contention logging.
<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
  ADDITIONAL_BUILD_PROPERTIES += dalvik.vm.lockprof.threshold=500
  # Include the debugging/testing OTA keys in this build.
  INCLUDE_TEST_OTA_KEYS := true
=======
  ADDITIONAL_SYSTEM_PROPERTIES += dalvik.vm.lockprof.threshold=500
>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])
else # !enable_target_debugging
  # Target is less debuggable and adbd is off by default
  ADDITIONAL_SYSTEM_PROPERTIES += ro.debuggable=0
endif # !enable_target_debugging

## eng ##

ifeq ($(TARGET_BUILD_VARIANT),eng)
tags_to_install := debug eng
ifneq ($(filter ro.setupwizard.mode=ENABLED, $(call collapse-pairs, $(ADDITIONAL_SYSTEM_PROPERTIES))),)
  # Don't require the setup wizard on eng builds
  ADDITIONAL_SYSTEM_PROPERTIES := $(filter-out ro.setupwizard.mode=%,\
          $(call collapse-pairs, $(ADDITIONAL_SYSTEM_PROPERTIES))) \
          ro.setupwizard.mode=OPTIONAL
endif
ifndef is_sdk_build
  # To speedup startup of non-preopted builds, don't verify or compile the boot image.
<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
  ADDITIONAL_BUILD_PROPERTIES += dalvik.vm.image-dex2oat-filter=verify-at-runtime
=======
  ADDITIONAL_SYSTEM_PROPERTIES += dalvik.vm.image-dex2oat-filter=extract
>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])
endif
endif

## sdk ##

ifdef is_sdk_build

# Detect if we want to build a repository for the SDK
sdk_repo_goal := $(strip $(filter sdk_repo,$(MAKECMDGOALS)))
MAKECMDGOALS := $(strip $(filter-out sdk_repo,$(MAKECMDGOALS)))

ifneq ($(words $(sort $(filter-out $(INTERNAL_MODIFIER_TARGETS) checkbuild emulator_tests,$(MAKECMDGOALS)))),1)
$(error The 'sdk' target may not be specified with any other targets)
endif

# TODO: this should be eng I think.  Since the sdk is built from the eng
# variant.
tags_to_install := debug eng
ADDITIONAL_SYSTEM_PROPERTIES += xmpp.auto-presence=true
ADDITIONAL_SYSTEM_PROPERTIES += ro.config.nocheckin=yes
else # !sdk
endif

BUILD_WITHOUT_PV := true

ADDITIONAL_SYSTEM_PROPERTIES += net.bt.name=Android

# Sets the location that the runtime dumps stack traces to when signalled
# with SIGQUIT. Stack trace dumping is turned on for all android builds.
ADDITIONAL_BUILD_PROPERTIES += dalvik.vm.stack-trace-dir=/data/anr

# ------------------------------------------------------------
# Define a function that, given a list of module tags, returns
# non-empty if that module should be installed in /system.

# For most goals, anything not tagged with the "tests" tag should
# be installed in /system.
define should-install-to-system
$(if $(filter tests,$(1)),,true)
endef

ifdef is_sdk_build
# For the sdk goal, anything with the "samples" tag should be
# installed in /data even if that module also has "eng"/"debug"/"user".
define should-install-to-system
$(if $(filter samples tests,$(1)),,true)
endef
endif


# If they only used the modifier goals (all, etc), we'll actually
# build the default target.
ifeq ($(filter-out $(INTERNAL_MODIFIER_TARGETS),$(MAKECMDGOALS)),)
.PHONY: $(INTERNAL_MODIFIER_TARGETS)
$(INTERNAL_MODIFIER_TARGETS): $(DEFAULT_GOAL)
endif

#
# Typical build; include any Android.mk files we can find.
#

<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
FULL_BUILD := true

# Before we go and include all of the module makefiles, mark the PRODUCT_*
# and ADDITIONAL*PROPERTIES values readonly so that they won't be modified.
$(call readonly-product-vars)
ADDITIONAL_DEFAULT_PROPERTIES := $(strip $(ADDITIONAL_DEFAULT_PROPERTIES))
.KATI_READONLY := ADDITIONAL_DEFAULT_PROPERTIES
ADDITIONAL_BUILD_PROPERTIES := $(strip $(ADDITIONAL_BUILD_PROPERTIES))
.KATI_READONLY := ADDITIONAL_BUILD_PROPERTIES
=======
# Bring in dex_preopt.mk
# This creates some modules so it needs to be included after
# should-install-to-system is defined (in order for base_rules.mk to function
# properly), but before readonly-final-product-vars is called.
include $(BUILD_SYSTEM)/dex_preopt.mk

# Strip and readonly a few more variables so they won't be modified.
$(readonly-final-product-vars)
ADDITIONAL_SYSTEM_PROPERTIES := $(strip $(ADDITIONAL_SYSTEM_PROPERTIES))
.KATI_READONLY := ADDITIONAL_SYSTEM_PROPERTIES
ADDITIONAL_PRODUCT_PROPERTIES := $(strip $(ADDITIONAL_PRODUCT_PROPERTIES))
.KATI_READONLY := ADDITIONAL_PRODUCT_PROPERTIES
>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])

ifneq ($(PRODUCT_ENFORCE_RRO_TARGETS),)
ENFORCE_RRO_SOURCES :=
endif

ifneq ($(ONE_SHOT_MAKEFILE),)
# We've probably been invoked by the "mm" shell function
# with a subdirectory's makefile.
include $(SOONG_ANDROID_MK) $(wildcard $(ONE_SHOT_MAKEFILE))
# Change CUSTOM_MODULES to include only modules that were
# defined by this makefile; this will install all of those
# modules as a side-effect.  Do this after including ONE_SHOT_MAKEFILE
# so that the modules will be installed in the same place they
# would have been with a normal make.
CUSTOM_MODULES := $(sort $(call get-tagged-modules,$(ALL_MODULE_TAGS)))
FULL_BUILD :=
# Stub out the notice targets, which probably aren't defined
# when using ONE_SHOT_MAKEFILE.
NOTICE-HOST-%: ;
NOTICE-TARGET-%: ;

# A helper goal printing out install paths
define register_module_install_path
.PHONY: GET-MODULE-INSTALL-PATH-$(1)
GET-MODULE-INSTALL-PATH-$(1):
	echo 'INSTALL-PATH: $(1) $(ALL_MODULES.$(1).INSTALLED)'
endef

SORTED_ALL_MODULES := $(sort $(ALL_MODULES))
UNIQUE_ALL_MODULES :=
$(foreach m,$(SORTED_ALL_MODULES),\
    $(if $(call streq,$(m),$(lastword $(UNIQUE_ALL_MODULES))),,\
        $(eval UNIQUE_ALL_MODULES += $(m))))
SORTED_ALL_MODULES :=

$(foreach mod,$(UNIQUE_ALL_MODULES),$(if $(ALL_MODULES.$(mod).INSTALLED),\
    $(eval $(call register_module_install_path,$(mod)))\
    $(foreach path,$(ALL_MODULES.$(mod).PATH),\
        $(eval my_path_prefix := GET-INSTALL-PATH-IN)\
        $(foreach component,$(subst /,$(space),$(path)),\
            $(eval my_path_prefix := $$(my_path_prefix)-$$(component))\
            $(eval .PHONY: $$(my_path_prefix))\
            $(eval $$(my_path_prefix): GET-MODULE-INSTALL-PATH-$(mod))))))
UNIQUE_ALL_MODULES :=

else # ONE_SHOT_MAKEFILE

ifneq ($(dont_bother),true)
#
# Include all of the makefiles in the system
#

subdir_makefiles := $(SOONG_ANDROID_MK) $(file <$(OUT_DIR)/.module_paths/Android.mk.list)
subdir_makefiles_total := $(words $(subdir_makefiles))
.KATI_READONLY := subdir_makefiles_total

$(foreach mk,$(subdir_makefiles),$(info [$(call inc_and_print,subdir_makefiles_inc)/$(subdir_makefiles_total)] including $(mk) ...)$(eval include $(mk)))

droid_targets : blueprint_tools

endif # dont_bother

endif # ONE_SHOT_MAKEFILE

# -------------------------------------------------------------------
# All module makefiles have been included at this point.
# -------------------------------------------------------------------

# -------------------------------------------------------------------
# Enforce to generate all RRO packages for modules having resource
# overlays.
# -------------------------------------------------------------------
ifneq ($(PRODUCT_ENFORCE_RRO_TARGETS),)
$(call generate_all_enforce_rro_packages)
endif

# -------------------------------------------------------------------
# Sort ALL_MODULES to remove duplicate entries.
# -------------------------------------------------------------------
ALL_MODULES := $(sort $(ALL_MODULES))
# Cannot set to readonly because Makefile extends ALL_MODULES
# .KATI_READONLY := ALL_MODULES

# -------------------------------------------------------------------
# Fix up CUSTOM_MODULES to refer to installed files rather than
# just bare module names.  Leave unknown modules alone in case
# they're actually full paths to a particular file.
known_custom_modules := $(filter $(ALL_MODULES),$(CUSTOM_MODULES))
unknown_custom_modules := $(filter-out $(ALL_MODULES),$(CUSTOM_MODULES))
CUSTOM_MODULES := \
	$(call module-installed-files,$(known_custom_modules)) \
	$(unknown_custom_modules)

# -------------------------------------------------------------------
# Define dependencies for modules that require other modules.
# This can only happen now, after we've read in all module makefiles.
#
# TODO: deal with the fact that a bare module name isn't
# unambiguous enough.  Maybe declare short targets like
# APPS:Quake or HOST:SHARED_LIBRARIES:libutils.
# BUG: the system image won't know to depend on modules that are
# brought in as requirements of other modules.
#
# Resolve the required module name to 32-bit or 64-bit variant.
<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
# Get a list of corresponding 32-bit module names, if one exists.
ifneq ($(TARGET_TRANSLATE_2ND_ARCH),true)
define get-32-bit-modules
$(sort $(foreach m,$(1),\
  $(if $(ALL_MODULES.$(m)$(TARGET_2ND_ARCH_MODULE_SUFFIX).CLASS),\
    $(m)$(TARGET_2ND_ARCH_MODULE_SUFFIX))\
  $(if $(ALL_MODULES.$(m)$(HOST_2ND_ARCH_MODULE_SUFFIX).CLASS),\
    $(m)$(HOST_2ND_ARCH_MODULE_SUFFIX))\
    ))
endef
# Get a list of corresponding 32-bit module names, if one exists;
# otherwise return the original module name
define get-32-bit-modules-if-we-can
$(sort $(foreach m,$(1),\
  $(if $(ALL_MODULES.$(m)$(TARGET_2ND_ARCH_MODULE_SUFFIX).CLASS)$(ALL_MODULES.$(m)$(HOST_2ND_ARCH_MODULE_SUFFIX).CLASS),\
    $(if $(ALL_MODULES.$(m)$(TARGET_2ND_ARCH_MODULE_SUFFIX).CLASS),$(m)$(TARGET_2ND_ARCH_MODULE_SUFFIX)) \
    $(if $(ALL_MODULES.$(m)$(HOST_2ND_ARCH_MODULE_SUFFIX).CLASS),$(m)$(HOST_2ND_ARCH_MODULE_SUFFIX)),\
  $(m))))
endef
else  # TARGET_TRANSLATE_2ND_ARCH
# For binary translation config, by default only install the first arch.
define get-32-bit-modules
endef
=======
>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])

<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
define get-32-bit-modules-if-we-can
$(strip $(1))
endef
endif  # TARGET_TRANSLATE_2ND_ARCH

# If a module is for a cross host os, the required modules must be for
# that OS too.
# If a module is built for 32-bit, the required modules must be 32-bit too;
# Otherwise if the module is an executable or shared library,
#   the required modules must be 64-bit;
#   otherwise we require both 64-bit and 32-bit variant, if one exists.
define select-bitness-of-required-modules
$(foreach m,$(ALL_MODULES),\
  $(eval r := $(ALL_MODULES.$(m).REQUIRED))\
  $(if $(r),\
    $(if $(ALL_MODULES.$(m).FOR_HOST_CROSS),\
      $(eval r := $(addprefix host_cross_,$(r))))\
    $(if $(ALL_MODULES.$(m).FOR_2ND_ARCH),\
      $(eval r_r := $(call get-32-bit-modules-if-we-can,$(r))),\
      $(if $(filter EXECUTABLES SHARED_LIBRARIES NATIVE_TESTS,$(ALL_MODULES.$(m).CLASS)),\
        $(eval r_r := $(r)),\
        $(eval r_r := $(r) $(call get-32-bit-modules,$(r)))\
       )\
     )\
     $(eval ALL_MODULES.$(m).REQUIRED := $(strip $(r_r)))\
  )\
=======
# Get a list of corresponding module names for the second arch, if they exist.
# $(1): TARGET, HOST or HOST_CROSS
# $(2): A list of module names
define get-modules-for-2nd-arch
$(strip \
  $(foreach m,$(2), \
    $(if $(filter true,$(ALL_MODULES.$(m)$($(1)_2ND_ARCH_MODULE_SUFFIX).FOR_2ND_ARCH)), \
      $(m)$($(1)_2ND_ARCH_MODULE_SUFFIX) \
    ) \
  ) \
>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])
)
endef
<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
$(call select-bitness-of-required-modules)
r_r :=
=======

# Resolves module bitness for PRODUCT_PACKAGES and PRODUCT_HOST_PACKAGES.
# The returned list of module names can be used to access
# ALL_MODULES.<module>.<*> variables.
# Name resolution for PRODUCT_PACKAGES / PRODUCT_HOST_PACKAGES:
#   foo:32 resolves to foo_32;
#   foo:64 resolves to foo;
#   foo resolves to both foo and foo_32 (if foo_32 is defined).
#
# Name resolution for HOST_CROSS modules:
#   foo:32 resolves to foo;
#   foo:64 resolves to foo_64;
#   foo resolves to both foo and foo_64 (if foo_64 is defined).
#
# $(1): TARGET, HOST or HOST_CROSS
# $(2): A list of simple module names with :32 and :64 suffix
define resolve-bitness-for-modules
$(strip \
  $(eval modules_32 := $(patsubst %:32,%,$(filter %:32,$(2)))) \
  $(eval modules_64 := $(patsubst %:64,%,$(filter %:64,$(2)))) \
  $(eval modules_both := $(filter-out %:32 %:64,$(2))) \
  $(eval ### if 2ND_HOST_CROSS_IS_64_BIT, then primary/secondary are reversed for HOST_CROSS modules) \
  $(if $(filter HOST_CROSS_true,$(1)_$(2ND_HOST_CROSS_IS_64_BIT)), \
    $(eval modules_1st_arch := $(modules_32)) \
    $(eval modules_2nd_arch := $(modules_64)), \
    $(eval modules_1st_arch := $(modules_64)) \
    $(eval modules_2nd_arch := $(modules_32))) \
  $(eval ### Note for 32-bit product, 32 and 64 will be added as their original module names.) \
  $(eval modules := $(modules_1st_arch)) \
  $(if $($(1)_2ND_ARCH), \
    $(eval modules += $(call get-modules-for-2nd-arch,$(1),$(modules_2nd_arch))), \
    $(eval modules += $(modules_2nd_arch))) \
  $(eval ### For the rest we add both) \
  $(eval modules += $(modules_both)) \
  $(if $($(1)_2ND_ARCH), \
    $(eval modules += $(call get-modules-for-2nd-arch,$(1),$(modules_both)))) \
  $(modules) \
)
endef

# Resolve the required module names to 32-bit or 64-bit variant for:
#   ALL_MODULES.<*>.REQUIRED_FROM_TARGET
#   ALL_MODULES.<*>.REQUIRED_FROM_HOST
#   ALL_MODULES.<*>.REQUIRED_FROM_HOST_CROSS
#
# If a module is for cross host OS, the required modules are also for that OS.
# Required modules explicitly suffixed with :32 or :64 resolve to that bitness.
# Otherwise if the requiring module is native and the required module is shared
# library or native test, then the required module resolves to the same bitness.
# Otherwise the required module resolves to both variants, if they exist.
# $(1): TARGET, HOST or HOST_CROSS
define select-bitness-of-required-modules
$(foreach m,$(ALL_MODULES), \
  $(eval r := $(ALL_MODULES.$(m).REQUIRED_FROM_$(1))) \
  $(if $(r), \
    $(if $(filter HOST_CROSS,$(1)), \
      $(if $(ALL_MODULES.$(m).FOR_HOST_CROSS),,$(error Only expected REQUIRED_FROM_HOST_CROSS on FOR_HOST_CROSS modules - $(m))) \
      $(eval r := $(addprefix host_cross_,$(r)))) \
    $(eval module_is_native := \
      $(filter EXECUTABLES SHARED_LIBRARIES NATIVE_TESTS,$(ALL_MODULES.$(m).CLASS))) \
    $(eval r_r := \
      $(foreach r_i,$(r), \
        $(if $(filter %:32 %:64,$(r_i)), \
          $(eval r_m := $(call resolve-bitness-for-modules,$(1),$(r_i))), \
          $(eval r_m := \
            $(eval r_i_2nd := $(call get-modules-for-2nd-arch,$(1),$(r_i))) \
            $(eval required_is_shared_library_or_native_test := \
              $(filter SHARED_LIBRARIES NATIVE_TESTS, \
                $(ALL_MODULES.$(r_i).CLASS) $(ALL_MODULES.$(r_i_2nd).CLASS))) \
            $(if $(and $(module_is_native),$(required_is_shared_library_or_native_test)), \
              $(if $(ALL_MODULES.$(m).FOR_2ND_ARCH),$(r_i_2nd),$(r_i)), \
              $(r_i) $(r_i_2nd)))) \
        $(eval r_m := $(foreach r_j,$(r_m),$(if $(ALL_MODULES.$(r_j).PATH),$(r_j)))) \
        $(if $(r_m),,$(eval _nonexistent_required += $(1)$(comma)$(m)$(comma)$(1)$(comma)$(r_i))) \
        $(r_m))) \
    $(eval ALL_MODULES.$(m).REQUIRED_FROM_$(1) := $(sort $(r_r))) \
  ) \
)
endef

# Resolve the required module names to 32-bit or 64-bit variant for:
#   ALL_MODULES.<*>.TARGET_REQUIRED_FROM_HOST
#   ALL_MODULES.<*>.HOST_REQUIRED_FROM_TARGET
#
# This is like select-bitness-of-required-modules, but it doesn't have
# complicated logic for various module types.
# Calls resolve-bitness-for-modules to resolve module names.
# $(1): TARGET or HOST
# $(2): HOST or TARGET
define select-bitness-of-target-host-required-modules
$(foreach m,$(ALL_MODULES), \
  $(eval r := $(ALL_MODULES.$(m).$(1)_REQUIRED_FROM_$(2))) \
  $(if $(r), \
    $(eval r_r := \
      $(foreach r_i,$(r), \
        $(eval r_m := $(call resolve-bitness-for-modules,$(1),$(r_i))) \
        $(eval r_m := $(foreach r_j,$(r_m),$(if $(ALL_MODULES.$(r_j).PATH),$(r_j)))) \
        $(if $(r_m),,$(eval _nonexistent_required += $(2)$(comma)$(m)$(comma)$(1)$(comma)$(r_i))) \
        $(r_m))) \
    $(eval ALL_MODULES.$(m).$(1)_REQUIRED_FROM_$(2) := $(sort $(r_r))) \
  ) \
)
endef

_nonexistent_required :=
$(call select-bitness-of-required-modules,TARGET)
$(call select-bitness-of-required-modules,HOST)
$(call select-bitness-of-required-modules,HOST_CROSS)
$(call select-bitness-of-target-host-required-modules,TARGET,HOST)
$(call select-bitness-of-target-host-required-modules,HOST,TARGET)
_nonexistent_required := $(sort $(_nonexistent_required))

check_missing_required_modules := true
ifneq (,$(filter true,$(ALLOW_MISSING_DEPENDENCIES) $(BUILD_BROKEN_MISSING_REQUIRED_MODULES)))
  check_missing_required_modules :=
endif # ALLOW_MISSING_DEPENDENCIES == true || BUILD_BROKEN_MISSING_REQUIRED_MODULES == true

# Some executables are skipped in ASAN SANITIZE_TARGET build, thus breaking their dependencies.
ifneq (,$(filter address,$(SANITIZE_TARGET)))
  check_missing_required_modules :=
endif # SANITIZE_TARGET has ASAN

# HOST OS darwin build is broken, disable this check for darwin for now.
# TODO(b/162102724): Remove this when darwin host has no broken dependency.
ifneq (,$(filter $(HOST_OS),darwin))
  check_missing_required_modules :=
endif # HOST_OS == darwin

ifeq (true,$(check_missing_required_modules))
ifneq (,$(_nonexistent_required))
  $(warning Missing required dependencies:)
  $(foreach r_i,$(_nonexistent_required), \
    $(eval r := $(subst $(comma),$(space),$(r_i))) \
    $(info $(word 1,$(r)) module $(word 2,$(r)) requires non-existent $(word 3,$(r)) module: $(word 4,$(r))) \
  )
  $(warning Set BUILD_BROKEN_MISSING_REQUIRED_MODULES := true to bypass this check if this is intentional)
  $(error Build failed)
endif # _nonexistent_required != empty
endif # check_missing_required_modules == true
>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])

define add-required-deps
$(1): | $(2)
endef

# Use a normal dependency instead of an order-only dependency when installing
# host dynamic binaries so that the timestamp of the final binary always
# changes, even if the toc optimization has skipped relinking the binary
# and its dependant shared libraries.
define add-required-host-so-deps
$(1): $(2)
endef

# Sets up dependencies such that whenever a host module is installed,
# any other host modules listed in $(ALL_MODULES.$(m).REQUIRED) will also be installed
define add-all-host-to-host-required-modules-deps
$(foreach m,$(ALL_MODULES), \
  $(eval r := $(ALL_MODULES.$(m).REQUIRED)) \
  $(if $(r), \
    $(eval r := $(call module-installed-files,$(r))) \
    $(eval h_m := $(filter $(HOST_OUT)/%, $(ALL_MODULES.$(m).INSTALLED))) \
    $(eval hc_m := $(filter $(HOST_CROSS_OUT)/%, $(ALL_MODULES.$(m).INSTALLED))) \
    $(eval h_r := $(filter $(HOST_OUT)/%, $(r))) \
<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
    $(eval hc_r := $(filter $(HOST_CROSS_OUT)/%, $(r))) \
    $(eval h_m := $(filter-out $(h_r), $(h_m))) \
    $(eval hc_m := $(filter-out $(hc_r), $(hc_m))) \
=======
    $(eval h_r := $(filter-out $(h_m), $(h_r))) \
>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])
    $(if $(h_m), $(eval $(call add-required-deps, $(h_m),$(h_r)))) \
    $(if $(hc_m), $(eval $(call add-required-deps, $(hc_m),$(hc_r)))) \
  ) \
)
endef
$(call add-all-host-to-host-required-modules-deps)

<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
=======
# Sets up dependencies such that whenever a host cross module is installed,
# any other host cross modules listed in $(ALL_MODULES.$(m).REQUIRED_FROM_HOST_CROSS) will also be installed
define add-all-host-cross-to-host-cross-required-modules-deps
$(foreach m,$(ALL_MODULES), \
  $(eval r := $(ALL_MODULES.$(m).REQUIRED_FROM_HOST_CROSS)) \
  $(if $(r), \
    $(eval r := $(call module-installed-files,$(r))) \
    $(eval hc_m := $(filter $(HOST_CROSS_OUT)/%, $(ALL_MODULES.$(m).INSTALLED))) \
    $(eval hc_r := $(filter $(HOST_CROSS_OUT)/%, $(r))) \
    $(eval hc_r := $(filter-out $(hc_m), $(hc_r))) \
    $(if $(hc_m), $(eval $(call add-required-deps, $(hc_m),$(hc_r)))) \
  ) \
)
endef
$(call add-all-host-cross-to-host-cross-required-modules-deps)

>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])
# Sets up dependencies such that whenever a target module is installed,
# any other target modules listed in $(ALL_MODULES.$(m).REQUIRED) will also be installed
define add-all-target-to-target-required-modules-deps
$(foreach m,$(ALL_MODULES), \
  $(eval r := $(ALL_MODULES.$(m).REQUIRED)) \
  $(if $(r), \
    $(eval r := $(call module-installed-files,$(r))) \
    $(eval t_m := $(filter $(TARGET_OUT_ROOT)/%, $(ALL_MODULES.$(m).INSTALLED))) \
    $(eval t_r := $(filter $(TARGET_OUT_ROOT)/%, $(r))) \
    $(eval t_r := $(filter-out $(t_m), $(t_r))) \
    $(if $(t_m), $(eval $(call add-required-deps, $(t_m),$(t_r)))) \
  ) \
)
endef
$(call add-all-target-to-target-required-modules-deps)

# Sets up dependencies such that whenever a host module is installed,
# any target modules listed in $(ALL_MODULES.$(m).TARGET_REQUIRED) will also be installed
define add-all-host-to-target-required-modules-deps
$(foreach m,$(ALL_MODULES), \
  $(eval req_mods := $(ALL_MODULES.$(m).TARGET_REQUIRED))\
  $(if $(req_mods), \
    $(eval req_files := )\
    $(foreach req_mod,$(req_mods), \
      $(eval req_file := $(filter $(TARGET_OUT_ROOT)/%, $(call module-installed-files,$(req_mod)))) \
      $(if $(filter true,$(ALLOW_MISSING_DEPENDENCIES)), \
        , \
        $(if $(strip $(req_file)), \
          , \
          $(error $(m).LOCAL_TARGET_REQUIRED_MODULES : illegal value $(req_mod) : not a device module. If you want to specify host modules to be required to be installed along with your host module, add those module names to LOCAL_REQUIRED_MODULES instead) \
        ) \
      ) \
      $(eval req_files := $(req_files)$(space)$(req_file))\
    )\
    $(eval req_files := $(strip $(req_files)))\
    $(eval mod_files := $(filter $(HOST_OUT)/%, $(call module-installed-files,$(m)))) \
    $(if $(mod_files),\
      $(eval $(call add-required-deps, $(mod_files),$(req_files))) \
    )\
  )\
)
endef
$(call add-all-host-to-target-required-modules-deps)

# Sets up dependencies such that whenever a target module is installed,
# any host modules listed in $(ALL_MODULES.$(m).HOST_REQUIRED) will also be installed
define add-all-target-to-host-required-modules-deps
$(foreach m,$(ALL_MODULES), \
  $(eval req_mods := $(ALL_MODULES.$(m).HOST_REQUIRED))\
  $(if $(req_mods), \
    $(eval req_files := )\
    $(foreach req_mod,$(req_mods), \
      $(eval req_file := $(filter $(HOST_OUT)/%, $(call module-installed-files,$(req_mod)))) \
      $(if $(filter true,$(ALLOW_MISSING_DEPENDENCIES)), \
        , \
        $(if $(strip $(req_file)), \
          , \
          $(error $(m).LOCAL_HOST_REQUIRED_MODULES : illegal value $(req_mod) : not a host module. If you want to specify target modules to be required to be installed along with your target module, add those module names to LOCAL_REQUIRED_MODULES instead) \
        ) \
      ) \
      $(eval req_files := $(req_files)$(space)$(req_file))\
    )\
    $(eval req_files := $(strip $(req_files)))\
    $(eval mod_files := $(filter $(TARGET_OUT_ROOT)/%, $(call module-installed-files,$(m))))\
    $(if $(mod_files),\
      $(eval $(call add-required-deps, $(mod_files),$(req_files))) \
    )\
  )\
)
endef
$(call add-all-target-to-host-required-modules-deps)

t_m :=
h_m :=
hc_m :=
t_r :=
h_r :=
hc_r :=

# Establish the dependencies on the shared libraries.
# It also adds the shared library module names to ALL_MODULES.$(m).REQUIRED,
# so they can be expanded to product_MODULES later.
# $(1): TARGET_ or HOST_ or HOST_CROSS_.
# $(2): non-empty for 2nd arch.
# $(3): non-empty for host cross compile.
define resolve-shared-libs-depes
$(foreach m,$($(if $(2),$($(1)2ND_ARCH_VAR_PREFIX))$(1)DEPENDENCIES_ON_SHARED_LIBRARIES),\
  $(eval p := $(subst :,$(space),$(m)))\
  $(eval mod := $(firstword $(p)))\
  $(eval deps := $(subst $(comma),$(space),$(lastword $(p))))\
  $(eval root := $(1)OUT$(if $(call streq,$(1),TARGET_),_ROOT))\
  $(if $(2),$(eval deps := $(addsuffix $($(1)2ND_ARCH_MODULE_SUFFIX),$(deps))))\
  $(if $(3),$(eval deps := $(addprefix host_cross_,$(deps))))\
  $(eval r := $(filter $($(root))/%,$(call module-installed-files,\
    $(deps))))\
  $(if $(filter $(1),HOST_),\
    $(eval $(call add-required-host-so-deps,$(word 2,$(p)),$(r))),\
    $(eval $(call add-required-deps,$(word 2,$(p)),$(r))))\
<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
  $(eval ALL_MODULES.$(mod).REQUIRED += $(deps)))
=======
  $(eval ALL_MODULES.$(mod).REQUIRED_FROM_$(patsubst %_,%,$(1)) += $(deps)))
endef

# Recursively resolve host shared library dependency for a given module.
# $(1): module name
# Returns all dependencies of shared library.
define get-all-shared-libs-deps
$(if $(_all_deps_for_$(1)_set_),$(_all_deps_for_$(1)_),\
  $(eval _all_deps_for_$(1)_ :=) \
  $(foreach dep,$(ALL_MODULES.$(1).HOST_SHARED_LIBRARIES),\
    $(foreach m,$(call get-all-shared-libs-deps,$(dep)),\
      $(eval _all_deps_for_$(1)_ := $$(_all_deps_for_$(1)_) $(m))\
      $(eval _all_deps_for_$(1)_ := $(sort $(_all_deps_for_$(1)_))))\
    $(eval _all_deps_for_$(1)_ := $$(_all_deps_for_$(1)_) $(dep))\
    $(eval _all_deps_for_$(1)_ := $(sort $(_all_deps_for_$(1)_) $(dep)))\
    $(eval _all_deps_for_$(1)_set_ := true))\
$(_all_deps_for_$(1)_))
endef

# Scan all modules in general-tests, device-tests and other selected suites and
# flatten the shared library dependencies.
define update-host-shared-libs-deps-for-suites
$(foreach suite,general-tests device-tests vts art-host-tests host-unit-tests,\
  $(foreach m,$(COMPATIBILITY.$(suite).MODULES),\
    $(eval my_deps := $(call get-all-shared-libs-deps,$(m)))\
    $(foreach dep,$(my_deps),\
      $(foreach f,$(ALL_MODULES.$(dep).HOST_SHARED_LIBRARY_FILES),\
        $(if $(filter $(suite),device-tests general-tests),\
          $(eval my_testcases := $(HOST_OUT_TESTCASES)),\
          $(eval my_testcases := $$(COMPATIBILITY_TESTCASES_OUT_$(suite))))\
        $(eval target := $(my_testcases)/$(lastword $(subst /, ,$(dir $(f))))/$(notdir $(f)))\
        $(eval COMPATIBILITY.$(suite).HOST_SHARED_LIBRARY.FILES := \
          $$(COMPATIBILITY.$(suite).HOST_SHARED_LIBRARY.FILES) $(f):$(target))\
        $(eval COMPATIBILITY.$(suite).HOST_SHARED_LIBRARY.FILES := \
          $(sort $(COMPATIBILITY.$(suite).HOST_SHARED_LIBRARY.FILES)))))))
>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])
endef

$(call resolve-shared-libs-depes,TARGET_)
ifdef TARGET_2ND_ARCH
$(call resolve-shared-libs-depes,TARGET_,true)
endif
$(call resolve-shared-libs-depes,HOST_)
ifdef HOST_2ND_ARCH
$(call resolve-shared-libs-depes,HOST_,true)
endif
ifdef HOST_CROSS_OS
$(call resolve-shared-libs-depes,HOST_CROSS_,,true)
<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
=======
ifdef HOST_CROSS_2ND_ARCH
$(call resolve-shared-libs-depes,HOST_CROSS_,true,true)
endif
endif

# Pass the shared libraries dependencies to prebuilt ELF file check.
define add-elf-file-check-shared-lib
$(1): PRIVATE_SHARED_LIBRARY_FILES += $(2)
$(1): $(2)
endef

define resolve-shared-libs-for-elf-file-check
$(foreach m,$($(if $(2),$($(1)2ND_ARCH_VAR_PREFIX))$(1)DEPENDENCIES_ON_SHARED_LIBRARIES),\
  $(eval p := $(subst :,$(space),$(m)))\
  $(eval mod := $(firstword $(p)))\
  \
  $(eval deps := $(subst $(comma),$(space),$(lastword $(p))))\
  $(if $(2),$(eval deps := $(addsuffix $($(1)2ND_ARCH_MODULE_SUFFIX),$(deps))))\
  $(eval root := $(1)OUT$(if $(call streq,$(1),TARGET_),_ROOT))\
  $(eval deps := $(filter $($(root))/%$($(1)SHLIB_SUFFIX),$(call module-built-files,$(deps))))\
  \
  $(eval r := $(firstword $(filter \
    $($(if $(2),$($(1)2ND_ARCH_VAR_PREFIX))TARGET_OUT_INTERMEDIATES)/EXECUTABLES/%\
    $($(if $(2),$($(1)2ND_ARCH_VAR_PREFIX))TARGET_OUT_INTERMEDIATES)/NATIVE_TESTS/%\
    $($(if $(2),$($(1)2ND_ARCH_VAR_PREFIX))TARGET_OUT_INTERMEDIATES)/SHARED_LIBRARIES/%,\
    $(call module-built-files,$(mod)))))\
  \
  $(if $(and $(r),$(deps)),\
    $(eval stamp := $(dir $(r))check_elf_files.timestamp)\
    $(if $(CHECK_ELF_FILES.$(stamp)),\
      $(eval $(call add-elf-file-check-shared-lib,$(stamp),$(deps))))\
  ))
endef

$(call resolve-shared-libs-for-elf-file-check,TARGET_)
ifdef TARGET_2ND_ARCH
$(call resolve-shared-libs-for-elf-file-check,TARGET_,true)
>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])
endif

m :=
r :=
p :=
deps :=
add-required-deps :=

################################################################################
# Link type checking
#
# ALL_LINK_TYPES contains a list of all link type prefixes (generally one per
# module, but APKs can "link" to both java and native code). The link type
# prefix consists of all the information needed by intermediates-dir-for:
#
#  LINK_TYPE:TARGET:_:2ND:STATIC_LIBRARIES:libfoo
#
#   1: LINK_TYPE literal
#   2: prefix
#     - TARGET
#     - HOST
#     - HOST_CROSS
#   3: Whether to use the common intermediates directory or not
#     - _
#     - COMMON
#   4: Whether it's the second arch or not
#     - _
#     - 2ND_
#   5: Module Class
#     - STATIC_LIBRARIES
#     - SHARED_LIBRARIES
#     - ...
#   6: Module Name
#
# Then fields under that are separated by a period and the field name:
#   - TYPE: the link types for this module
#   - MAKEFILE: Where this module was defined
#   - BUILT: The built module location
#   - DEPS: the link type prefixes for the module's dependencies
#   - ALLOWED: the link types to allow in this module's dependencies
#   - WARN: the link types to warn about in this module's dependencies
#
# All of the dependency link types not listed in ALLOWED or WARN will become
# errors.
################################################################################

link_type_error :=

define link-type-prefix
$(word 2,$(subst :,$(space),$(1)))
endef
define link-type-common
$(patsubst _,,$(word 3,$(subst :,$(space),$(1))))
endef
define link-type-2ndarchprefix
$(patsubst _,,$(word 4,$(subst :,$(space),$(1))))
endef
define link-type-class
$(word 5,$(subst :,$(space),$(1)))
endef
define link-type-name
$(word 6,$(subst :,$(space),$(1)))
endef
define link-type-os
$(strip $(eval _p := $(link-type-prefix))\
  $(if $(filter HOST HOST_CROSS,$(_p)),\
    $($(_p)_OS),\
    android))
endef
define link-type-arch
$($(link-type-prefix)_$(link-type-2ndarchprefix)ARCH)
endef
define link-type-name-variant
$(link-type-name) ($(link-type-class) $(link-type-os)-$(link-type-arch))
endef

# $(1): the prefix of the module doing the linking
# $(2): the prefix of the linked module
define link-type-warning
$(shell $(call echo-warning,$($(1).MAKEFILE),"$(call link-type-name,$(1)) ($($(1).TYPE)) should not link against $(call link-type-name,$(2)) ($(3))"))
endef

# $(1): the prefix of the module doing the linking
# $(2): the prefix of the linked module
define link-type-error
$(shell $(call echo-error,$($(1).MAKEFILE),"$(call link-type-name,$(1)) ($($(1).TYPE)) can not link against $(call link-type-name,$(2)) ($(3))"))\
$(eval link_type_error := true)
endef

link-type-missing :=
ifneq ($(ALLOW_MISSING_DEPENDENCIES),true)
  # Print an error message if the linked-to module is missing
  # $(1): the prefix of the module doing the linking
  # $(2): the prefix of the missing module
  define link-type-missing
    $(shell $(call echo-error,$($(1).MAKEFILE),"$(call link-type-name-variant,$(1)) missing $(call link-type-name-variant,$(2))"))\
    $(eval available_variants := $(filter %:$(call link-type-name,$(2)),$(ALL_LINK_TYPES)))\
    $(if $(available_variants),\
      $(info Available variants:)\
      $(foreach v,$(available_variants),$(info $(space)$(space)$(call link-type-name-variant,$(v)))))\
    $(info You can set ALLOW_MISSING_DEPENDENCIES=true in your environment if this is intentional, but that may defer real problems until later in the build.)\
    $(eval link_type_error := true)
  endef
else
  define link-type-missing
    $(eval $$(1).MISSING := true)
  endef
endif

# Verify that $(1) can link against $(2)
# Both $(1) and $(2) are the link type prefix defined above
define verify-link-type
$(foreach t,$($(2).TYPE),\
  $(if $(filter-out $($(1).ALLOWED),$(t)),\
    $(if $(filter $(t),$($(1).WARN)),\
      $(call link-type-warning,$(1),$(2),$(t)),\
      $(call link-type-error,$(1),$(2),$(t)))))
endef

# TODO: Verify all branches/configs have reasonable warnings/errors, and remove
# this override
verify-link-type = $(eval $$(1).MISSING := true)

$(foreach lt,$(ALL_LINK_TYPES),\
  $(foreach d,$($(lt).DEPS),\
    $(if $($(d).TYPE),\
      $(call verify-link-type,$(lt),$(d)),\
      $(call link-type-missing,$(lt),$(d)))))

ifdef link_type_error
  $(error exiting from previous errors)
endif

# The intermediate filename for link type rules
#
# APPS are special -- they have up to three different rules:
#  1. The COMMON rule for Java libraries
#  2. The jni_link_type rule for embedded native code
#  3. The 2ND_jni_link_type for the second architecture native code
define link-type-file
$(eval _ltf_aux_variant:=$(link-type-aux-variant))\
$(if $(_ltf_aux_variant),$(call aux-variant-load-env,$(_ltf_aux_variant)))\
$(call intermediates-dir-for,$(link-type-class),$(link-type-name),$(filter AUX HOST HOST_CROSS,$(link-type-prefix)),$(link-type-common),$(link-type-2ndarchprefix),$(filter HOST_CROSS,$(link-type-prefix)))/$(if $(filter APPS,$(link-type-class)),$(if $(link-type-common),,$(link-type-2ndarchprefix)jni_))link_type\
$(if $(_ltf_aux_variant),$(call aux-variant-load-env,none))\
$(eval _ltf_aux_variant:=)
endef

# Write out the file-based link_type rules for the ALLOW_MISSING_DEPENDENCIES
# case. We always need to write the file for mm to work, but only need to
# check it if we weren't able to check it when reading the Android.mk files.
define link-type-file-rule
my_link_type_deps := $(foreach l,$($(1).DEPS),$(call link-type-file,$(l)))
my_link_type_file := $(call link-type-file,$(1))
$($(1).BUILT): | $$(my_link_type_file)
$$(my_link_type_file): PRIVATE_DEPS := $$(my_link_type_deps)
ifeq ($($(1).MISSING),true)
$$(my_link_type_file): $(CHECK_LINK_TYPE)
endif
$$(my_link_type_file): $$(my_link_type_deps)
	@echo Check module type: $$@
	$$(hide) mkdir -p $$(dir $$@) && rm -f $$@
ifeq ($($(1).MISSING),true)
	$$(hide) $(CHECK_LINK_TYPE) --makefile $($(1).MAKEFILE) --module $(link-type-name) \
	  --type "$($(1).TYPE)" $(addprefix --allowed ,$($(1).ALLOWED)) \
	  $(addprefix --warn ,$($(1).WARN)) $$(PRIVATE_DEPS)
endif
	$$(hide) echo "$($(1).TYPE)" >$$@
endef

$(foreach lt,$(ALL_LINK_TYPES),\
  $(eval $(call link-type-file-rule,$(lt))))

# -------------------------------------------------------------------
# Figure out our module sets.
#
# Of the modules defined by the component makefiles,
# determine what we actually want to build.

###########################################################
## Expand a module name list with REQUIRED modules
###########################################################
# $(1): The variable name that holds the initial module name list.
#       the variable will be modified to hold the expanded results.
# $(2): The initial module name list.
# Returns empty string (maybe with some whitespaces).
define expand-required-modules
<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
$(eval _erm_new_modules := $(sort $(filter-out $($(1)),\
  $(foreach m,$(2),$(ALL_MODULES.$(m).REQUIRED)))))\
$(if $(_erm_new_modules),$(eval $(1) += $(_erm_new_modules))\
  $(call expand-required-modules,$(1),$(_erm_new_modules)))
=======
$(eval _erm_req := $(foreach m,$(2),$(ALL_MODULES.$(m).REQUIRED_FROM_TARGET))) \
$(eval _erm_new_modules := $(sort $(filter-out $($(1)),$(_erm_req)))) \
$(eval _erm_new_overrides := $(call module-overrides,$(_erm_new_modules))) \
$(eval _erm_all_overrides := $(3) $(_erm_new_overrides)) \
$(eval _erm_new_modules := $(filter-out $(_erm_all_overrides), $(_erm_new_modules))) \
$(eval $(1) := $(filter-out $(_erm_new_overrides),$($(1)))) \
$(eval $(1) += $(_erm_new_modules)) \
$(if $(_erm_new_modules),\
  $(call expand-required-modules,$(1),$(_erm_new_modules),$(_erm_all_overrides)))
endef

# Same as expand-required-modules above, but does not handle module overrides, as
# we don't intend to support them on the host.
# $(1): The variable name that holds the initial module name list.
#       the variable will be modified to hold the expanded results.
# $(2): The initial module name list.
# $(3): HOST or HOST_CROSS depending on whether we're expanding host or host cross modules
# Returns empty string (maybe with some whitespaces).
define expand-required-host-modules
$(eval _erm_req := $(foreach m,$(2),$(ALL_MODULES.$(m).REQUIRED_FROM_$(3)))) \
$(eval _erm_new_modules := $(sort $(filter-out $($(1)),$(_erm_req)))) \
$(eval $(1) += $(_erm_new_modules)) \
$(if $(_erm_new_modules),\
  $(call expand-required-host-modules,$(1),$(_erm_new_modules),$(3)))
endef

# Transforms paths relative to PRODUCT_OUT to absolute paths.
# $(1): list of relative paths
# $(2): optional suffix to append to paths
define resolve-product-relative-paths
  $(subst $(_vendor_path_placeholder),$(TARGET_COPY_OUT_VENDOR),\
    $(subst $(_product_path_placeholder),$(TARGET_COPY_OUT_PRODUCT),\
      $(subst $(_system_ext_path_placeholder),$(TARGET_COPY_OUT_SYSTEM_EXT),\
        $(subst $(_odm_path_placeholder),$(TARGET_COPY_OUT_ODM),\
          $(subst $(_vendor_dlkm_path_placeholder),$(TARGET_COPY_OUT_VENDOR_DLKM),\
            $(subst $(_odm_dlkm_path_placeholder),$(TARGET_COPY_OUT_ODM_DLKM),\
              $(foreach p,$(1),$(call append-path,$(PRODUCT_OUT),$(p)$(2)))))))))
endef

# Returns modules included automatically as a result of certain BoardConfig
# variables being set.
define auto-included-modules
  $(if $(BOARD_VNDK_VERSION),vndk_package) \
  $(if $(DEVICE_MANIFEST_FILE),vendor_manifest.xml) \
  $(if $(DEVICE_MANIFEST_SKUS),$(foreach sku, $(DEVICE_MANIFEST_SKUS),vendor_manifest_$(sku).xml)) \
  $(if $(ODM_MANIFEST_FILES),odm_manifest.xml) \
  $(if $(ODM_MANIFEST_SKUS),$(foreach sku, $(ODM_MANIFEST_SKUS),odm_manifest_$(sku).xml)) \

endef

# Lists most of the files a particular product installs, including:
# - PRODUCT_PACKAGES, and their LOCAL_REQUIRED_MODULES
# - PRODUCT_COPY_FILES
# The base list of modules to build for this product is specified
# by the appropriate product definition file, which was included
# by product_config.mk.
# Name resolution for PRODUCT_PACKAGES:
#   foo:32 resolves to foo_32;
#   foo:64 resolves to foo;
#   foo resolves to both foo and foo_32 (if foo_32 is defined).
#
# Name resolution for LOCAL_REQUIRED_MODULES:
#   See the select-bitness-of-required-modules definition.
# $(1): product makefile
define product-installed-files
  $(eval _pif_modules := \
    $(call get-product-var,$(1),PRODUCT_PACKAGES) \
    $(if $(filter eng,$(tags_to_install)),$(call get-product-var,$(1),PRODUCT_PACKAGES_ENG)) \
    $(if $(filter debug,$(tags_to_install)),$(call get-product-var,$(1),PRODUCT_PACKAGES_DEBUG)) \
    $(if $(filter tests,$(tags_to_install)),$(call get-product-var,$(1),PRODUCT_PACKAGES_TESTS)) \
    $(if $(filter asan,$(tags_to_install)),$(call get-product-var,$(1),PRODUCT_PACKAGES_DEBUG_ASAN)) \
    $(if $(filter java_coverage,$(tags_to_install)),$(call get-product-var,$(1),PRODUCT_PACKAGES_DEBUG_JAVA_COVERAGE)) \
    $(call auto-included-modules) \
  ) \
  $(eval ### Filter out the overridden packages and executables before doing expansion) \
  $(eval _pif_overrides := $(call module-overrides,$(_pif_modules))) \
  $(eval _pif_modules := $(filter-out $(_pif_overrides), $(_pif_modules))) \
  $(eval ### Resolve the :32 :64 module name) \
  $(eval _pif_modules := $(sort $(call resolve-bitness-for-modules,TARGET,$(_pif_modules)))) \
  $(call expand-required-modules,_pif_modules,$(_pif_modules),$(_pif_overrides)) \
  $(filter-out $(HOST_OUT_ROOT)/%,$(call module-installed-files, $(_pif_modules))) \
  $(call resolve-product-relative-paths,\
    $(foreach cf,$(call get-product-var,$(1),PRODUCT_COPY_FILES),$(call word-colon,2,$(cf))))
endef

# Similar to product-installed-files above, but handles PRODUCT_HOST_PACKAGES instead
# This does support the :32 / :64 syntax, but does not support module overrides.
define host-installed-files
  $(eval _hif_modules := $(call get-product-var,$(1),PRODUCT_HOST_PACKAGES)) \
  $(eval ### Split host vs host cross modules) \
  $(eval _hcif_modules := $(filter host_cross_%,$(_hif_modules))) \
  $(eval _hif_modules := $(filter-out host_cross_%,$(_hif_modules))) \
  $(eval ### Resolve the :32 :64 module name) \
  $(eval _hif_modules := $(sort $(call resolve-bitness-for-modules,HOST,$(_hif_modules)))) \
  $(eval _hcif_modules := $(sort $(call resolve-bitness-for-modules,HOST_CROSS,$(_hcif_modules)))) \
  $(call expand-required-host-modules,_hif_modules,$(_hif_modules),HOST) \
  $(call expand-required-host-modules,_hcif_modules,$(_hcif_modules),HOST_CROSS) \
  $(filter $(HOST_OUT)/%,$(call module-installed-files, $(_hif_modules))) \
  $(filter $(HOST_CROSS_OUT)/%,$(call module-installed-files, $(_hcif_modules)))
endef

# Fails the build if the given list is non-empty, and prints it entries (stripping PRODUCT_OUT).
# $(1): list of files to print
# $(2): heading to print on failure
define maybe-print-list-and-error
$(if $(strip $(1)), \
  $(warning $(2)) \
  $(info Offending entries:) \
  $(foreach e,$(sort $(1)),$(info    $(patsubst $(PRODUCT_OUT)/%,%,$(e)))) \
  $(error Build failed) \
)
>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])
endef

ifdef FULL_BUILD
<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
  # The base list of modules to build for this product is specified
  # by the appropriate product definition file, which was included
  # by product_config.mk.
  product_MODULES := $(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_PACKAGES)
ifdef BOARD_VNDK_VERSION
  product_MODULES += vndk_package
endif
  # Filter out the overridden packages before doing expansion
  product_MODULES := $(filter-out $(foreach p, $(product_MODULES), \
      $(PACKAGES.$(p).OVERRIDES)), $(product_MODULES))
  # Filter out executables as well
  product_MODULES := $(filter-out $(foreach m, $(product_MODULES), \
      $(EXECUTABLES.$(m).OVERRIDES)), $(product_MODULES))
=======
  ifneq (true,$(ALLOW_MISSING_DEPENDENCIES))
    # Check to ensure that all modules in PRODUCT_PACKAGES exist (opt in per product)
    ifeq (true,$(PRODUCT_ENFORCE_PACKAGES_EXIST))
      _allow_list := $(PRODUCT_ENFORCE_PACKAGES_EXIST_ALLOW_LIST)
      _modules := $(PRODUCT_PACKAGES)
      # Strip :32 and :64 suffixes
      _modules := $(patsubst %:32,%,$(_modules))
      _modules := $(patsubst %:64,%,$(_modules))
      # Quickly check all modules in PRODUCT_PACKAGES exist. We check for the
      # existence if either <module> or the <module>_32 variant.
      _nonexistent_modules := $(foreach m,$(_modules), \
        $(if $(or $(ALL_MODULES.$(m).PATH),$(call get-modules-for-2nd-arch,TARGET,$(m))),,$(m)))
      $(call maybe-print-list-and-error,$(filter-out $(_allow_list),$(_nonexistent_modules)),\
        $(INTERNAL_PRODUCT) includes non-existent modules in PRODUCT_PACKAGES)
      $(call maybe-print-list-and-error,$(filter-out $(_nonexistent_modules),$(_allow_list)),\
        $(INTERNAL_PRODUCT) includes redundant allow list entries for non-existent PRODUCT_PACKAGES)
    endif
>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])

  # Resolve the :32 :64 module name
  modules_32 := $(patsubst %:32,%,$(filter %:32, $(product_MODULES)))
  modules_64 := $(patsubst %:64,%,$(filter %:64, $(product_MODULES)))
  modules_rest := $(filter-out %:32 %:64,$(product_MODULES))
  # Note for 32-bit product, $(modules_32) and $(modules_64) will be
  # added as their original module names.
  product_MODULES := $(call get-32-bit-modules-if-we-can, $(modules_32))
  product_MODULES += $(modules_64)
  # For the rest we add both
  product_MODULES += $(call get-32-bit-modules, $(modules_rest))
  product_MODULES += $(modules_rest)

<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
  $(call expand-required-modules,product_MODULES,$(product_MODULES))
=======
  # Modules may produce only host installed files in unbundled builds.
  ifeq (,$(TARGET_BUILD_UNBUNDLED))
    _modules := $(call resolve-bitness-for-modules,TARGET, \
      $(PRODUCT_PACKAGES) \
      $(PRODUCT_PACKAGES_DEBUG) \
      $(PRODUCT_PACKAGES_DEBUG_ASAN) \
      $(PRODUCT_PACKAGES_ENG) \
      $(PRODUCT_PACKAGES_TESTS))
    _host_modules := $(foreach m,$(_modules), \
                  $(if $(ALL_MODULES.$(m).INSTALLED),\
                    $(if $(filter-out $(HOST_OUT_ROOT)/%,$(ALL_MODULES.$(m).INSTALLED)),,\
                      $(m))))
    $(call maybe-print-list-and-error,$(sort $(_host_modules)),\
      Host modules should be in PRODUCT_HOST_PACKAGES$(comma) not PRODUCT_PACKAGES)
  endif
>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])

<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
  product_FILES := $(call module-installed-files, $(product_MODULES))
  ifeq (0,1)
    $(info product_FILES for $(TARGET_DEVICE) ($(INTERNAL_PRODUCT)):)
    $(foreach p,$(product_FILES),$(info :   $(p)))
    $(error done)
=======
  product_host_FILES := $(call host-installed-files,$(INTERNAL_PRODUCT))
  product_target_FILES := $(call product-installed-files, $(INTERNAL_PRODUCT))
  # WARNING: The product_MODULES variable is depended on by external files.
  product_MODULES := $(_pif_modules)

  # Verify the artifact path requirements made by included products.
  is_asan := $(if $(filter address,$(SANITIZE_TARGET)),true)
  ifneq (true,$(or $(is_asan),$(DISABLE_ARTIFACT_PATH_REQUIREMENTS)))
    include $(BUILD_SYSTEM)/artifact_path_requirements.mk
>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])
  endif
else
  # We're not doing a full build, and are probably only including
  # a subset of the module makefiles.  Don't try to build any modules
  # requested by the product, because we probably won't have rules
  # to build them.
  product_FILES :=
endif

eng_MODULES := $(sort \
        $(call get-tagged-modules,eng) \
        $(call module-installed-files, $(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_PACKAGES_ENG)) \
    )
debug_MODULES := $(sort \
        $(call get-tagged-modules,debug) \
        $(call module-installed-files, $(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_PACKAGES_DEBUG)) \
    )
tests_MODULES := $(sort \
        $(call get-tagged-modules,tests) \
        $(call module-installed-files, $(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_PACKAGES_TESTS)) \
    )

# TODO: Remove the 3 places in the tree that use ALL_DEFAULT_INSTALLED_MODULES
# and get rid of it from this list.
modules_to_install := $(sort \
    $(ALL_DEFAULT_INSTALLED_MODULES) \
    $(product_FILES) \
    $(foreach tag,$(tags_to_install),$($(tag)_MODULES)) \
    $(CUSTOM_MODULES) \
  )

# Some packages may override others using LOCAL_OVERRIDES_PACKAGES.
# Filter out (do not install) any overridden packages.
overridden_packages := $(call get-package-overrides,$(modules_to_install))
ifdef overridden_packages
#  old_modules_to_install := $(modules_to_install)
  modules_to_install := \
      $(filter-out $(foreach p,$(overridden_packages),$(p) %/$(p).apk %/$(p).odex %/$(p).vdex), \
          $(modules_to_install))
endif
<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
#$(error filtered out
#           $(filter-out $(modules_to_install),$(old_modules_to_install)))
=======

# Dedpulicate compatibility suite dist files across modules and packages before
# copying them to their requested locations. Assign the eval result to an unused
# var to prevent Make from trying to make a sense of it.
_unused := $(call copy-many-files, $(sort $(ALL_COMPATIBILITY_DIST_FILES)))
>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])

# Don't include any GNU General Public License shared objects or static
# libraries in SDK images.  GPL executables (not static/dynamic libraries)
# are okay if they don't link against any closed source libraries (directly
# or indirectly)

# It's ok (and necessary) to build the host tools, but nothing that's
# going to be installed on the target (including static libraries).

ifdef is_sdk_build
  target_gnu_MODULES := \
              $(filter \
                      $(TARGET_OUT_INTERMEDIATES)/% \
                      $(TARGET_OUT)/% \
                      $(TARGET_OUT_DATA)/%, \
                              $(sort $(call get-tagged-modules,gnu)))
  target_gnu_MODULES := $(filter-out $(TARGET_OUT_EXECUTABLES)/%,$(target_gnu_MODULES))
  target_gnu_MODULES := $(filter-out %/libopenjdkjvmti.so,$(target_gnu_MODULES))
  target_gnu_MODULES := $(filter-out %/libopenjdkjvmtid.so,$(target_gnu_MODULES))
  $(info Removing from sdk:)$(foreach d,$(target_gnu_MODULES),$(info : $(d)))
  modules_to_install := \
              $(filter-out $(target_gnu_MODULES),$(modules_to_install))

  # Ensure every module listed in PRODUCT_PACKAGES* gets something installed
  # TODO: Should we do this for all builds and not just the sdk?
  dangling_modules :=
  $(foreach m, $(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_PACKAGES), \
    $(if $(strip $(ALL_MODULES.$(m).INSTALLED) $(ALL_MODULES.$(m)$(TARGET_2ND_ARCH_MODULE_SUFFIX).INSTALLED)),,\
      $(eval dangling_modules += $(m))))
  ifneq ($(dangling_modules),)
    $(warning: Modules '$(dangling_modules)' in PRODUCT_PACKAGES have nothing to install!)
  endif
  $(foreach m, $(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_PACKAGES_DEBUG), \
    $(if $(strip $(ALL_MODULES.$(m).INSTALLED)),,\
      $(warning $(ALL_MODULES.$(m).MAKEFILE): Module '$(m)' in PRODUCT_PACKAGES_DEBUG has nothing to install!)))
  $(foreach m, $(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_PACKAGES_ENG), \
    $(if $(strip $(ALL_MODULES.$(m).INSTALLED)),,\
      $(warning $(ALL_MODULES.$(m).MAKEFILE): Module '$(m)' in PRODUCT_PACKAGES_ENG has nothing to install!)))
  $(foreach m, $(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_PACKAGES_TESTS), \
    $(if $(strip $(ALL_MODULES.$(m).INSTALLED)),,\
      $(warning $(ALL_MODULES.$(m).MAKEFILE): Module '$(m)' in PRODUCT_PACKAGES_TESTS has nothing to install!)))
endif

# build/make/core/Makefile contains extra stuff that we don't want to pollute this
# top-level makefile with.  It expects that ALL_DEFAULT_INSTALLED_MODULES
# contains everything that's built during the current make, but it also further
# extends ALL_DEFAULT_INSTALLED_MODULES.
ALL_DEFAULT_INSTALLED_MODULES := $(modules_to_install)
include $(BUILD_SYSTEM)/Makefile
modules_to_install := $(sort $(ALL_DEFAULT_INSTALLED_MODULES))
ALL_DEFAULT_INSTALLED_MODULES :=


# Some notice deps refer to module names without prefix or arch suffix where
# only the variants with them get built.
# fix-notice-deps replaces those unadorned module names with every built variant.
$(call fix-notice-deps)

# Create a license metadata rule per module. Could happen in base_rules.mk or
# notice_files.mk; except, it has to happen after fix-notice-deps to avoid
# missing dependency errors.
$(call build-license-metadata)


# These are additional goals that we build, in order to make sure that there
# is as little code as possible in the tree that doesn't build.
modules_to_check := $(foreach m,$(ALL_MODULES),$(ALL_MODULES.$(m).CHECKED))

# If you would like to build all goals, and not skip any intermediate
# steps, you can pass the "all" modifier goal on the commandline.
ifneq ($(filter all,$(MAKECMDGOALS)),)
modules_to_check += $(foreach m,$(ALL_MODULES),$(ALL_MODULES.$(m).BUILT))
endif

# for easier debugging
modules_to_check := $(sort $(modules_to_check))
#$(error modules_to_check $(modules_to_check))

# -------------------------------------------------------------------
# This is used to to get the ordering right, you can also use these,
# but they're considered undocumented, so don't complain if their
# behavior changes.
# An internal target that depends on all copied headers
# (see copy_headers.make).  Other targets that need the
# headers to be copied first can depend on this target.
.PHONY: all_copied_headers
all_copied_headers: ;

$(ALL_C_CPP_ETC_OBJECTS): | all_copied_headers

# All the droid stuff, in directories
.PHONY: files
files: $(modules_to_install) \
       $(INSTALLED_ANDROID_INFO_TXT_TARGET)

# -------------------------------------------------------------------

.PHONY: checkbuild
checkbuild: $(modules_to_check) droid_targets

ifeq (true,$(ANDROID_BUILD_EVERYTHING_BY_DEFAULT))
droid: checkbuild
endif

.PHONY: ramdisk
ramdisk: $(INSTALLED_RAMDISK_TARGET)

.PHONY: systemtarball
systemtarball: $(INSTALLED_SYSTEMTARBALL_TARGET)

.PHONY: boottarball
boottarball: $(INSTALLED_BOOTTARBALL_TARGET)

.PHONY: userdataimage
userdataimage: $(INSTALLED_USERDATAIMAGE_TARGET)

ifneq (,$(filter userdataimage, $(MAKECMDGOALS)))
$(call dist-for-goals, userdataimage, $(BUILT_USERDATAIMAGE_TARGET))
endif

.PHONY: userdatatarball
userdatatarball: $(INSTALLED_USERDATATARBALL_TARGET)

.PHONY: cacheimage
cacheimage: $(INSTALLED_CACHEIMAGE_TARGET)

.PHONY: bptimage
bptimage: $(INSTALLED_BPTIMAGE_TARGET)

.PHONY: vendorimage
vendorimage: $(INSTALLED_VENDORIMAGE_TARGET)

.PHONY: productimage
productimage: $(INSTALLED_PRODUCTIMAGE_TARGET)

<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
=======
.PHONY: systemextimage
systemextimage: $(INSTALLED_SYSTEM_EXTIMAGE_TARGET)

.PHONY: odmimage
odmimage: $(INSTALLED_ODMIMAGE_TARGET)

.PHONY: vendor_dlkmimage
vendor_dlkmimage: $(INSTALLED_VENDOR_DLKMIMAGE_TARGET)

.PHONY: odm_dlkmimage
odm_dlkmimage: $(INSTALLED_ODM_DLKMIMAGE_TARGET)

>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])
.PHONY: systemotherimage
systemotherimage: $(INSTALLED_SYSTEMOTHERIMAGE_TARGET)

.PHONY: bootimage
bootimage: $(INSTALLED_BOOTIMAGE_TARGET)

.PHONY: vbmetaimage
vbmetaimage: $(INSTALLED_VBMETAIMAGE_TARGET)

.PHONY: vbmetasystemimage
vbmetasystemimage: $(INSTALLED_VBMETA_SYSTEMIMAGE_TARGET)

.PHONY: vbmetavendorimage
vbmetavendorimage: $(INSTALLED_VBMETA_VENDORIMAGE_TARGET)

# Build files and then package it into the rom formats
.PHONY: droidcore
<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
droidcore: files \
	systemimage \
	$(INSTALLED_BOOTIMAGE_TARGET) \
	$(INSTALLED_RECOVERYIMAGE_TARGET) \
	$(INSTALLED_VBMETAIMAGE_TARGET) \
	$(INSTALLED_USERDATAIMAGE_TARGET) \
	$(INSTALLED_CACHEIMAGE_TARGET) \
	$(INSTALLED_BPTIMAGE_TARGET) \
	$(INSTALLED_VENDORIMAGE_TARGET) \
	$(INSTALLED_PRODUCTIMAGE_TARGET) \
	$(INSTALLED_SYSTEMOTHERIMAGE_TARGET) \
	$(INSTALLED_FILES_FILE) \
	$(INSTALLED_FILES_FILE_VENDOR) \
	$(INSTALLED_FILES_FILE_PRODUCT) \
	$(INSTALLED_FILES_FILE_SYSTEMOTHER) \
	soong_docs
=======
droidcore: $(filter $(HOST_OUT_ROOT)/%,$(modules_to_install)) \
    $(INSTALLED_SYSTEMIMAGE_TARGET) \
    $(INSTALLED_RAMDISK_TARGET) \
    $(INSTALLED_BOOTIMAGE_TARGET) \
    $(INSTALLED_RADIOIMAGE_TARGET) \
    $(INSTALLED_DEBUG_RAMDISK_TARGET) \
    $(INSTALLED_DEBUG_BOOTIMAGE_TARGET) \
    $(INSTALLED_RECOVERYIMAGE_TARGET) \
    $(INSTALLED_VBMETAIMAGE_TARGET) \
    $(INSTALLED_VBMETA_SYSTEMIMAGE_TARGET) \
    $(INSTALLED_VBMETA_VENDORIMAGE_TARGET) \
    $(INSTALLED_USERDATAIMAGE_TARGET) \
    $(INSTALLED_CACHEIMAGE_TARGET) \
    $(INSTALLED_BPTIMAGE_TARGET) \
    $(INSTALLED_VENDORIMAGE_TARGET) \
    $(INSTALLED_VENDOR_BOOTIMAGE_TARGET) \
    $(INSTALLED_VENDOR_DEBUG_RAMDISK_TARGET) \
    $(INSTALLED_VENDOR_DEBUG_BOOTIMAGE_TARGET) \
    $(INSTALLED_ODMIMAGE_TARGET) \
    $(INSTALLED_VENDOR_DLKMIMAGE_TARGET) \
    $(INSTALLED_ODM_DLKMIMAGE_TARGET) \
    $(INSTALLED_SUPERIMAGE_EMPTY_TARGET) \
    $(INSTALLED_PRODUCTIMAGE_TARGET) \
    $(INSTALLED_SYSTEMOTHERIMAGE_TARGET) \
    $(INSTALLED_FILES_FILE) \
    $(INSTALLED_FILES_JSON) \
    $(INSTALLED_FILES_FILE_VENDOR) \
    $(INSTALLED_FILES_JSON_VENDOR) \
    $(INSTALLED_FILES_FILE_ODM) \
    $(INSTALLED_FILES_JSON_ODM) \
    $(INSTALLED_FILES_FILE_VENDOR_DLKM) \
    $(INSTALLED_FILES_JSON_VENDOR_DLKM) \
    $(INSTALLED_FILES_FILE_ODM_DLKM) \
    $(INSTALLED_FILES_JSON_ODM_DLKM) \
    $(INSTALLED_FILES_FILE_PRODUCT) \
    $(INSTALLED_FILES_JSON_PRODUCT) \
    $(INSTALLED_FILES_FILE_SYSTEM_EXT) \
    $(INSTALLED_FILES_JSON_SYSTEM_EXT) \
    $(INSTALLED_FILES_FILE_SYSTEMOTHER) \
    $(INSTALLED_FILES_JSON_SYSTEMOTHER) \
    $(INSTALLED_FILES_FILE_RAMDISK) \
    $(INSTALLED_FILES_JSON_RAMDISK) \
    $(INSTALLED_FILES_FILE_DEBUG_RAMDISK) \
    $(INSTALLED_FILES_JSON_DEBUG_RAMDISK) \
    $(INSTALLED_FILES_FILE_VENDOR_RAMDISK) \
    $(INSTALLED_FILES_JSON_VENDOR_RAMDISK) \
    $(INSTALLED_FILES_FILE_VENDOR_DEBUG_RAMDISK) \
    $(INSTALLED_FILES_JSON_VENDOR_DEBUG_RAMDISK) \
    $(INSTALLED_FILES_FILE_ROOT) \
    $(INSTALLED_FILES_JSON_ROOT) \
    $(INSTALLED_FILES_FILE_RECOVERY) \
    $(INSTALLED_FILES_JSON_RECOVERY) \
    $(INSTALLED_ANDROID_INFO_TXT_TARGET) \
    soong_docs
>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])

# dist_files only for putting your library into the dist directory with a full build.
.PHONY: dist_files

<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
=======
ifeq ($(SOONG_COLLECT_JAVA_DEPS), true)
  $(call dist-for-goals, dist_files, $(SOONG_OUT_DIR)/module_bp_java_deps.json)
  $(call dist-for-goals, dist_files, $(PRODUCT_OUT)/module-info.json)
endif

.PHONY: apps_only
>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])
ifneq ($(TARGET_BUILD_APPS),)
  # If this build is just for apps, only build apps and not the full system by default.

  unbundled_build_modules :=
  ifneq ($(filter all,$(TARGET_BUILD_APPS)),)
    # If they used the magic goal "all" then build all apps in the source tree.
    unbundled_build_modules := $(foreach m,$(sort $(ALL_MODULES)),$(if $(filter APPS,$(ALL_MODULES.$(m).CLASS)),$(m)))
  else
    unbundled_build_modules := $(TARGET_BUILD_APPS)
  endif

  # Dist the installed files if they exist.
  apps_only_installed_files := $(foreach m,$(unbundled_build_modules),$(ALL_MODULES.$(m).INSTALLED))
  $(call dist-for-goals,apps_only, $(apps_only_installed_files))
  # For uninstallable modules such as static Java library, we have to dist the built file,
  # as <module_name>.<suffix>
  apps_only_dist_built_files := $(foreach m,$(unbundled_build_modules),$(if $(ALL_MODULES.$(m).INSTALLED),,\
      $(if $(ALL_MODULES.$(m).BUILT),$(ALL_MODULES.$(m).BUILT):$(m)$(suffix $(ALL_MODULES.$(m).BUILT)))\
      $(if $(ALL_MODULES.$(m).AAR),$(ALL_MODULES.$(m).AAR):$(m).aar)\
      ))
  $(call dist-for-goals,apps_only, $(apps_only_dist_built_files))

  ifeq ($(EMMA_INSTRUMENT),true)
    $(JACOCO_REPORT_CLASSES_ALL) : $(apps_only_installed_files)
    $(call dist-for-goals,apps_only, $(JACOCO_REPORT_CLASSES_ALL))
  endif

  $(PROGUARD_DICT_ZIP) : $(apps_only_installed_files)
  $(call dist-for-goals,apps_only, $(PROGUARD_DICT_ZIP))

  $(PROGUARD_USAGE_ZIP) : $(apps_only_installed_files)
  $(call dist-for-goals,apps_only, $(PROGUARD_USAGE_ZIP))

  $(SYMBOLS_ZIP) : $(apps_only_installed_files)
  $(call dist-for-goals,apps_only, $(SYMBOLS_ZIP))

  $(COVERAGE_ZIP) : $(apps_only_installed_files)
  $(call dist-for-goals,apps_only, $(COVERAGE_ZIP))

.PHONY: apps_only
apps_only: $(unbundled_build_modules)

droid_targets: apps_only

# Combine the NOTICE files for a apps_only build
$(eval $(call combine-notice-files, html, \
    $(target_notice_file_txt), \
    $(target_notice_file_html_or_xml), \
    "Notices for files for apps:", \
    $(TARGET_OUT_NOTICE_FILES), \
    $(apps_only_installed_files)))


else ifeq (,$(TARGET_BUILD_UNBUNDLED))
  $(call dist-for-goals, droidcore, \
    $(INTERNAL_UPDATE_PACKAGE_TARGET) \
    $(INTERNAL_OTA_PACKAGE_TARGET) \
<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
=======
    $(INTERNAL_OTA_METADATA) \
    $(INTERNAL_OTA_PARTIAL_PACKAGE_TARGET) \
    $(INTERNAL_OTA_RETROFIT_DYNAMIC_PARTITIONS_PACKAGE_TARGET) \
>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])
    $(BUILT_OTATOOLS_PACKAGE) \
    $(SYMBOLS_ZIP) \
<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
=======
    $(PROGUARD_DICT_ZIP) \
    $(PROGUARD_USAGE_ZIP) \
>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])
    $(COVERAGE_ZIP) \
    $(INSTALLED_FILES_FILE) \
    $(INSTALLED_FILES_FILE_VENDOR) \
<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
=======
    $(INSTALLED_FILES_JSON_VENDOR) \
    $(INSTALLED_FILES_FILE_ODM) \
    $(INSTALLED_FILES_JSON_ODM) \
    $(INSTALLED_FILES_FILE_VENDOR_DLKM) \
    $(INSTALLED_FILES_JSON_VENDOR_DLKM) \
    $(INSTALLED_FILES_FILE_ODM_DLKM) \
    $(INSTALLED_FILES_JSON_ODM_DLKM) \
>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])
    $(INSTALLED_FILES_FILE_PRODUCT) \
    $(INSTALLED_FILES_FILE_SYSTEMOTHER) \
<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
    $(INSTALLED_BUILD_PROP_TARGET) \
=======
    $(INSTALLED_FILES_JSON_SYSTEMOTHER) \
    $(INSTALLED_FILES_FILE_RECOVERY) \
    $(INSTALLED_FILES_JSON_RECOVERY) \
    $(INSTALLED_BUILD_PROP_TARGET):build.prop \
    $(INSTALLED_VENDOR_BUILD_PROP_TARGET):build.prop-vendor \
    $(INSTALLED_PRODUCT_BUILD_PROP_TARGET):build.prop-product \
    $(INSTALLED_ODM_BUILD_PROP_TARGET):build.prop-odm \
    $(INSTALLED_SYSTEM_EXT_BUILD_PROP_TARGET):build.prop-system_ext \
    $(INSTALLED_RAMDISK_BUILD_PROP_TARGET):build.prop-ramdisk \
>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])
    $(BUILT_TARGET_FILES_PACKAGE) \
    $(INSTALLED_ANDROID_INFO_TXT_TARGET) \
    $(INSTALLED_RAMDISK_TARGET) \
   )

  # Put a copy of the radio/bootloader files in the dist dir.
  $(foreach f,$(INSTALLED_RADIOIMAGE_TARGET), \
    $(call dist-for-goals, droidcore, $(f)))

  ifneq ($(ANDROID_BUILD_EMBEDDED),true)
    $(call dist-for-goals, droidcore, \
      $(APPS_ZIP) \
      $(INTERNAL_EMULATOR_PACKAGE_TARGET) \
      $(PACKAGE_STATS_FILE) \
    )
  endif

<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
=======
  $(call dist-for-goals, droidcore, \
    $(INSTALLED_FILES_FILE_ROOT) \
    $(INSTALLED_FILES_JSON_ROOT) \
  )

  ifneq ($(BOARD_BUILD_SYSTEM_ROOT_IMAGE),true)
    $(call dist-for-goals, droidcore, \
      $(INSTALLED_FILES_FILE_RAMDISK) \
      $(INSTALLED_FILES_JSON_RAMDISK) \
      $(INSTALLED_FILES_FILE_DEBUG_RAMDISK) \
      $(INSTALLED_FILES_JSON_DEBUG_RAMDISK) \
      $(INSTALLED_FILES_FILE_VENDOR_RAMDISK) \
      $(INSTALLED_FILES_JSON_VENDOR_RAMDISK) \
      $(INSTALLED_FILES_FILE_VENDOR_DEBUG_RAMDISK) \
      $(INSTALLED_FILES_JSON_VENDOR_DEBUG_RAMDISK) \
      $(INSTALLED_DEBUG_RAMDISK_TARGET) \
      $(INSTALLED_DEBUG_BOOTIMAGE_TARGET) \
      $(INSTALLED_VENDOR_DEBUG_RAMDISK_TARGET) \
      $(INSTALLED_VENDOR_DEBUG_BOOTIMAGE_TARGET) \
    )
    $(call dist-for-goals, bootimage_test_harness, \
      $(INSTALLED_TEST_HARNESS_RAMDISK_TARGET) \
      $(INSTALLED_TEST_HARNESS_BOOTIMAGE_TARGET) \
    )
  endif

  ifeq ($(BOARD_USES_RECOVERY_AS_BOOT),true)
    $(call dist-for-goals, droidcore, \
      $(recovery_ramdisk) \
    )
  endif

>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])
  ifeq ($(EMMA_INSTRUMENT),true)
    $(JACOCO_REPORT_CLASSES_ALL) : $(INSTALLED_SYSTEMIMAGE)
    $(call dist-for-goals, dist_files, $(JACOCO_REPORT_CLASSES_ALL))
  endif

<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
=======
  # Put XML formatted API files in the dist dir.
  $(TARGET_OUT_COMMON_INTERMEDIATES)/api.xml: $(call java-lib-files,android_stubs_current) $(APICHECK)
  $(TARGET_OUT_COMMON_INTERMEDIATES)/system-api.xml: $(call java-lib-files,android_system_stubs_current) $(APICHECK)
  $(TARGET_OUT_COMMON_INTERMEDIATES)/module-lib-api.xml: $(call java-lib-files,android_module_lib_stubs_current) $(APICHECK)
  $(TARGET_OUT_COMMON_INTERMEDIATES)/system-server-api.xml: $(call java-lib-files,android_system_server_stubs_current) $(APICHECK)
  $(TARGET_OUT_COMMON_INTERMEDIATES)/test-api.xml: $(call java-lib-files,android_test_stubs_current) $(APICHECK)

  api_xmls := $(addprefix $(TARGET_OUT_COMMON_INTERMEDIATES)/,api.xml system-api.xml module-lib-api.xml system-server-api.xml test-api.xml)
  $(api_xmls):
	$(hide) echo "Converting API file to XML: $@"
	$(hide) mkdir -p $(dir $@)
	$(hide) $(APICHECK_COMMAND) --input-api-jar $< --api-xml $@

  $(call dist-for-goals, dist_files, $(api_xmls))
  api_xmls :=

  ifdef CLANG_COVERAGE
    $(foreach f,$(SOONG_NDK_API_XML), \
        $(call dist-for-goals,droidcore,$(f):ndk_apis/$(notdir $(f))))
  endif

>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])
# Building a full system-- the default is to build droidcore
droid_targets: droidcore dist_files

endif # !TARGET_BUILD_UNBUNDLED

.PHONY: docs
docs: $(ALL_DOCS)

.PHONY: sdk
ALL_SDK_TARGETS := $(INTERNAL_SDK_TARGET)
sdk: $(ALL_SDK_TARGETS)
$(call dist-for-goals,sdk win_sdk, \
    $(ALL_SDK_TARGETS) \
    $(SYMBOLS_ZIP) \
    $(COVERAGE_ZIP) \
    $(INSTALLED_BUILD_PROP_TARGET) \
)

# umbrella targets to assit engineers in verifying builds
.PHONY: java native target host java-host java-target native-host native-target \
        java-host-tests java-target-tests native-host-tests native-target-tests \
        java-tests native-tests host-tests target-tests tests java-dex
# some synonyms
.PHONY: host-java target-java host-native target-native \
        target-java-tests target-native-tests
host-java : java-host
target-java : java-target
host-native : native-host
target-native : native-target
target-java-tests : java-target-tests
target-native-tests : native-target-tests
tests : host-tests target-tests

# Phony target to run all java compilations that use javac
.PHONY: javac-check

ifneq (,$(filter samplecode, $(MAKECMDGOALS)))
.PHONY: samplecode
sample_MODULES := $(sort $(call get-tagged-modules,samples))
sample_APKS_DEST_PATH := $(TARGET_COMMON_OUT_ROOT)/samples
sample_APKS_COLLECTION := \
        $(foreach module,$(sample_MODULES),$(sample_APKS_DEST_PATH)/$(notdir $(module)))
$(foreach module,$(sample_MODULES),$(eval $(call \
        copy-one-file,$(module),$(sample_APKS_DEST_PATH)/$(notdir $(module)))))
sample_ADDITIONAL_INSTALLED := \
        $(filter-out $(modules_to_install) $(modules_to_check),$(sample_MODULES))
samplecode: $(sample_APKS_COLLECTION)
	@echo "Collect sample code apks: $^"
	# remove apks that are not intended to be installed.
	rm -f $(sample_ADDITIONAL_INSTALLED)
endif  # samplecode in $(MAKECMDGOALS)

.PHONY: findbugs
findbugs: $(INTERNAL_FINDBUGS_HTML_TARGET) $(INTERNAL_FINDBUGS_XML_TARGET)

.PHONY: findlsdumps
findlsdumps: $(FIND_LSDUMPS_FILE)

#xxx scrape this from ALL_MODULE_NAME_TAGS
.PHONY: modules
modules:
	@echo "Available sub-modules:"
	@echo "$(call module-names-for-tag-list,$(ALL_MODULE_TAGS))" | \
<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
	      tr -s ' ' '\n' | sort -u | $(COLUMN)
=======
	      tr -s ' ' '\n' | sort -u

.PHONY: dump-files
dump-files:
	@echo "Target files for $(TARGET_PRODUCT)-$(TARGET_BUILD_VARIANT) ($(INTERNAL_PRODUCT)):"
	@echo $(sort $(patsubst $(PRODUCT_OUT)/%,%,$(filter $(PRODUCT_OUT)/%,$(modules_to_install)))) | tr -s ' ' '\n'
	@echo Successfully dumped product target file list.
>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])

.PHONY: nothing
nothing:
	@echo Successfully read the makefiles.

.PHONY: tidy_only
tidy_only:
	@echo Successfully make tidy_only.

ndk: $(SOONG_OUT_DIR)/ndk.timestamp
.PHONY: ndk

<<<<<<< HEAD   (4be654 Merge "Merge empty history for sparse-7121469-L4290000080720)
endif # KATI
=======
# Checks that build/soong/apex/allowed_deps.txt remains up to date
ifneq ($(UNSAFE_DISABLE_APEX_ALLOWED_DEPS_CHECK),true)
  droidcore: ${APEX_ALLOWED_DEPS_CHECK}
endif

$(call dist-write-file,$(KATI_PACKAGE_MK_DIR)/dist.mk)

$(info [$(call inc_and_print,subdir_makefiles_inc)/$(subdir_makefiles_total)] writing build rules ...)
>>>>>>> BRANCH (fe6ad7 Merge "Version bump to RBT1.210107.001.A1 [core/build_id.mk])
