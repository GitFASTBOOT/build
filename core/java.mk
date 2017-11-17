# Target Java.
# Requires:
# LOCAL_MODULE_SUFFIX
# LOCAL_MODULE_CLASS
# all_res_assets

ifeq ($(TARGET_BUILD_PDK),true)
ifeq ($(TARGET_BUILD_PDK_JAVA_PLATFORM),)
# LOCAL_SDK not defined or set to current
ifeq ($(filter-out current,$(LOCAL_SDK_VERSION)),)
ifneq ($(LOCAL_NO_STANDARD_LIBRARIES),true)
LOCAL_SDK_VERSION := $(PDK_BUILD_SDK_VERSION)
endif #!LOCAL_NO_STANDARD_LIBRARIES
endif
endif # !PDK_JAVA
endif #PDK

LOCAL_NO_STANDARD_LIBRARIES:=$(strip $(LOCAL_NO_STANDARD_LIBRARIES))
LOCAL_SDK_VERSION:=$(strip $(LOCAL_SDK_VERSION))

proto_sources := $(filter %.proto,$(LOCAL_SRC_FILES))
ifneq ($(proto_sources),)
ifeq ($(LOCAL_PROTOC_OPTIMIZE_TYPE),micro)
    LOCAL_STATIC_JAVA_LIBRARIES += libprotobuf-java-micro
else
  ifeq ($(LOCAL_PROTOC_OPTIMIZE_TYPE),nano)
    LOCAL_STATIC_JAVA_LIBRARIES += libprotobuf-java-nano
  else
    ifeq ($(LOCAL_PROTOC_OPTIMIZE_TYPE),stream)
      # No library for stream protobufs
    else
      LOCAL_STATIC_JAVA_LIBRARIES += libprotobuf-java-lite
    endif
  endif
endif
endif

# LOCAL_STATIC_JAVA_AAR_LIBRARIES and LOCAL_STATIC_ANDROID_LIBRARIES are also LOCAL_STATIC_JAVA_LIBRARIES.
LOCAL_STATIC_JAVA_LIBRARIES := $(strip $(LOCAL_STATIC_JAVA_LIBRARIES) \
    $(LOCAL_STATIC_JAVA_AAR_LIBRARIES) \
    $(LOCAL_STATIC_ANDROID_LIBRARIES))
# LOCAL_SHARED_ANDROID_LIBRARIES are also LOCAL_JAVA_LIBRARIES.
LOCAL_JAVA_LIBRARIES := $(sort $(LOCAL_JAVA_LIBRARIES) $(LOCAL_SHARED_ANDROID_LIBRARIES))

LOCAL_BUILT_MODULE_STEM := $(strip $(LOCAL_BUILT_MODULE_STEM))
ifeq ($(LOCAL_BUILT_MODULE_STEM),)
$(error $(LOCAL_PATH): Target java template must define LOCAL_BUILT_MODULE_STEM)
endif
ifneq ($(filter classes-compiled.jar classes.jar,$(LOCAL_BUILT_MODULE_STEM)),)
$(error LOCAL_BUILT_MODULE_STEM may not be "$(LOCAL_BUILT_MODULE_STEM)")
endif


##############################################################################
# Define the intermediate targets before including base_rules so they get
# the correct environment.
##############################################################################

intermediates := $(call local-intermediates-dir)
intermediates.COMMON := $(call local-intermediates-dir,COMMON)

# Choose leaf name for the compiled jar file.
ifeq ($(LOCAL_EMMA_INSTRUMENT),true)
full_classes_compiled_jar_leaf := classes-no-debug-var.jar
built_dex_intermediate_leaf := no-local
else
full_classes_compiled_jar_leaf := classes-full-debug.jar
built_dex_intermediate_leaf := with-local
endif

ifeq ($(LOCAL_PROGUARD_ENABLED),disabled)
LOCAL_PROGUARD_ENABLED :=
endif

full_classes_turbine_jar := $(intermediates.COMMON)/classes-turbine.jar
full_classes_header_jarjar := $(intermediates.COMMON)/classes-header-jarjar.jar
full_classes_header_jar := $(intermediates.COMMON)/classes-header.jar
full_classes_compiled_jar := $(intermediates.COMMON)/$(full_classes_compiled_jar_leaf)
full_classes_processed_jar := $(intermediates.COMMON)/classes-processed.jar
full_classes_desugar_jar := $(intermediates.COMMON)/classes-desugar.jar
jarjar_leaf := classes-jarjar.jar
full_classes_jarjar_jar := $(intermediates.COMMON)/$(jarjar_leaf)
full_classes_proguard_jar := $(intermediates.COMMON)/classes-proguard.jar
full_classes_combined_jar := $(intermediates.COMMON)/classes-combined.jar
built_dex_intermediate := $(intermediates.COMMON)/$(built_dex_intermediate_leaf)/classes.dex
full_classes_stubs_jar := $(intermediates.COMMON)/stubs.jar
java_source_list_file := $(intermediates.COMMON)/java-source-list


ifeq ($(LOCAL_MODULE_CLASS)$(LOCAL_SRC_FILES)$(LOCAL_STATIC_JAVA_LIBRARIES)$(LOCAL_SOURCE_FILES_ALL_GENERATED),APPS)
# If this is an apk without any Java code (e.g. framework-res), we should skip compiling Java.
full_classes_jar :=
built_dex :=
else
full_classes_jar := $(intermediates.COMMON)/classes.jar
built_dex := $(intermediates.COMMON)/classes.dex
endif

