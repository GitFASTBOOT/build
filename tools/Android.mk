#
# Copyright (C) 2010 The Android Open Source Project
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

ifeq (,$(TARGET_BUILD_APPS))

ifeq ($(TARGET_BUILD_PDK),true)
include $(filter-out %/acp/Android.mk %/signapk/Android.mk %/zipalign/Android.mk,\
  $(call all-makefiles-under,$(LOCAL_PATH)))
else # !PDK
include $(call all-makefiles-under,$(LOCAL_PATH))
endif # PDK

else # TARGET_BUILD_APPS

# TODO(hamaji): Add $(LOCAL_PATH)/dextoc/Android.mk once b/25904002 is fixed.
include $(LOCAL_PATH)/apicheck/Android.mk

endif
