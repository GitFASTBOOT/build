## AAPT Flags
# aapt doesn't accept multiple --extra-packages flags.
# We have to collapse them into a single --extra-packages flag here.
LOCAL_AAPT_FLAGS := $(strip $(LOCAL_AAPT_FLAGS))
ifdef LOCAL_AAPT_FLAGS
  ifeq ($(filter 0 1,$(words $(filter --extra-packages,$(LOCAL_AAPT_FLAGS)))),)
    aapt_flags := $(subst --extra-packages$(space),--extra-packages@,$(LOCAL_AAPT_FLAGS))
    aapt_flags_extra_packages := $(patsubst --extra-packages@%,%,$(filter --extra-packages@%,$(aapt_flags)))
    aapt_flags_extra_packages := $(sort $(subst :,$(space),$(aapt_flags_extra_packages)))
    LOCAL_AAPT_FLAGS := $(filter-out --extra-packages@%,$(aapt_flags)) \
        --extra-packages $(subst $(space),:,$(aapt_flags_extra_packages))
    aapt_flags_extra_packages :=
    aapt_flags :=
  endif
endif

$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_AAPT_FLAGS := $(LOCAL_AAPT_FLAGS)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_TARGET_AAPT_CHARACTERISTICS := $(TARGET_AAPT_CHARACTERISTICS)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_MANIFEST_PACKAGE_NAME := $(LOCAL_MANIFEST_PACKAGE_NAME)
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_MANIFEST_INSTRUMENTATION_FOR := $(LOCAL_MANIFEST_INSTRUMENTATION_FOR)