LOCAL_INTERMEDIATE_TARGETS += \
    $(full_classes_turbine_jar) \
    $(full_classes_compiled_jar) \
    $(full_classes_desugar_jar) \
    $(full_classes_jarjar_jar) \
    $(full_classes_jar) \
    $(full_classes_combined_jar) \
    $(full_classes_proguard_jar) \
    $(built_dex_intermediate) \
    $(built_dex) \
    $(full_classes_stubs_jar) \
    $(java_source_list_file)

LOCAL_INTERMEDIATE_SOURCE_DIR := $(intermediates.COMMON)/src

###############################################################
## .rs files: RenderScript sources to .java files and .bc files
## .fs files: Filterscript sources to .java files and .bc files
###############################################################
renderscript_sources := $(filter %.rs %.fs,$(LOCAL_SRC_FILES))
# Because names of the java files from RenderScript are unknown until the
# .rs file(s) are compiled, we have to depend on a timestamp file.
RenderScript_file_stamp :=
rs_generated_res_dir :=
rs_compatibility_jni_libs :=
ifneq ($(renderscript_sources),)
renderscript_sources_fullpath := $(addprefix $(LOCAL_PATH)/, $(renderscript_sources))
RenderScript_file_stamp := $(LOCAL_INTERMEDIATE_SOURCE_DIR)/RenderScript.stamp
renderscript_intermediate.COMMON := $(intermediates.COMMON)/renderscript

# Defaulting to an empty string uses the latest available platform SDK.
renderscript_target_api :=

ifneq (,$(LOCAL_RENDERSCRIPT_TARGET_API))
  renderscript_target_api := $(LOCAL_RENDERSCRIPT_TARGET_API)
else
  ifneq (,$(LOCAL_SDK_VERSION))
    # Set target-api for LOCAL_SDK_VERSIONs other than current.
    ifneq (,$(filter-out current system_current test_current, $(LOCAL_SDK_VERSION)))
      renderscript_target_api := $(LOCAL_SDK_VERSION)
    endif
  endif  # LOCAL_SDK_VERSION is set
endif  # LOCAL_RENDERSCRIPT_TARGET_API is set

# For 64-bit, we always have to upgrade to at least 21 for compat build.
ifneq ($(LOCAL_RENDERSCRIPT_COMPATIBILITY),)
  ifeq ($(TARGET_IS_64_BIT),true)
    ifneq ($(filter $(RSCOMPAT_32BIT_ONLY_API_LEVELS),$(renderscript_target_api)),)
      renderscript_target_api := 21
    endif
  endif
endif

ifeq ($(LOCAL_RENDERSCRIPT_CC),)
LOCAL_RENDERSCRIPT_CC := $(LLVM_RS_CC)
endif

# Turn on all warnings and warnings as errors for RS compiles.
# This can be disabled with LOCAL_RENDERSCRIPT_FLAGS := -Wno-error
renderscript_flags := -Wall -Werror
renderscript_flags += $(LOCAL_RENDERSCRIPT_FLAGS)

# prepend the RenderScript system include path
ifneq ($(filter-out current system_current test_current,$(LOCAL_SDK_VERSION))$(if $(TARGET_BUILD_APPS),$(filter current system_current test_current,$(LOCAL_SDK_VERSION))),)
# if a numeric LOCAL_SDK_VERSION, or current LOCAL_SDK_VERSION with TARGET_BUILD_APPS
LOCAL_RENDERSCRIPT_INCLUDES := \
    $(HISTORICAL_SDK_VERSIONS_ROOT)/renderscript/clang-include \
    $(HISTORICAL_SDK_VERSIONS_ROOT)/renderscript/include \
    $(LOCAL_RENDERSCRIPT_INCLUDES)
else
LOCAL_RENDERSCRIPT_INCLUDES := \
    $(TOPDIR)external/clang/lib/Headers \
    $(TOPDIR)frameworks/rs/script_api/include \
    $(LOCAL_RENDERSCRIPT_INCLUDES)
endif

ifneq ($(LOCAL_RENDERSCRIPT_INCLUDES_OVERRIDE),)
LOCAL_RENDERSCRIPT_INCLUDES := $(LOCAL_RENDERSCRIPT_INCLUDES_OVERRIDE)
endif

bc_files := $(patsubst %.fs,%.bc, $(patsubst %.rs,%.bc, $(notdir $(renderscript_sources))))
bc_dep_files := $(addprefix $(renderscript_intermediate.COMMON)/,$(patsubst %.bc,%.d,$(bc_files)))

$(RenderScript_file_stamp): PRIVATE_RS_INCLUDES := $(LOCAL_RENDERSCRIPT_INCLUDES)
$(RenderScript_file_stamp): PRIVATE_RS_CC := $(LOCAL_RENDERSCRIPT_CC)
$(RenderScript_file_stamp): PRIVATE_RS_FLAGS := $(renderscript_flags)
$(RenderScript_file_stamp): PRIVATE_RS_SOURCE_FILES := $(renderscript_sources_fullpath)
# By putting the generated java files into $(LOCAL_INTERMEDIATE_SOURCE_DIR), they will be
# automatically found by the java compiling function transform-java-to-classes.jar.
$(RenderScript_file_stamp): PRIVATE_RS_OUTPUT_DIR := $(renderscript_intermediate.COMMON)
$(RenderScript_file_stamp): PRIVATE_RS_TARGET_API := $(renderscript_target_api)
$(RenderScript_file_stamp): PRIVATE_DEP_FILES := $(bc_dep_files)
$(RenderScript_file_stamp): $(renderscript_sources_fullpath) $(LOCAL_RENDERSCRIPT_CC)
	$(transform-renderscripts-to-java-and-bc)

# include the dependency files (.d/.P) generated by llvm-rs-cc.
$(call include-depfile,$(RenderScript_file_stamp).P,$(RenderScript_file_stamp))

ifneq ($(LOCAL_RENDERSCRIPT_COMPATIBILITY),)


