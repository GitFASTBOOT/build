#
# Copyright (C) 2023 The Android Open Source Project
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

# This file is executed by build/envsetup.sh, and can use anything
# defined in envsetup.sh.
function _create_out_symlink_for_cog() {
  if [[ "${OUT_DIR}" == "" ]]; then
    OUT_DIR="out"
  fi

  if [[ -L "${OUT_DIR}" ]]; then
    return
  fi
  if [ -d "${OUT_DIR}" ]; then
    echo "Output directory ${OUT_DIR} cannot be present in a Cog workspace."
    echo "Delete \"${OUT_DIR}\" or create a symlink from \"${OUT_DIR}\" to a path that points to a directory outside your workspace."
    return 1
  fi

  DEFAULT_OUTPUT_DIR="${HOME}/.cog/android-build-out"
  mkdir -p ${DEFAULT_OUTPUT_DIR}
  ln -s ${DEFAULT_OUTPUT_DIR} `pwd`/out
}

# This function moves the reclient binaries into a directory that exists in a
# non-cog part of the overall filesystem.  This is to workaround the problem
# described in b/289391270.
function _copy_reclient_binaries_from_cog() {
  local NONCOG_RECLIENT_BIN_DIR="${HOME}/.cog/reclient/bin"
  if [ ! -d "$NONCOG_RECLIENT_BIN_DIR" ]; then
    # Create the non cog directory if it doesn't exist.
    mkdir -p ${NONCOG_RECLIENT_BIN_DIR}
  else
    # Clear out the non cog directory if it does exist.
    rm -f ${NONCOG_RECLIENT_BIN_DIR}/*
  fi

  local TOP=$(gettop)

  # Copy the binaries out of live.
  cp $TOP/prebuilts/remoteexecution-client/live/* $NONCOG_RECLIENT_BIN_DIR

  # Finally set the RBE_DIR env var to point to the out-of-cog directory.
  export RBE_DIR=$NONCOG_RECLIENT_BIN_DIR
}

# This function sets up the build environment to be appropriate for Cog.
function _setup_cog_env() {
  _create_out_symlink_for_cog
  _copy_reclient_binaries_from_cog

  export ANDROID_BUILD_ENVIRONMENT_CONFIG="googler-cog"

  # Running repo command within Cog workspaces is not supported, so override
  # it with this function. If the user is running repo within a Cog workspace,
  # we'll fail with an error, otherwise, we run the original repo command with
  # the given args.
  ORIG_REPO_PATH=`which repo`
  function repo {
    if [[ "${PWD}" == /google/cog/* ]]; then
      echo "\e[01;31mERROR:\e[0mrepo command is disallowed within Cog workspaces."
      return 1
    fi
    ${ORIG_REPO_PATH} "$@"
  }
}

if [[ "${PWD}" != /google/cog/* ]]; then
  echo -e "\e[01;31mERROR:\e[0m This script must be run from a Cog workspace."
fi

_setup_cog_env