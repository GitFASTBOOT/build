#
# Copyright (C) 2015 The Android Open Source Project
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

# Notice: this feature is only for Googlers.
ifneq ($(USE_GOMA),)
  ifdef GOMA_DIR
    goma_dir := $(GOMA_DIR)
  else
    goma_dir := $(HOME)/goma
  endif
  goma_ctl := $(goma_dir)/goma_ctl.py
  $(if $(wildcard $(goma_ctl)),, \
   $(warning You should have goma in $$GOMA_DIR or $(HOME)/goma) \
   $(error See go/ma/how-to-use-goma/how-to-use-goma-for-android for detail))

  # Append gomacc to existing *_WRAPPER variables so it's possible to
  # use both ccache and gomacc.
  CC_WRAPPER += $(goma_dir)/gomacc
  CXX_WRAPPER += $(goma_dir)/gomacc
  # Ninja file generated by kati uses this for remote jobs (i.e.,
  # commands which contain gomacc). Note the parallelism of all other
  # jobs will be limited the number of cores.
  KATI_NINJA_NUM_JOBS := 500

  # gomacc can start goma client's daemon process automatically, but
  # it is safer and faster to start up it beforehand. We run this as a
  # background process so this won't slow down the build.
  $(shell $(goma_ctl) ensure_start &> /dev/null &)

  goma_dir :=
  goma_ctl :=
endif