ifeq ($(filter $(RSCOMPAT_32BIT_ONLY_API_LEVELS),$(renderscript_target_api)),)
ifeq ($(TARGET_IS_64_BIT),true)
renderscript_intermediate.bc_folder := $(renderscript_intermediate.COMMON)/res/raw/bc64/
else
renderscript_intermediate.bc_folder := $(renderscript_intermediate.COMMON)/res/raw/bc32/
endif
else
renderscript_intermediate.bc_folder := $(renderscript_intermediate.COMMON)/res/raw/
endif

rs_generated_bc := $(addprefix \
    $(renderscript_intermediate.bc_folder), $(bc_files))

renderscript_intermediate := $(intermediates)/renderscript

# We don't need the .so files in bundled branches
# Prevent these from showing up on the device
# One exception is librsjni.so, which is needed for
# both native path and compat path.
rs_jni_lib := $(TARGET_OUT_INTERMEDIATE_LIBRARIES)/librsjni.so
LOCAL_JNI_SHARED_LIBRARIES += librsjni

ifneq (,$(TARGET_BUILD_APPS)$(FORCE_BUILD_RS_COMPAT))

rs_compatibility_jni_libs := $(addprefix \
    $(renderscript_intermediate)/librs., \
    $(patsubst %.bc,%.so, $(bc_files)))

$(rs_generated_bc) : $(RenderScript_file_stamp)

rs_support_lib := $(TARGET_OUT_INTERMEDIATE_LIBRARIES)/libRSSupport.so
LOCAL_JNI_SHARED_LIBRARIES += libRSSupport

rs_support_io_lib :=
# check if the target api level support USAGE_IO
ifeq ($(filter $(RSCOMPAT_NO_USAGEIO_API_LEVELS),$(renderscript_target_api)),)
rs_support_io_lib := $(TARGET_OUT_INTERMEDIATE_LIBRARIES)/libRSSupportIO.so
LOCAL_JNI_SHARED_LIBRARIES += libRSSupportIO
endif

my_arch := $(TARGET_$(LOCAL_2ND_ARCH_VAR_PREFIX)ARCH)
ifneq (,$(filter arm64 mips64 x86_64,$(my_arch)))
  my_min_sdk_version := 21
else
  my_min_sdk_version := $(MIN_SUPPORTED_SDK_VERSION)
endif

$(rs_compatibility_jni_libs): $(RenderScript_file_stamp) $(RS_PREBUILT_CLCORE) \
    $(rs_support_lib) $(rs_support_io_lib) $(rs_jni_lib) $(rs_compiler_rt)
$(rs_compatibility_jni_libs): $(BCC_COMPAT)
$(rs_compatibility_jni_libs): PRIVATE_CXX := $(CXX_WRAPPER) $(TARGET_CXX)
$(rs_compatibility_jni_libs): PRIVATE_SDK_VERSION := $(my_min_sdk_version)
$(rs_compatibility_jni_libs): $(renderscript_intermediate)/librs.%.so: \
    $(renderscript_intermediate.bc_folder)%.bc \
    $(SOONG_OUT_DIR)/ndk.timestamp
	$(transform-bc-to-so)

endif

endif

LOCAL_INTERMEDIATE_TARGETS += $(RenderScript_file_stamp)
# Make sure the generated resource will be added to the apk.
rs_generated_res_dir := $(renderscript_intermediate.COMMON)/res
LOCAL_RESOURCE_DIR := $(rs_generated_res_dir) $(LOCAL_RESOURCE_DIR)
endif


###########################################################
## AIDL: Compile .aidl files to .java
###########################################################
aidl_sources := $(filter %.aidl,$(LOCAL_SRC_FILES))
aidl_java_sources :=

ifneq ($(strip $(aidl_sources)),)

aidl_preprocess_import :=
ifdef LOCAL_SDK_VERSION
ifneq ($(filter current system_current test_current, $(LOCAL_SDK_VERSION)$(TARGET_BUILD_APPS)),)
  # LOCAL_SDK_VERSION is current and no TARGET_BUILD_APPS
  aidl_preprocess_import := $(TARGET_OUT_COMMON_INTERMEDIATES)/framework.aidl
else
  aidl_preprocess_import := $(HISTORICAL_SDK_VERSIONS_ROOT)/$(LOCAL_SDK_VERSION)/framework.aidl
endif # not current or system_current
else
# build against the platform.
LOCAL_AIDL_INCLUDES += $(FRAMEWORKS_BASE_JAVA_SRC_DIRS)
endif # LOCAL_SDK_VERSION

$(foreach s,$(aidl_sources),\
    $(eval $(call define-aidl-java-rule,$(s),$(intermediates.COMMON)/aidl,aidl_java_sources)))
$(foreach java,$(aidl_java_sources), \
    $(call include-depfile,$(java:%.java=%.P),$(java)))

$(aidl_java_sources) : $(LOCAL_ADDITIONAL_DEPENDENCIES) $(aidl_preprocess_import)

$(aidl_java_sources): PRIVATE_AIDL_FLAGS := -b $(addprefix -p,$(aidl_preprocess_import)) -I$(LOCAL_PATH) -I$(LOCAL_PATH)/src $(addprefix -I,$(LOCAL_AIDL_INCLUDES))
$(aidl_java_sources): PRIVATE_MODULE := $(LOCAL_MODULE)

endif

##########################################

# All of the rules after full_classes_compiled_jar are very unlikely
# to fail except for bugs in their respective tools.  If you would
# like to run these rules, add the "all" modifier goal to the make
# command line.
ifndef LOCAL_CHECKED_MODULE
ifdef full_classes_jar
LOCAL_CHECKED_MODULE := $(full_classes_compiled_jar)
endif
endif

#######################################
include $(BUILD_SYSTEM)/base_rules.mk
#######################################

