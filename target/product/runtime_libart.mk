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

# Provides a functioning ART environment without Android frameworks

ifeq ($(TARGET_CORE_JARS),)
$(error TARGET_CORE_JARS is empty; cannot update PRODUCT_PACKAGES variable)
endif

# Minimal boot classpath. This should be a subset of PRODUCT_BOOT_JARS, and equivalent to
# TARGET_CORE_JARS.
PRODUCT_PACKAGES += \
    $(TARGET_CORE_JARS)

# Additional mixins to the boot classpath.
PRODUCT_PACKAGES += \
    android.test.base \

# Why are we pulling in ext, which is frameworks/base, depending on tagsoup and nist-sip?
PRODUCT_PACKAGES += \
    ext \

# Runtime (Bionic) APEX module.
PRODUCT_PACKAGES += com.android.runtime

# ART APEX module.

# The ART APEX comes in three flavors:
# - the release module (`com.android.art.release`) containing only
#   "release" artifacts, included by default in "user" builds;
RELEASE_ART_APEX := com.android.art.release
# - the debug module (`com.android.art.debug`), containing both
#   "release" and "debug" artifacts as well as additional tools,
#   included by default in "userdebug" and "eng" builds and used in
#   ART device benchmarking;
DEBUG_ART_APEX := com.android.art.debug
# - the testing module (`com.android.art.testing`), containing both
#   "release" and "debug" artifacts as well as additional tools and
#   ART gtests, used in ART device testing.
TESTING_ART_APEX := com.android.art.testing

# The ART APEX module (`com.android.art`) is an "alias" for either the
# release or the debug module. By default, "user" build variants contain
# the release module, while "userdebug" and "eng" build variants contain
# the debug module. However, if `PRODUCT_ART_TARGET_INCLUDE_DEBUG_BUILD`
# is defined, it overrides the previous logic:
# - if `PRODUCT_ART_TARGET_INCLUDE_DEBUG_BUILD` is set to `false`, the
#   build will include the release module (whatever the build
#   variant);
# - if `PRODUCT_ART_TARGET_INCLUDE_DEBUG_BUILD` is set to `true`, the
#   build will include the debug module (whatever the build variant).

art_target_include_debug_build := $(PRODUCT_ART_TARGET_INCLUDE_DEBUG_BUILD)
ifneq (false,$(art_target_include_debug_build))
  ifneq (,$(filter userdebug eng,$(TARGET_BUILD_VARIANT)))
    art_target_include_debug_build := true
  endif
endif
ifeq (true,$(art_target_include_debug_build))
  # Module with both release and debug variants, as well as
  # additional tools.
  TARGET_ART_APEX := $(DEBUG_ART_APEX)
  APEX_TEST_MODULE := art-check-debug-apex-gen-fakebin
else
  # Release module (without debug variants nor tools).
  TARGET_ART_APEX := $(RELEASE_ART_APEX)
  APEX_TEST_MODULE := art-check-release-apex-gen-fakebin
endif

# Clear locally used variable.
art_target_include_debug_build :=

# See art/Android.mk for the definition of the com.android.art module.
PRODUCT_PACKAGES += com.android.art
PRODUCT_HOST_PACKAGES += com.android.art

# Certificates.
PRODUCT_PACKAGES += \
    cacerts \

PRODUCT_PACKAGES += \
    hiddenapi-package-whitelist.xml \

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    dalvik.vm.image-dex2oat-Xms=64m \
    dalvik.vm.image-dex2oat-Xmx=64m \
    dalvik.vm.dex2oat-Xms=64m \
    dalvik.vm.dex2oat-Xmx=512m \
    dalvik.vm.usejit=true \
    dalvik.vm.usejitprofiles=true \
    dalvik.vm.dexopt.secondary=true \
    dalvik.vm.appimageformat=lz4

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.dalvik.vm.native.bridge=0

# Different dexopt types for different package update/install times.
# On eng builds, make "boot" reasons only extract for faster turnaround.
ifeq (eng,$(TARGET_BUILD_VARIANT))
    PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
        pm.dexopt.first-boot=extract \
        pm.dexopt.boot=extract
else
    PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
        pm.dexopt.first-boot=quicken \
        pm.dexopt.boot=verify
endif

# The install filter is speed-profile in order to enable the use of
# profiles from the dex metadata files. Note that if a profile is not provided
# or if it is empty speed-profile is equivalent to (quicken + empty app image).
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    pm.dexopt.install=speed-profile \
    pm.dexopt.bg-dexopt=speed-profile \
    pm.dexopt.ab-ota=speed-profile \
    pm.dexopt.inactive=verify \
    pm.dexopt.shared=speed

# Enable resolution of startup const strings.
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    dalvik.vm.dex2oat-resolve-startup-strings=true

# Specify default block size of 512K to enable parallel image decompression.
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    dalvik.vm.dex2oat-max-image-block-size=524288

# Enable minidebuginfo generation unless overridden.
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    dalvik.vm.minidebuginfo=true \
    dalvik.vm.dex2oat-minidebuginfo=true

# Disable iorapd by default
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.iorapd.enable=false

PRODUCT_USES_DEFAULT_ART_CONFIG := true
