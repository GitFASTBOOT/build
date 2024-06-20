#
# Copyright (C) 2013 The Android Open Source Project
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

include $(SRC_TARGET_DIR)/product/generic_kernel.mk

ifdef BUILD_WITH_KERNEL

# Keep prebuilt
PRODUCT_COPY_FILES += \
    kernel/prebuilts/mainline/arm64/kernel-mainline-allsyms:kernel-mainline \
    kernel/prebuilts/mainline/arm64/kernel-mainline-gz-allsyms:kernel-mainline-gz \
    kernel/prebuilts/mainline/arm64/kernel-mainline-lz4-allsyms:kernel-mainline-lz4 \

PRODUCT_COPY_FILES += \
    $(OUT_DIR)/target/kernel/5.10/arm64/kernel-5.10:kernel-5.10 \
    $(OUT_DIR)/target/kernel/5.10/arm64/kernel-5.10-gz:kernel-5.10-gz \
    $(OUT_DIR)/target/kernel/5.10/arm64/kernel-5.10-lz4:kernel-5.10-lz4 \

ifneq (,$(filter userdebug eng,$(TARGET_BUILD_VARIANT)))
PRODUCT_COPY_FILES += \
    $(OUT_DIR)/target/kernel/5.10/arm64/kernel-5.10-allsyms:kernel-5.10-allsyms \
    $(OUT_DIR)/target/kernel/5.10/arm64/kernel-5.10-gz-allsyms:kernel-5.10-gz-allsyms \
    $(OUT_DIR)/target/kernel/5.10/arm64/kernel-5.10-lz4-allsyms:kernel-5.10-lz4-allsyms \

endif

else # BUILD_WITH_KERNEL

PRODUCT_COPY_FILES += \
    kernel/prebuilts/5.10/arm64/kernel-5.10:kernel-5.10 \
    kernel/prebuilts/5.10/arm64/kernel-5.10-gz:kernel-5.10-gz \
    kernel/prebuilts/5.10/arm64/kernel-5.10-lz4:kernel-5.10-lz4 \

$(call _output-kernel-info,kernel/prebuilts/5.10/arm64,kernel/5.10)

ifneq (,$(filter userdebug eng,$(TARGET_BUILD_VARIANT)))
PRODUCT_COPY_FILES += \
    kernel/prebuilts/5.10/arm64/kernel-5.10-allsyms:kernel-5.10-allsyms \
    kernel/prebuilts/5.10/arm64/kernel-5.10-gz-allsyms:kernel-5.10-gz-allsyms \
    kernel/prebuilts/5.10/arm64/kernel-5.10-lz4-allsyms:kernel-5.10-lz4-allsyms \

$(call _output-kernel-info-debug,kernel/prebuilts/5.10/arm64,kernel/5.10-debug)

endif

endif # BUILD_WITH_KERNEL

PRODUCT_BUILD_VENDOR_BOOT_IMAGE := false
PRODUCT_BUILD_RECOVERY_IMAGE := false

$(call inherit-product, $(SRC_TARGET_DIR)/product/generic_ramdisk.mk)
