#
# Copyright (C) 2014 The Android Open Source Project
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

# Set up variables and dependency for one odex file
# Input variables: my_2nd_arch_prefix
# Output(modified) variables: built_odex, installed_odex, built_installed_odex

my_built_odex := $(call get-odex-file-path,$($(my_2nd_arch_prefix)DEX2OAT_TARGET_ARCH),$(LOCAL_BUILT_MODULE))
ifdef LOCAL_DEX_PREOPT_IMAGE_LOCATION
my_dex_preopt_image_location := $(LOCAL_DEX_PREOPT_IMAGE_LOCATION)
else
my_dex_preopt_image_location := $($(my_2nd_arch_prefix)DEFAULT_DEX_PREOPT_BUILT_IMAGE_LOCATION)
endif
my_dex_preopt_image_filename := $(call get-image-file-path,$($(my_2nd_arch_prefix)DEX2OAT_TARGET_ARCH),$(my_dex_preopt_image_location))
$(my_built_odex): PRIVATE_2ND_ARCH_VAR_PREFIX := $(my_2nd_arch_prefix)
$(my_built_odex): PRIVATE_DEX_LOCATION := $(patsubst $(PRODUCT_OUT)%,%,$(LOCAL_INSTALLED_MODULE))
$(my_built_odex): PRIVATE_DEX_PREOPT_IMAGE_LOCATION := $(my_dex_preopt_image_location)
$(my_built_odex) : $($(my_2nd_arch_prefix)DEXPREOPT_ONE_FILE_DEPENDENCY_BUILT_BOOT_PREOPT) \
    $(DEXPREOPT_ONE_FILE_DEPENDENCY_TOOLS) \
    $(my_dex_preopt_image_filename)

my_installed_odex := $(call get-odex-installed-file-path,$($(my_2nd_arch_prefix)DEX2OAT_TARGET_ARCH),$(LOCAL_INSTALLED_MODULE))

my_built_vdex := $(patsubst %.odex,%.vdex,$(my_built_odex))
my_installed_vdex := $(patsubst %.odex,%.vdex,$(my_installed_odex))
my_installed_art := $(patsubst %.odex,%.art,$(my_installed_odex))

ifndef LOCAL_DEX_PREOPT_APP_IMAGE
# Local override not defined, use the global one.
ifeq (true,$(WITH_DEX_PREOPT_APP_IMAGE))
  LOCAL_DEX_PREOPT_APP_IMAGE := true
endif
endif

ifeq (true,$(LOCAL_DEX_PREOPT_APP_IMAGE))
my_built_art := $(patsubst %.odex,%.art,$(my_built_odex))
$(my_built_odex): PRIVATE_ART_FILE_PREOPT_FLAGS := --app-image-file=$(my_built_art) \
    --image-format=lz4
$(eval $(call copy-one-file,$(my_built_art),$(my_installed_art)))
built_art += $(my_built_art)
installed_art += $(my_installed_art)
built_installed_art += $(my_built_art):$(my_installed_art)
endif

ifndef LOCAL_DEX_PREOPT_GENERATE_PROFILE
ifeq (true,$(WITH_DEX_PREOPT_GENERATE_PROFILE))
  LOCAL_DEX_PREOPT_GENERATE_PROFILE := true
endif
endif

ifeq (true,$(LOCAL_DEX_PREOPT_GENERATE_PROFILE))
ifndef LOCAL_DEX_PREOPT_PROFILE_CLASS_LISTING
$(call pretty-error,Must have specified class listing (LOCAL_DEX_PREOPT_PROFILE_CLASS_LISTING))
endif
my_built_profile := $(dir $(my_built_odex))../../$($(my_2nd_arch_prefix)DEX2OAT_TARGET_ARCH).prof
my_profile_classes := $(patsubst %.prof,%.classes,$(my_built_profile))
my_dex_location := $(patsubst $(PRODUCT_OUT)%,%,$(LOCAL_INSTALLED_MODULE))
$(my_built_odex): $(my_built_profile)
$(my_built_odex): PRIVATE_PROFILE_PREOPT_FLAGS := --profile-file=$(my_built_profile)
$(my_built_profile): PRIVATE_INSTALLED_MODULE := $(LOCAL_INSTALLED_MODULE)
$(my_built_profile): PRIVATE_DEX_LOCATION := $(my_dex_location)
$(my_built_profile): PRIVATE_PROFILE_CLASSES := $(my_profile_classes)
$(my_built_profile): PRIVATE_SOURCE_CLASSES := $(LOCAL_DEX_PREOPT_PROFILE_CLASS_LISTING)
$(my_built_profile): $(LOCAL_DEX_PREOPT_PROFILE_CLASS_LISTING)
$(my_built_profile): $(PROFMAN)
$(my_built_profile): $(PRIVATE_INSTALLED_MODULE)
$(my_built_profile):
	cp $(PRIVATE_SOURCE_CLASSES) $(PRIVATE_PROFILE_CLASSES)
	$(PROFMAN) --create-profile-from=$(PRIVATE_PROFILE_CLASSES) --apk=$(PRIVATE_INSTALLED_MODULE) --dex-location=$(PRIVATE_DEX_LOCATION) --reference-profile-file=$@
endif

$(eval $(call copy-one-file,$(my_built_odex),$(my_installed_odex)))
$(eval $(call copy-one-file,$(my_built_vdex),$(my_installed_vdex)))

built_odex += $(my_built_odex)
built_vdex += $(my_built_vdex)

installed_odex += $(my_installed_odex)
installed_vdex += $(my_installed_vdex)

built_installed_odex += $(my_built_odex):$(my_installed_odex)
built_installed_vdex += $(my_built_vdex):$(my_installed_vdex)