###########################################################
## logtags: emit java source
###########################################################
ifneq ($(strip $(logtags_sources)),)

logtags_java_sources := $(patsubst %.logtags,%.java,$(addprefix $(intermediates.COMMON)/logtags/, $(logtags_sources)))
logtags_sources := $(addprefix $(LOCAL_PATH)/, $(logtags_sources))

$(logtags_java_sources): PRIVATE_MERGED_TAG := $(TARGET_OUT_COMMON_INTERMEDIATES)/all-event-log-tags.txt
$(logtags_java_sources): $(intermediates.COMMON)/logtags/%.java: $(LOCAL_PATH)/%.logtags $(TARGET_OUT_COMMON_INTERMEDIATES)/all-event-log-tags.txt $(JAVATAGS) build/tools/event_log_tags.py
	$(transform-logtags-to-java)

else
logtags_java_sources :=
endif

##########################################
java_sources := $(addprefix $(LOCAL_PATH)/, $(filter %.java,$(LOCAL_SRC_FILES))) $(aidl_java_sources) $(logtags_java_sources) \
                $(filter %.java,$(LOCAL_GENERATED_SOURCES))
java_intermediate_sources := $(addprefix $(TARGET_OUT_COMMON_INTERMEDIATES)/, $(filter %.java,$(LOCAL_INTERMEDIATE_SOURCES)))
all_java_sources := $(java_sources) $(java_intermediate_sources)

enable_sharding :=
ifneq ($(TURBINE_ENABLED),false)
ifneq ($(LOCAL_JAVAC_SHARD_SIZE),)
ifneq ($(LOCAL_JAR_PROCESSOR),)
$(call pretty-error,Cannot set both LOCAL_JAVAC_SHARD_SIZE and LOCAL_JAR_PROCESSOR!)
endif # LOCAL_JAR_PROCESSOR is not empty
enable_sharding := true

num_shards := $(call int_divide,$(words $(java_sources)),$(LOCAL_JAVAC_SHARD_SIZE))
ifneq ($(words $(java_sources)),$(call int_multiply,$(LOCAL_JAVAC_SHARD_SIZE),$(num_shards)))
# increment number of shards by 1.
num_shards := $(call int_plus,$(num_shards),1)
endif

shard_idx_list := $(call int_range_list,1,$(num_shards))
sharded_java_source_list_files += $(foreach x,$(shard_idx_list),$(java_source_list_file).shard.$(x))
sharded_jar_list += $(foreach x,$(shard_idx_list),$(full_classes_compiled_jar).shard.$(x))

# always put dynamically-located .java files (generated by Proto/resource, etc) in a new final shard.
# increment number of shards by 1.
num_shards := $(call int_plus,$(num_shards),1)
sharded_java_source_list_files += $(java_source_list_file).shard.$(num_shards)
sharded_jar_list += $(full_classes_compiled_jar).shard.$(num_shards)
LOCAL_INTERMEDIATE_TARGETS += $(sharded_java_source_list_files)
LOCAL_INTERMEDIATE_TARGETS += $(sharded_jar_list)
endif # LOCAL_JAVAC_SHARD_SIZE is not empty
endif # TURBINE_ENABLED != false

include $(BUILD_SYSTEM)/java_common.mk

$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_HAS_RS_SOURCES := $(if $(renderscript_sources),true)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_RS_SOURCE_INTERMEDIATES_DIR := $(intermediates.COMMON)/renderscript

#######################################
# defines built_odex along with rule to install odex
include $(BUILD_SYSTEM)/dex_preopt_odex_install.mk
#######################################

# Make sure there's something to build.
ifdef full_classes_jar
ifndef need_compile_java
$(error $(LOCAL_PATH): Target java module does not define any source or resource files)
endif
endif

# Since we're using intermediates.COMMON, make sure that it gets cleaned
# properly.
$(cleantarget): PRIVATE_CLEAN_FILES += $(intermediates.COMMON)

ifdef full_classes_jar

# Droiddoc isn't currently able to generate stubs for modules, so we're just
# allowing it to use the classes.jar as the "stubs" that would be use to link
# against, for the cases where someone needs the jar to link against.
$(eval $(call copy-one-file,$(full_classes_jar),$(full_classes_stubs_jar)))
ALL_MODULES.$(LOCAL_MODULE).STUBS := $(full_classes_stubs_jar)

# The layers file allows you to enforce a layering between java packages.
# Run build/tools/java-layers.py for more details.
layers_file := $(addprefix $(LOCAL_PATH)/, $(LOCAL_JAVA_LAYERS_FILE))
$(full_classes_compiled_jar): PRIVATE_JAVA_LAYERS_FILE := $(layers_file)
$(full_classes_compiled_jar): PRIVATE_WARNINGS_ENABLE := $(LOCAL_WARNINGS_ENABLE)

# Compile the java files to a .jar file.
# This intentionally depends on java_sources, not all_java_sources.
# Deps for generated source files must be handled separately,
# via deps on the target that generates the sources.

# If error prone is enabled then add LOCAL_ERROR_PRONE_FLAGS to LOCAL_JAVACFLAGS
ifeq ($(RUN_ERROR_PRONE),true)
LOCAL_JAVACFLAGS += $(LOCAL_ERROR_PRONE_FLAGS)
endif

# For user / userdebug builds, strip the local variable table and the local variable
# type table. This has no bearing on stack traces, but will leave less information
# available via JDWP.
ifneq (,$(PRODUCT_MINIMIZE_JAVA_DEBUG_INFO))
ifneq (,$(filter userdebug user,$(TARGET_BUILD_VARIANT)))
LOCAL_JAVACFLAGS+= -g:source,lines
endif
endif

