#
# Copyright 2018 The Android Open Source Project
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

# Use an empty profile to make non of the boot image be AOT compiled (for now).
# Note that we could use a previous profile but we will miss the opportunity to
# remove classes that are no longer in use.
# Ideally we would just generate an empty boot.art but we don't have the build
# support to separate the image from the compile code.
PRODUCT_DEX_PREOPT_BOOT_IMAGE_PROFILE_LOCATION := build/make/target/product/empty-profile
DEX_PREOPT_DEFAULT := nostripping

# Boot image property overrides.
PRODUCT_PROPERTY_OVERRIDES += \
    dalvik.vm.profilesystemserver=true \
    dalvik.vm.profilebootclasspath=true

PRODUCT_DIST_BOOT_AND_SYSTEM_JARS := true
