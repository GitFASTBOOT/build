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

LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

LOCAL_SRC_FILES := check_prereq.c
LOCAL_MODULE := check_prereq
LOCAL_FORCE_STATIC_EXECUTABLE := true
LOCAL_MODULE_TAGS := eng
LOCAL_C_INCLUDES +=
LOCAL_STATIC_LIBRARIES += libcutils libc
ifeq (true,$(TARGET_PREFER_32_BIT_EXECUTABLES))
# We are doing a 32p build, force recovery to be 64bit
LOCAL_MULTILIB := 64
endif

include $(BUILD_EXECUTABLE)