# List of dependencies for anything that needs all java sources in place
java_sources_deps := \
    $(java_sources) \
    $(java_resource_sources) \
    $(RenderScript_file_stamp) \
    $(proto_java_sources_file_stamp) \
    $(LOCAL_ADDITIONAL_DEPENDENCIES)

$(java_source_list_file): $(java_sources_deps)
	$(write-java-source-list)

ifdef enable_sharding
$(foreach x,$(shard_idx_list),\
  $(eval $(call save-sharded-java-source-list,$(x),\
    $(wordlist $(call int_plus,1,$(call int_multiply,$(LOCAL_JAVAC_SHARD_SIZE),$(call int_subtract,$(x),1))),\
      $(call int_multiply,$(LOCAL_JAVAC_SHARD_SIZE),$(x)),$(sort $(java_sources))))))

# always put dynamically-located .java files (generated by Proto/resource, etc) in a new final shard.
$(java_source_list_file).shard.$(num_shards): PRIVATE_JAVA_INTERMEDIATE_SOURCES := $(java_intermediate_sources)
$(java_source_list_file).shard.$(num_shards): $(java_resource_sources) \
    $(RenderScript_file_stamp) \
    $(proto_java_sources_file_stamp) \
    $(LOCAL_ADDITIONAL_DEPENDENCIES) \
    $(NORMALIZE_PATH)
	$(hide) rm -f $@
	$(call dump-words-to-file,$(PRIVATE_JAVA_INTERMEDIATE_SOURCES),$@.tmp)
	$(call fetch-additional-java-source,$@.tmp)
	$(hide) tr ' ' '\n' < $@.tmp | $(NORMALIZE_PATH) | sort -u > $@

# Javac sharding with header libs including its own header jar as one of dependency.
$(foreach x,$(shard_idx_list),\
  $(eval $(call create-classes-full-debug.jar,$(full_classes_compiled_jar).shard.$(x),\
    $(java_source_list_file).shard.$(x),\
      $(full_java_header_libs) $(full_classes_header_jar),$(x),\
        $(wordlist $(call int_plus,1,$(call int_multiply,$(LOCAL_JAVAC_SHARD_SIZE),$(call int_subtract,$(x),1))),\
          $(call int_multiply,$(LOCAL_JAVAC_SHARD_SIZE),$(x)),$(sort $(java_sources))))))

# Javac sharding for last shard with additional Java dependencies.
$(eval $(call create-classes-full-debug.jar,$(full_classes_compiled_jar).shard.$(num_shards),\
  $(java_source_list_file).shard.$(num_shards),$(full_java_header_libs) $(full_classes_header_jar),$(strip \
    $(num_shards)),$$(java_resource_sources) $$(RenderScript_file_stamp) \
      $$(proto_java_sources_file_stamp) $$(LOCAL_ADDITIONAL_DEPENDENCIES)))

$(full_classes_compiled_jar): PRIVATE_SHARDED_JAR_LIST := $(sharded_jar_list)
$(full_classes_compiled_jar): $(sharded_jar_list) | $(MERGE_ZIPS)
	$(MERGE_ZIPS) -j $@ $(PRIVATE_SHARDED_JAR_LIST)
else
# we can't use single $ for java_sources_deps since it may contain hash '#' sign.
$(eval $(call create-classes-full-debug.jar,$(full_classes_compiled_jar),\
  $(java_source_list_file),$(full_java_header_libs),,$$(java_sources_deps)))

endif # ifdef enable_sharding

ifneq ($(TURBINE_ENABLED),false)

$(full_classes_turbine_jar): PRIVATE_JAVACFLAGS := $(LOCAL_JAVACFLAGS) $(annotation_processor_flags)
$(full_classes_turbine_jar): PRIVATE_DONT_DELETE_JAR_META_INF := $(LOCAL_DONT_DELETE_JAR_META_INF)
$(full_classes_turbine_jar): \
    $(java_source_list_file) \
    $(java_sources_deps) \
    $(full_java_header_libs) \
    $(full_java_bootclasspath_libs) \
    $(full_java_system_modules_deps) \
    $(NORMALIZE_PATH) \
    $(JAR_ARGS) \
    $(ZIPTIME) \
    | $(TURBINE) \
    $(MERGE_ZIPS)
	$(transform-java-to-header.jar)

.KATI_RESTAT: $(full_classes_turbine_jar)

# Run jarjar before generate classes-header.jar if necessary.
ifneq ($(strip $(LOCAL_JARJAR_RULES)),)
$(full_classes_header_jarjar): PRIVATE_JARJAR_RULES := $(LOCAL_JARJAR_RULES)
$(full_classes_header_jarjar): $(full_classes_turbine_jar) $(LOCAL_JARJAR_RULES) | $(JARJAR)
	@echo Header JarJar: $@
	$(hide) $(JAVA) -jar $(JARJAR) process $(PRIVATE_JARJAR_RULES) $< $@
else
full_classes_header_jarjar := $(full_classes_turbine_jar)
endif

$(eval $(call copy-one-file,$(full_classes_header_jarjar),$(full_classes_header_jar)))

endif # TURBINE_ENABLED != false

javac-check : $(full_classes_compiled_jar)
javac-check-$(LOCAL_MODULE) : $(full_classes_compiled_jar)

