SOONG := $(SOONG_OUT_DIR)/soong
SOONG_BOOTSTRAP := $(SOONG_OUT_DIR)/.soong.bootstrap
SOONG_BUILD_NINJA := $(SOONG_OUT_DIR)/build.ninja
SOONG_IN_MAKE := $(SOONG_OUT_DIR)/.soong.in_make
SOONG_MAKEVARS_MK := $(SOONG_OUT_DIR)/make_vars-$(TARGET_PRODUCT).mk
SOONG_VARIABLES := $(SOONG_OUT_DIR)/soong.variables
SOONG_ANDROID_MK := $(SOONG_OUT_DIR)/Android-$(TARGET_PRODUCT).mk

BINDER32BIT :=
ifneq ($(TARGET_USES_64_BIT_BINDER),true)
ifneq ($(TARGET_IS_64_BIT),true)
BINDER32BIT := true
endif
endif

include $(BUILD_SYSTEM)/dex_preopt_config.mk

ifeq ($(WRITE_SOONG_VARIABLES),true)

# Create soong.variables with copies of makefile settings.  Runs every build,
# but only updates soong.variables if it changes
$(shell mkdir -p $(dir $(SOONG_VARIABLES)))
$(call json_start)

$(call add_json_str,  Make_suffix, -$(TARGET_PRODUCT))

$(call add_json_str,  BuildId,                           $(BUILD_ID))
$(call add_json_str,  BuildNumberFromFile,               $$$(BUILD_NUMBER_FROM_FILE))

$(call add_json_str,  Platform_version_name,             $(PLATFORM_VERSION))
$(call add_json_val,  Platform_sdk_version,              $(PLATFORM_SDK_VERSION))
$(call add_json_str,  Platform_sdk_codename,             $(PLATFORM_VERSION_CODENAME))
$(call add_json_bool, Platform_sdk_final,                $(filter REL,$(PLATFORM_VERSION_CODENAME)))
$(call add_json_csv,  Platform_version_active_codenames, $(PLATFORM_VERSION_ALL_CODENAMES))
$(call add_json_csv,  Platform_version_future_codenames, $(PLATFORM_VERSION_FUTURE_CODENAMES))

$(call add_json_bool, Allow_missing_dependencies,        $(ALLOW_MISSING_DEPENDENCIES))
$(call add_json_bool, Unbundled_build,                   $(TARGET_BUILD_APPS))
$(call add_json_bool, Unbundled_build_sdks_from_source,  $(UNBUNDLED_BUILD_SDKS_FROM_SOURCE))
$(call add_json_bool, Pdk,                               $(filter true,$(TARGET_BUILD_PDK)))

$(call add_json_bool, Debuggable,                        $(filter userdebug eng,$(TARGET_BUILD_VARIANT)))
$(call add_json_bool, Eng,                               $(filter eng,$(TARGET_BUILD_VARIANT)))

$(call add_json_str,  DeviceName,                        $(TARGET_DEVICE))
$(call add_json_str,  DeviceArch,                        $(TARGET_ARCH))
$(call add_json_str,  DeviceArchVariant,                 $(TARGET_ARCH_VARIANT))
$(call add_json_str,  DeviceCpuVariant,                  $(TARGET_CPU_VARIANT))
$(call add_json_list, DeviceAbi,                         $(TARGET_CPU_ABI) $(TARGET_CPU_ABI2))

$(call add_json_str,  DeviceSecondaryArch,               $(TARGET_2ND_ARCH))
$(call add_json_str,  DeviceSecondaryArchVariant,        $(TARGET_2ND_ARCH_VARIANT))
$(call add_json_str,  DeviceSecondaryCpuVariant,         $(TARGET_2ND_CPU_VARIANT))
$(call add_json_list, DeviceSecondaryAbi,                $(TARGET_2ND_CPU_ABI) $(TARGET_2ND_CPU_ABI2))

$(call add_json_str,  HostArch,                          $(HOST_ARCH))
$(call add_json_str,  HostSecondaryArch,                 $(HOST_2ND_ARCH))
$(call add_json_bool, HostStaticBinaries,                $(BUILD_HOST_static))

$(call add_json_str,  CrossHost,                         $(HOST_CROSS_OS))
$(call add_json_str,  CrossHostArch,                     $(HOST_CROSS_ARCH))
$(call add_json_str,  CrossHostSecondaryArch,            $(HOST_CROSS_2ND_ARCH))

