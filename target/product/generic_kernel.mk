#
# Copyright (C) 2021 The Android Open Source Project
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

_output-kernel-info-files := \
    prebuilt-info.txt \
    manifest.xml \

# Output the release kernel prebuilt files to dist folder
#
# $(1): the source folder contains the kernel prebuilt files
# $(2): the dist folder
define _output-kernel-user
$(if $(findstring mainline,$(1)), \
  $(foreach file,$(wildcard $(1)/kernel-*-allsyms), \
    $(eval PRODUCT_COPY_FILES += $(file):$(subst -allsyms,,$(notdir $(file))))), \
  $(foreach file,$(wildcard $(1)/kernel-*), \
    $(if $(findstring -allsyms,$(file)),, \
      $(eval PRODUCT_COPY_FILES += $(file):$(notdir $(file))))))

$(foreach file,$(_output-kernel-info-files), \
  $(if $(wildcard $(1)/$(file)), \
    $(call dist-for-goals,dist_files,$(1)/$(file):$(2)/$(file))))
endef


_output-kernel-info-files-debug := \
    prebuilt-info.txt:prebuilt-info.txt \
    manifest.xml:manifest.xml \

# Output the debug kernel prebuilt files to dist folder
#
# $(1): the source folder contains the kernel prebuilt files
# $(2): the dist folder
define _output-kernel-debug
$(if $(findstring mainline,$(1)),, \
  $(foreach file,$(wildcard $(1)/kernel-*), \
    $(if $(findstring -allsyms,$(file)), \
      $(eval PRODUCT_COPY_FILES += $(file):$(notdir $(file))))))

$(foreach file,$(_output-kernel-info-files-debug), \
  $(eval _src := $(call word-colon,1,$(file))) \
  $(eval _dst := $(call word-colon,2,$(file))) \
  $(if $(wildcard $(1)/$(_src)), \
    $(call dist-for-goals,dist_files,$(1)/$(_src):$(2)/$(_dst))))
endef


# Output the kernel prebuilt files to dist folder
#
# $(1): the source folder contains the kernel prebuilt files
# $(2): the dist folder
define _output-kernel
$(call _output-kernel-user,$(1),$(2))
$(if $(filter userdebug eng,$(TARGET_BUILD_VARIANT)), \
  $(call _output-kernel-debug,$(1),$(2)))
endef