$(full_classes_combined_jar): PRIVATE_DONT_DELETE_JAR_META_INF := $(LOCAL_DONT_DELETE_JAR_META_INF)
$(full_classes_combined_jar): $(full_classes_compiled_jar) \
                              $(jar_manifest_file) \
                              $(full_static_java_libs) | $(MERGE_ZIPS)
	$(if $(PRIVATE_JAR_MANIFEST), $(hide) sed -e "s/%BUILD_NUMBER%/$(BUILD_NUMBER_FROM_FILE)/" \
            $(PRIVATE_JAR_MANIFEST) > $(dir $@)/manifest.mf)
	$(MERGE_ZIPS) -j $(if $(PRIVATE_JAR_MANIFEST),-m $(dir $@)/manifest.mf) \
            $(if $(PRIVATE_DONT_DELETE_JAR_META_INF),,-stripDir META-INF -zipToNotStrip $<) \
            $@ $< $(call reverse-list,$(PRIVATE_STATIC_JAVA_LIBRARIES))

ifdef LOCAL_JAR_PROCESSOR
# LOCAL_JAR_PROCESSOR_ARGS must be evaluated here to set up the rule-local
# PRIVATE_JAR_PROCESSOR_ARGS variable, but $< and $@ are not available yet.
# Set ${in} and ${out} so they can be referenced by LOCAL_JAR_PROCESSOR_ARGS
# using deferred evaluation (LOCAL_JAR_PROCESSOR_ARGS = instead of :=).
in := $(full_classes_combined_jar)
out := $(full_classes_processed_jar).tmp
my_jar_processor := $(HOST_OUT_JAVA_LIBRARIES)/$(LOCAL_JAR_PROCESSOR).jar

$(full_classes_processed_jar): PRIVATE_JAR_PROCESSOR_ARGS := $(LOCAL_JAR_PROCESSOR_ARGS)
$(full_classes_processed_jar): PRIVATE_JAR_PROCESSOR := $(my_jar_processor)
$(full_classes_processed_jar): PRIVATE_TMP_OUT := $(out)
in :=
out :=

$(full_classes_processed_jar): $(full_classes_combined_jar) $(my_jar_processor)
	@echo Processing $@ with $(PRIVATE_JAR_PROCESSOR)
	$(hide) rm -f $@ $(PRIVATE_TMP_OUT)
	$(hide) $(JAVA) -jar $(PRIVATE_JAR_PROCESSOR) $(PRIVATE_JAR_PROCESSOR_ARGS)
	$(hide) mv $(PRIVATE_TMP_OUT) $@

my_jar_processor :=
else
full_classes_processed_jar := $(full_classes_combined_jar)
endif

# Run jarjar if necessary
ifneq ($(strip $(LOCAL_JARJAR_RULES)),)
$(full_classes_jarjar_jar): PRIVATE_JARJAR_RULES := $(LOCAL_JARJAR_RULES)
$(full_classes_jarjar_jar): $(full_classes_processed_jar) $(LOCAL_JARJAR_RULES) | $(JARJAR)
	@echo JarJar: $@
	$(hide) $(JAVA) -jar $(JARJAR) process $(PRIVATE_JARJAR_RULES) $< $@
else
full_classes_jarjar_jar := $(full_classes_processed_jar)
endif

$(eval $(call copy-one-file,$(full_classes_jarjar_jar),$(full_classes_jar)))

# Temporarily enable --multi-dex until proguard supports v53 class files
# ( http://b/67673860 ) or we move away from proguard altogether.
ifdef TARGET_OPENJDK9
LOCAL_DX_FLAGS := $(filter-out --multi-dex,$(LOCAL_DX_FLAGS)) --multi-dex
endif

my_desugaring :=
ifndef LOCAL_IS_STATIC_JAVA_LIBRARY
my_desugaring := true
$(full_classes_desugar_jar): PRIVATE_DX_FLAGS := $(LOCAL_DX_FLAGS)
$(full_classes_desugar_jar): $(full_classes_jar) $(full_java_header_libs) $(DESUGAR)
	$(desugar-classes-jar)
endif

ifndef my_desugaring
full_classes_desugar_jar := $(full_classes_jar)
endif

LOCAL_FULL_CLASSES_PRE_JACOCO_JAR := $(full_classes_desugar_jar)

#######################################
include $(BUILD_SYSTEM)/jacoco.mk
#######################################

full_classes_pre_proguard_jar := $(LOCAL_FULL_CLASSES_JACOCO_JAR)

# Keep a copy of the jar just before proguard processing.
$(eval $(call copy-one-file,$(full_classes_pre_proguard_jar),$(intermediates.COMMON)/classes-pre-proguard.jar))

# Run proguard if necessary
ifdef LOCAL_PROGUARD_ENABLED
ifneq ($(filter-out full custom nosystem obfuscation optimization shrinktests,$(LOCAL_PROGUARD_ENABLED)),)
    $(warning while processing: $(LOCAL_MODULE))
    $(error invalid value for LOCAL_PROGUARD_ENABLED: $(LOCAL_PROGUARD_ENABLED))
endif
proguard_dictionary := $(intermediates.COMMON)/proguard_dictionary

# When an app contains references to APIs that are not in the SDK specified by
# its LOCAL_SDK_VERSION for example added by support library or by runtime 
# classes added by desugar, we artifically raise the "SDK version" "linked" by
# ProGuard, to
# - suppress ProGuard warnings of referencing symbols unknown to the lower SDK version.
# - prevent ProGuard stripping subclass in the support library that extends class added in the higher SDK version.
# See b/20667396
my_proguard_sdk_raise :=
ifdef LOCAL_SDK_VERSION
ifdef TARGET_BUILD_APPS
ifeq (,$(filter current system_current test_current, $(LOCAL_SDK_VERSION)))
  my_proguard_sdk_raise := $(call java-lib-header-files, sdk_vcurrent)
endif
else
  # For platform build, we can't just raise to the "current" SDK,
  # that would break apps that use APIs removed from the current SDK.
  my_proguard_sdk_raise := $(call java-lib-header-files,$(TARGET_DEFAULT_BOOTCLASSPATH_LIBRARIES) $(TARGET_DEFAULT_JAVA_LIBRARIES))