$(call add_json_list, ResourceOverlays,                  $(PRODUCT_PACKAGE_OVERLAYS) $(DEVICE_PACKAGE_OVERLAYS))
$(call add_json_list, EnforceRROTargets,                 $(PRODUCT_ENFORCE_RRO_TARGETS))
$(call add_json_list, EnforceRROExcludedOverlays,        $(PRODUCT_ENFORCE_RRO_EXCLUDED_OVERLAYS))

$(call add_json_str,  AAPTCharacteristics,               $(TARGET_AAPT_CHARACTERISTICS))
$(call add_json_list, AAPTConfig,                        $(PRODUCT_AAPT_CONFIG))
$(call add_json_str,  AAPTPreferredConfig,               $(PRODUCT_AAPT_PREF_CONFIG))
$(call add_json_list, AAPTPrebuiltDPI,                   $(PRODUCT_AAPT_PREBUILT_DPI))

$(call add_json_str,  DefaultAppCertificate,             $(PRODUCT_DEFAULT_DEV_CERTIFICATE))

$(call add_json_str,  AppsDefaultVersionName,            $(APPS_DEFAULT_VERSION_NAME))

$(call add_json_list, SanitizeHost,                      $(SANITIZE_HOST))
$(call add_json_list, SanitizeDevice,                    $(SANITIZE_TARGET))
$(call add_json_list, SanitizeDeviceDiag,                $(SANITIZE_TARGET_DIAG))
$(call add_json_list, SanitizeDeviceArch,                $(SANITIZE_TARGET_ARCH))

$(call add_json_bool, Safestack,                         $(filter true,$(USE_SAFESTACK)))
$(call add_json_bool, EnableCFI,                         $(call invert_bool,$(filter false,$(ENABLE_CFI))))
$(call add_json_list, CFIExcludePaths,                   $(CFI_EXCLUDE_PATHS) $(PRODUCT_CFI_EXCLUDE_PATHS))
$(call add_json_list, CFIIncludePaths,                   $(CFI_INCLUDE_PATHS) $(PRODUCT_CFI_INCLUDE_PATHS))
$(call add_json_bool, EnableXOM,                         $(filter true,$(ENABLE_XOM)))
$(call add_json_list, XOMExcludePaths,                   $(XOM_EXCLUDE_PATHS) $(PRODUCT_XOM_EXCLUDE_PATHS))
$(call add_json_list, IntegerOverflowExcludePaths,       $(INTEGER_OVERFLOW_EXCLUDE_PATHS) $(PRODUCT_INTEGER_OVERFLOW_EXCLUDE_PATHS))

$(call add_json_bool, ClangTidy,                         $(filter 1 true,$(WITH_TIDY)))
$(call add_json_str,  TidyChecks,                        $(WITH_TIDY_CHECKS))

$(call add_json_bool, NativeCoverage,                    $(filter true,$(NATIVE_COVERAGE)))
$(call add_json_list, CoveragePaths,                     $(COVERAGE_PATHS))
$(call add_json_list, CoverageExcludePaths,              $(COVERAGE_EXCLUDE_PATHS))

$(call add_json_bool, ArtUseReadBarrier,                 $(call invert_bool,$(filter false,$(PRODUCT_ART_USE_READ_BARRIER))))
$(call add_json_bool, Binder32bit,                       $(BINDER32BIT))
$(call add_json_str,  BtConfigIncludeDir,                $(BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR))
$(call add_json_list, DeviceKernelHeaders,               $(TARGET_PROJECT_SYSTEM_INCLUDES))
$(call add_json_bool, DevicePrefer32BitApps,             $(filter true,$(TARGET_PREFER_32_BIT_APPS)))
$(call add_json_bool, DevicePrefer32BitExecutables,      $(filter true,$(TARGET_PREFER_32_BIT_EXECUTABLES)))
$(call add_json_str,  DeviceVndkVersion,                 $(BOARD_VNDK_VERSION))
$(call add_json_bool, MediaDrm32bit,                     $(call invert_bool,$(filter false,$(TARGET_ENABLE_MEDIADRM_64))))
$(call add_json_str,  Platform_vndk_version,             $(PLATFORM_VNDK_VERSION))
$(call add_json_list, ExtraVndkVersions,                 $(PRODUCT_EXTRA_VNDK_VERSIONS))
$(call add_json_list, DeviceSystemSdkVersions,           $(BOARD_SYSTEMSDK_VERSIONS))
$(call add_json_list, Platform_systemsdk_versions,       $(PLATFORM_SYSTEMSDK_VERSIONS))
$(call add_json_bool, Malloc_not_svelte,                 $(call invert_bool,$(filter true,$(MALLOC_SVELTE))))
$(call add_json_str,  Override_rs_driver,                $(OVERRIDE_RS_DRIVER))

