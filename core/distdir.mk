#
# Copyright (C) 2007 The Android Open Source Project
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

# When specifying "dist", the user has asked that we copy the important
# files from this build into DIST_DIR.

# list of all goals that depend on any dist files
_all_dist_goals :=
# pairs of goal:distfile
_all_dist_goal_output_pairs :=
# pairs of srcfile:distfile
_all_dist_src_dst_pairs :=

# Other parts of the system should use this function to associate
# certain files with certain goals.  When those goals are built
# and "dist" is specified, the marked files will be copied to DIST_DIR.
#
# $(1): a list of goals  (e.g. droid, sdk, ndk). These must be PHONY
# $(2): the dist files to add to those goals.  If the file contains ':',
#       the text following the colon is the name that the file is copied
#       to under the dist directory.  Subdirs are ok, and will be created
#       at copy time if necessary.
define dist-for-goals
$(if $(strip $(2)), \
  $(eval _all_dist_goals += $$(1))) \
$(foreach file,$(2), \
  $(eval src := $(call word-colon,1,$(file))) \
  $(eval dst := $(call word-colon,2,$(file))) \
  $(if $(dst),,$(eval dst := $$(notdir $$(src)))) \
  $(eval _all_dist_src_dst_pairs += $$(src):$$(dst)) \
  $(foreach goal,$(1), \
    $(eval _all_dist_goal_output_pairs += $$(goal):$$(dst))))
endef

.PHONY: shareprojects
#shareprojects:

define __share-projects-rule
$(1) : PRIVATE_TARGETS := $(2)
$(1) : PRIVATE_ARGUMENT_FILE := $(call intermediates-dir-for,PACKAGING,codesharing)/$(1)/arguments
$(1): $(2) $(COMPLIANCE_LISTSHARE)
	$(hide) rm -f $$@
	mkdir -p $$(dir $$@)
	mkdir -p $$(dir $$(PRIVATE_ARGUMENT_FILE))
ifeq (,$(strip $(2)))
	touch $$@
else
	$$(call dump-words-to-file,$$(PRIVATE_TARGETS),$$(PRIVATE_ARGUMENT_FILE))
	OUT_DIR=$(OUT_DIR) $(COMPLIANCE_LISTSHARE) -o $$@ @$$(PRIVATE_ARGUMENT_FILE)
endif
endef

# build list of projects to share in $(1) for dist targets in $(2)
#
# $(1): the intermediate project sharing file
# $(2): the dist files to base the sharing on
define _share-projects-rule
$(eval $(call __share-projects-rule,$(1),$(call corresponding-license-metadata,$(2))))
endef

# Add a build dependency
#
# $(1): the goal phony target
# $(2): the intermediate shareprojects file
define _share-projects-dep
$(1): $(2)
endef

define _add_projects_to_share
$(strip $(eval _idir := $(call intermediates-dir-for,PACKAGING,shareprojects))) \
$(strip $(eval _goals := $(sort $(_all_dist_goals)))) \
$(strip $(eval _opairs := $(sort $(_all_dist_goal_output_pairs)))) \
$(strip $(eval _dpairs := $(sort $(_all_dist_src_dst_pairs)))) \
$(strip $(eval _allt :=)) \
$(foreach goal,$(_goals), \
  $(eval _f := $(_idir)/$(goal).shareprojects) \
  $(call dist-for-goals,$(goal),$(_f):shareprojects/$(basename $(notdir $(_f)))) \
  $(eval _targets :=) \
  $(foreach op,$(filter $(goal):%,$(_opairs)),$(foreach p,$(filter %:$(call word-colon,2,$(op)),$(_dpairs)),$(eval _targets += $(call word-colon,1,$(p))))) \
  $(eval _allt += $(_targets)) \
  $(eval $(call _share-projects-rule,$(_f),$(_targets))) \
)\
$(eval _f := $(_idir)/all.shareprojects)\
$(eval $(call _share-projects-dep,shareprojects,$(_f))) \
$(call dist-for-goals,droid shareprojects,$(_f):shareprojects/all)\
$(eval $(call _share-projects-rule,$(_f),$(sort $(_allt))))
endef

#------------------------------------------------------------------
# To be used at the end of the build to collect all the uses of
# dist-for-goals, and write them into a file for the packaging step to use.

# $(1): The file to write
define dist-write-file
$(strip \
  $(call _add_projects_to_share)\
  $(if $(strip $(ANDROID_REQUIRE_LICENSE_METADATA)),\
    $(if $(strip $(ANDROID_REQUIRE_LICENSE_METADATA)),\
      $(foreach target,$(sort $(TARGETS_MISSING_LICENSE_METADATA)),$(warning target $(target) missing license metadata)))\
    $(if $(strip $(TARGETS_MISSING_LICENSE_METADATA)),\
      $(if $(filter true error,$(ANDROID_REQUIRE_LICENSE_METADATA)),\
        $(error $(words $(sort $(TARGETS_MISSING_LICENSE_METADATA))) targets need license metadata))))\
  $(foreach t,$(sort $(ALL_NON_MODULES)),$(call record-missing-non-module-dependencies,$(t))) \
  $(eval $(call report-missing-licenses-rule)) \
  $(eval $(call report-all-notice-library-names-rule)) \
  $(KATI_obsolete_var dist-for-goals,Cannot be used after dist-write-file) \
  $(foreach goal,$(sort $(_all_dist_goals)), \
    $(eval $$(goal): _dist_$$(goal))) \
  $(shell mkdir -p $(dir $(1))) \
  $(file >$(1).tmp, \
    DIST_GOAL_OUTPUT_PAIRS := $(sort $(_all_dist_goal_output_pairs)) \
    $(newline)DIST_SRC_DST_PAIRS := $(sort $(_all_dist_src_dst_pairs))) \
  $(shell if ! cmp -s $(1).tmp $(1); then \
            mv $(1).tmp $(1); \
          else \
            rm $(1).tmp; \
          fi))
endef

.KATI_READONLY := dist-for-goals dist-write-file