endif
endif

legacy_proguard_flags := $(addprefix -libraryjars ,$(my_proguard_sdk_raise) \
  $(filter-out $(my_proguard_sdk_raise), \
    $(full_java_bootclasspath_libs) \
    $(full_shared_java_header_libs)))

legacy_proguard_lib_deps := $(my_proguard_sdk_raise) \
  $(filter-out $(my_proguard_sdk_raise),$(full_shared_java_header_libs))

legacy_proguard_flags += -printmapping $(proguard_dictionary)

common_proguard_flags := -forceprocessing

common_proguard_flag_files :=
ifeq ($(filter nosystem,$(LOCAL_PROGUARD_ENABLED)),)
common_proguard_flag_files += $(BUILD_SYSTEM)/proguard.flags
ifeq ($(LOCAL_EMMA_INSTRUMENT),true)
common_proguard_flags += -include $(BUILD_SYSTEM)/proguard.emma.flags
endif
# If this is a test package, add proguard keep flags for tests.
ifneq ($(LOCAL_INSTRUMENTATION_FOR)$(filter tests,$(LOCAL_MODULE_TAGS)),)
common_proguard_flag_files += $(BUILD_SYSTEM)/proguard_tests.flags
ifeq ($(filter shrinktests,$(LOCAL_PROGUARD_ENABLED)),)
common_proguard_flags += -dontshrink # don't shrink tests by default
endif # shrinktests
endif # test package
ifneq ($(common_proguard_flag_files),)
common_proguard_flags += $(addprefix -include , $(common_proguard_flag_files))
# This is included from $(BUILD_SYSTEM)/proguard.flags
common_proguard_flag_files += $(BUILD_SYSTEM)/proguard_basic_keeps.flags
endif

ifeq ($(filter obfuscation,$(LOCAL_PROGUARD_ENABLED)),)
# By default no obfuscation
common_proguard_flags += -dontobfuscate
endif  # No obfuscation
ifeq ($(filter optimization,$(LOCAL_PROGUARD_ENABLED)),)
# By default no optimization
common_proguard_flags += -dontoptimize
endif  # No optimization

ifdef LOCAL_INSTRUMENTATION_FOR
ifeq ($(filter obfuscation,$(LOCAL_PROGUARD_ENABLED)),)
# If no obfuscation, link in the instrmented package's classes.jar as a library.
# link_instr_classes_jar is defined in base_rule.mk
legacy_proguard_flags += -libraryjars $(link_instr_classes_jar)
legacy_proguard_lib_deps += $(link_instr_classes_jar)
else # obfuscation
# If obfuscation is enabled, the main app must be obfuscated too.
# We need to run obfuscation using the main app's dictionary,
# and treat the main app's class.jar as injars instead of libraryjars.
legacy_proguard_flags := -injars  $(link_instr_classes_jar) \
    -outjars $(intermediates.COMMON)/proguard.$(LOCAL_INSTRUMENTATION_FOR).jar \
    -include $(link_instr_intermediates_dir.COMMON)/proguard_options \
    -applymapping $(link_instr_intermediates_dir.COMMON)/proguard_dictionary \
    -verbose \
    $(legacy_proguard_flags)

# Sometimes (test + main app) uses different keep rules from the main app -
# apply the main app's dictionary anyway.
legacy_proguard_flags += -ignorewarnings

# Make sure we run Proguard on the main app first
$(full_classes_proguard_jar) : $(link_instr_intermediates_dir.COMMON)/proguard.classes.jar

endif # no obfuscation
endif # LOCAL_INSTRUMENTATION_FOR
endif  # LOCAL_PROGUARD_ENABLED is not nosystem

proguard_flag_files := $(addprefix $(LOCAL_PATH)/, $(LOCAL_PROGUARD_FLAG_FILES))
ifeq ($(USE_R8),true)
proguard_flag_files += $(addprefix $(LOCAL_PATH)/, $(LOCAL_R8_FLAG_FILES))
endif # USE_R8
LOCAL_PROGUARD_FLAGS += $(addprefix -include , $(proguard_flag_files))

ifdef LOCAL_TEST_MODULE_TO_PROGUARD_WITH
extra_input_jar := $(call intermediates-dir-for,APPS,$(LOCAL_TEST_MODULE_TO_PROGUARD_WITH),,COMMON)/classes.jar
else
extra_input_jar :=
endif

