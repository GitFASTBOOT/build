#
# Copyright (C) 2009 The Android Open Source Project
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

# This is a build configuration for a full-featured build of the
# Open-Source part of the tree. It's geared toward a US-centric
# build quite specifically for the emulator, and might not be
# entirely appropriate to inherit from for on-device configurations.

PRODUCT_COPY_FILES += \
    development/sys-img/advancedFeatures.ini:advancedFeatures.ini \
    device/generic/goldfish/data/etc/encryptionkey.img:encryptionkey.img \
    device/generic/goldfish/fstab.ranchu:root/fstab.ranchu \
    device/generic/goldfish/fstab.ranchu.early:root/fstab.ranchu.early \
    prebuilts/qemu-kernel/x86_64/3.18/kernel-qemu2:kernel-ranchu

$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/sdk_base.mk)

# AOSP emulator images build the AOSP messaging app.
# Google API images override with the Google API app.
# See vendor/google/products/sdk_google_phone_*.mk
PRODUCT_PACKAGES += \
    messaging

# Overrides
PRODUCT_BRAND := Android
PRODUCT_NAME := sdk_phone_x86_64
PRODUCT_DEVICE := generic_x86_64
PRODUCT_MODEL := Android SDK built for x86_64
