<<<<<<< HEAD   (5f91bd Merge "Merge empty history for sparse-8435393-L9030000095399)
=======
# Droiddoc prebuilt coming from Soong.

ifneq ($(LOCAL_MODULE_MAKEFILE),$(SOONG_ANDROID_MK))
  $(call pretty-error,soong_droiddoc_prebuilt.mk may only be used from Soong)
endif

ifdef LOCAL_DROIDDOC_STUBS_SRCJAR
$(eval $(call copy-one-file,$(LOCAL_DROIDDOC_STUBS_SRCJAR),$(OUT_DOCS)/$(LOCAL_MODULE)-stubs.srcjar))
$(eval ALL_TARGETS.$(OUT_DOCS)/$(LOCAL_MODULE)-stubs.srcjar.META_LIC := $(LOCAL_SOONG_LICENSE_METADATA))
ALL_DOCS += $(OUT_DOCS)/$(LOCAL_MODULE)-stubs.srcjar

.PHONY: $(LOCAL_MODULE)
$(LOCAL_MODULE) : $(OUT_DOCS)/$(LOCAL_MODULE)-stubs.srcjar
endif

ifdef LOCAL_DROIDDOC_DOC_ZIP
$(eval $(call copy-one-file,$(LOCAL_DROIDDOC_DOC_ZIP),$(OUT_DOCS)/$(LOCAL_MODULE)-docs.zip))
$(eval ALL_TARGETS.$(OUT_DOCS)/$(LOCAL_MODULE)-docs.zip.META_LIC := $(LOCAL_SOONG_LICENSE_METADATA))
$(call dist-for-goals,docs,$(OUT_DOCS)/$(LOCAL_MODULE)-docs.zip)

.PHONY: $(LOCAL_MODULE) $(LOCAL_MODULE)-docs.zip
$(LOCAL_MODULE) $(LOCAL_MODULE)-docs.zip : $(OUT_DOCS)/$(LOCAL_MODULE)-docs.zip
ALL_DOCS += $(OUT_DOCS)/$(LOCAL_MODULE)-docs.zip
endif

ifdef LOCAL_DROIDDOC_ANNOTATIONS_ZIP
$(eval $(call copy-one-file,$(LOCAL_DROIDDOC_ANNOTATIONS_ZIP),$(TARGET_OUT_COMMON_INTERMEDIATES)/PACKAGING/$(LOCAL_MODULE)_annotations.zip))
$(eval ALL_TARGETS.$(TARGET_OUT_COMMON_INTERMEDIATES)/PACKAGING/$(LOCAL_MODULE)_annotations.zip.META_LIC := $(LOCAL_SOONG_LICENSE_METADATA))
endif

ifdef LOCAL_DROIDDOC_API_VERSIONS_XML
$(eval $(call copy-one-file,$(LOCAL_DROIDDOC_API_VERSIONS_XML),$(TARGET_OUT_COMMON_INTERMEDIATES)/PACKAGING/$(LOCAL_MODULE)_generated-api-versions.xml))
$(eval ALL_TARGETS.$(TARGET_OUT_COMMON_INTERMEDIATES)/PACKAGING/$(LOCAL_MODULE)_generated-api-versions.xml.META_LIC := $(LOCAL_SOONG_LICENSE_METADATA))
endif

ifdef LOCAL_DROIDDOC_METADATA_ZIP
$(eval $(call copy-one-file,$(LOCAL_DROIDDOC_METADATA_ZIP),$(TARGET_OUT_COMMON_INTERMEDIATES)/PACKAGING/$(LOCAL_MODULE)-metadata.zip))
$(eval ALL_TARGETS.$(TARGET_OUT_COMMON_INTERMEDIATES)/PACKAGING/$(LOCAL_MODULE)-metadata.zip.META_LIC := $(LOCAL_SOONG_LICENSE_METADATA))
endif
>>>>>>> BRANCH (436489 Merge "Version bump to TKB1.220417.001.A1 [core/build_id.mk])
