#
# Copyright (C) 2016 The Android Open Source Project
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
LOCAL_PATH := $(call my-dir)

# apksigner library, for signing APKs and verification signatures of APKs
# ============================================================
include $(CLEAR_VARS)
LOCAL_MODULE := apksigner-core
LOCAL_SRC_FILES := $(call all-java-files-under, src)

# Disable warnnings about our use of internal proprietary OpenJDK API.
# TODO: Remove this workaround by moving to our own implementation of PKCS #7
# SignedData block generation, parsing, and verification.
LOCAL_JAVACFLAGS := -XDignore.symbol.file

include $(BUILD_HOST_JAVA_LIBRARY)