$(call add_json_bool, UncompressPrivAppDex,              $(call invert_bool,$(filter true,$(DONT_UNCOMPRESS_PRIV_APPS_DEXS))))
$(call add_json_list, ModulesLoadedByPrivilegedModules,  $(PRODUCT_LOADED_BY_PRIVILEGED_MODULES))

$(call add_json_bool, DisableDexPreopt,                  $(call invert_bool,$(filter true,$(WITH_DEXPREOPT))))
$(call add_json_list, DisableDexPreoptModules,           $(DEXPREOPT_DISABLED_MODULES))
$(call add_json_str,  DexPreoptProfileDir,               $(PRODUCT_DEX_PREOPT_PROFILE_DIR))

$(call add_json_bool, Product_is_iot,                    $(filter true,$(PRODUCT_IOT)))

$(call add_json_bool, Treble_linker_namespaces,          $(filter true,$(PRODUCT_TREBLE_LINKER_NAMESPACES)))
$(call add_json_bool, Enforce_vintf_manifest,            $(filter true,$(PRODUCT_ENFORCE_VINTF_MANIFEST)))

$(call add_json_bool, Uml,                               $(filter true,$(TARGET_USER_MODE_LINUX)))
$(call add_json_bool, Use_lmkd_stats_log,                $(filter true,$(TARGET_LMKD_STATS_LOG)))
$(call add_json_str,  VendorPath,                        $(TARGET_COPY_OUT_VENDOR))
$(call add_json_str,  OdmPath,                           $(TARGET_COPY_OUT_ODM))
$(call add_json_str,  ProductPath,                       $(TARGET_COPY_OUT_PRODUCT))
$(call add_json_str,  ProductServicesPath,               $(TARGET_COPY_OUT_PRODUCT_SERVICES))
$(call add_json_bool, MinimizeJavaDebugInfo,             $(filter true,$(PRODUCT_MINIMIZE_JAVA_DEBUG_INFO)))

$(call add_json_bool, UseGoma,                           $(filter-out false,$(USE_GOMA)))
$(call add_json_bool, Arc,                               $(filter true,$(TARGET_ARC)))

$(call add_json_list, NamespacesToExport,                $(PRODUCT_SOONG_NAMESPACES))

$(call add_json_list, PgoAdditionalProfileDirs,          $(PGO_ADDITIONAL_PROFILE_DIRS))

$(call add_json_list, BoardVendorSepolicyDirs,           $(BOARD_SEPOLICY_DIRS))
$(call add_json_list, BoardOdmSepolicyDirs,              $(BOARD_ODM_SEPOLICY_DIRS))
$(call add_json_list, BoardPlatPublicSepolicyDirs,       $(BOARD_PLAT_PUBLIC_SEPOLICY_DIR))
$(call add_json_list, BoardPlatPrivateSepolicyDirs,      $(BOARD_PLAT_PRIVATE_SEPOLICY_DIR))

$(call add_json_bool, FlattenApex,                       $(filter true,$(TARGET_FLATTEN_APEX)))

$(call add_json_str,  DexpreoptGlobalConfig,             $(DEX_PREOPT_CONFIG))

$(call add_json_map, VendorVars)
$(foreach namespace,$(SOONG_CONFIG_NAMESPACES),\
  $(call add_json_map, $(namespace))\
  $(foreach key,$(SOONG_CONFIG_$(namespace)),\
    $(call add_json_str,$(key),$(SOONG_CONFIG_$(namespace)_$(key))))\
  $(call end_json_map))
$(call end_json_map)

$(call json_end)

$(file >$(SOONG_VARIABLES).tmp,$(json_contents))

$(shell if ! cmp -s $(SOONG_VARIABLES).tmp $(SOONG_VARIABLES); then \
	  mv $(SOONG_VARIABLES).tmp $(SOONG_VARIABLES); \
	else \
	  rm $(SOONG_VARIABLES).tmp; \
	fi)

endif # CONFIGURE_SOONG