# If building against the current SDK version then filter out the junit,
# android.test and c.a.i.u.Predicate classes that are to be removed from
# the Android API as part of b/30188076 but which are still present in
# the Android API. This is to allow changes to be made to the build to
# statically include those classes into the application without
# simultaneously removing those classes from the API.
proguard_injar_filters :=
ifdef LOCAL_SDK_VERSION
ifeq (,$(filter-out current system_current test_current, $(LOCAL_SDK_VERSION)))
proguard_injar_filters := (!junit/framework/**,!junit/runner/**,!junit/textui/**,!android/test/**,!com/android/internal/util/*)
endif
endif

ifneq ($(filter obfuscation,$(LOCAL_PROGUARD_ENABLED)),)
ifneq ($(USE_R8),true)
  $(full_classes_proguard_jar): .KATI_IMPLICIT_OUTPUTS := $(proguard_dictionary)
else
  $(built_dex_intermediate): .KATI_IMPLICIT_OUTPUTS := $(proguard_dictionary)
endif
endif

# If R8 is not enabled run Proguard.
ifneq ($(USE_R8),true)
# Changes to these dependencies need to be replicated below when using R8
# instead of Proguard + dx.
$(full_classes_proguard_jar): PRIVATE_PROGUARD_INJAR_FILTERS := $(proguard_injar_filters)
$(full_classes_proguard_jar): PRIVATE_EXTRA_INPUT_JAR := $(extra_input_jar)
$(full_classes_proguard_jar): PRIVATE_PROGUARD_FLAGS := $(legacy_proguard_flags) $(common_proguard_flags) $(LOCAL_PROGUARD_FLAGS)
$(full_classes_proguard_jar) : $(full_classes_pre_proguard_jar) $(extra_input_jar) $(my_proguard_sdk_raise) $(common_proguard_flag_files) $(proguard_flag_files) $(legacy_proguard_lib_deps) | $(PROGUARD)
	$(call transform-jar-to-proguard)
else # !USE_R8
# Running R8 instead of Proguard, proguarded jar is actually the pre-Proguarded jar.
full_classes_proguard_jar := $(full_classes_pre_proguard_jar)
endif # !USE_R8

else  # LOCAL_PROGUARD_ENABLED not defined
proguard_flag_files :=
full_classes_proguard_jar := $(full_classes_pre_proguard_jar)
endif # LOCAL_PROGUARD_ENABLED defined

ifneq ($(LOCAL_IS_STATIC_JAVA_LIBRARY),true)
$(built_dex_intermediate): PRIVATE_DX_FLAGS := $(LOCAL_DX_FLAGS)
# If you instrument class files that have local variable debug information in
# them emma does not correctly maintain the local variable table.
# This will cause an error when you try to convert the class files for Android.
# The workaround here is to build different dex file here based on emma switch
# then later copy into classes.dex. When emma is on, dx is run with --no-locals
# option to remove local variable information
ifeq ($(LOCAL_EMMA_INSTRUMENT),true)
$(built_dex_intermediate): PRIVATE_DX_FLAGS += --no-locals
endif

my_r8 :=
ifdef LOCAL_PROGUARD_ENABLED
ifeq ($(USE_R8),true)
# These are the dependencies for the proguarded jar when running
# Proguard + dx. They are used for the generated dex when using R8, as
# R8 does Proguard + dx
my_r8 := true
$(built_dex_intermediate): PRIVATE_PROGUARD_INJAR_FILTERS := $(proguard_injar_filters)
$(built_dex_intermediate): PRIVATE_EXTRA_INPUT_JAR := $(extra_input_jar)
$(built_dex_intermediate): PRIVATE_PROGUARD_FLAGS := $(legacy_proguard_flags) $(common_proguard_flags) $(LOCAL_PROGUARD_FLAGS)
$(built_dex_intermediate) : $(full_classes_proguard_jar) $(extra_input_jar) $(my_support_library_sdk_raise) $(common_proguard_flag_files) $(proguard_flag_files) $(legacy_proguard_lib_deps) $(R8_COMPAT_PROGUARD)
	$(transform-jar-to-dex-r8)
endif # USE_R8
endif # LOCAL_PROGUARD_ENABLED

ifndef my_r8
$(built_dex_intermediate): $(full_classes_proguard_jar) $(DX)
	$(transform-classes.jar-to-dex)
endif

$(built_dex): $(built_dex_intermediate)
	@echo Copying: $@
	$(hide) mkdir -p $(dir $@)
	$(hide) rm -f $(dir $@)/classes*.dex
	$(hide) cp -fp $(dir $<)/classes*.dex $(dir $@)

java-dex: $(built_dex)

endif # !LOCAL_IS_STATIC_JAVA_LIBRARY

findbugs_xml := $(intermediates.COMMON)/findbugs.xml
$(findbugs_xml): PRIVATE_AUXCLASSPATH := $(addprefix -auxclasspath ,$(strip \
    $(call normalize-path-list,$(filter %.jar,$(full_java_libs)))))
$(findbugs_xml): PRIVATE_FINDBUGS_FLAGS := $(LOCAL_FINDBUGS_FLAGS)
$(findbugs_xml) : $(full_classes_pre_proguard_jar) $(filter %.xml, $(LOCAL_FINDBUGS_FLAGS))
	@echo Findbugs: $@
	$(hide) $(FINDBUGS) -textui -effort:min -xml:withMessages \
		$(PRIVATE_AUXCLASSPATH) $(PRIVATE_FINDBUGS_FLAGS) \
		$< \
		> $@

ALL_FINDBUGS_FILES += $(findbugs_xml)

findbugs_html := $(PRODUCT_OUT)/findbugs/$(LOCAL_MODULE).html
$(findbugs_html) : PRIVATE_XML_FILE := $(findbugs_xml)
$(LOCAL_MODULE)-findbugs : $(findbugs_html)
$(findbugs_html) : $(findbugs_xml)
	@mkdir -p $(dir $@)
	@echo ConvertXmlToText: $@
	$(hide) $(FINDBUGS_DIR)/convertXmlToText -html:fancy.xsl $(PRIVATE_XML_FILE) \
	> $@

$(LOCAL_MODULE)-findbugs : $(findbugs_html)

endif  # full_classes_jar is defined

ifneq (,$(filter-out current system_current test_current, $(LOCAL_SDK_VERSION)))
  my_default_app_target_sdk := $(LOCAL_SDK_VERSION)
  my_sdk_version := $(LOCAL_SDK_VERSION)
else
  my_default_app_target_sdk := $(DEFAULT_APP_TARGET_SDK)
  my_sdk_version := $(PLATFORM_SDK_VERSION)
endif

ifdef LOCAL_MIN_SDK_VERSION
  my_min_sdk_version := $(LOCAL_MIN_SDK_VERSION)
else
  my_min_sdk_version := $(call codename-or-sdk-to-sdk,$(my_default_app_target_sdk))
endif

$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_DEFAULT_APP_TARGET_SDK := $(my_default_app_target_sdk)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_SDK_VERSION := $(my_sdk_version)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_MIN_SDK_VERSION := $(my_min_sdk_version)
