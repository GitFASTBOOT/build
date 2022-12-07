#!/bin/bash

set -ex

function finalize_aidl_vndk_sdk_resources() {
    local PLATFORM_CODENAME_JAVA='UPSIDE_DOWN_CAKE'
    local PLATFORM_SDK_VERSION='34'

    local top="$(dirname "$0")"/../..

    # default target to modify tree and build SDK
    local m="$top/build/soong/soong_ui.bash --make-mode TARGET_PRODUCT=aosp_arm64 TARGET_BUILD_VARIANT=userdebug"

    # This script is WIP and only finalizes part of the Android branch for release.
    # The full process can be found at (INTERNAL) go/android-sdk-finalization.

    # Update references in the codebase to new API version (TODO)
    # ...

    # VNDK definitions for new SDK version
    cp "$top/development/vndk/tools/definition-tool/datasets/vndk-lib-extra-list-current.txt" \
       "$top/development/vndk/tools/definition-tool/datasets/vndk-lib-extra-list-$PLATFORM_SDK_VERSION.txt"

    AIDL_TRANSITIVE_FREEZE=true $m aidl-freeze-api create_reference_dumps

    # Generate ABI dumps
    ANDROID_BUILD_TOP="$top" \
        out/host/linux-x86/bin/create_reference_dumps \
        -p aosp_arm64 --build-variant user

    echo "NOTE: THIS INTENTIONALLY MAY FAIL AND REPAIR ITSELF (until 'DONE')"
    # Update new versions of files. See update-vndk-list.sh (which requires envsetup.sh)
    $m check-vndk-list || \
        { cp $top/out/soong/vndk/vndk.libraries.txt $top/build/make/target/product/gsi/current.txt; }
    echo "DONE: THIS INTENTIONALLY MAY FAIL AND REPAIR ITSELF"

    # Finalize resources
    "$top/frameworks/base/tools/aapt2/tools/finalize_res.py" \
           "$top/frameworks/base/core/res/res/values/public-staging.xml" \
           "$top/frameworks/base/core/res/res/values/public-final.xml"

    # SDK finalization
    local sdk_codename="public static final int $PLATFORM_CODENAME_JAVA = CUR_DEVELOPMENT;"
    local sdk_version="public static final int $PLATFORM_CODENAME_JAVA = $PLATFORM_SDK_VERSION;"
    local sdk_build="$top/frameworks/base/core/java/android/os/Build.java"

    sed -i "s%$sdk_codename%$sdk_version%g" $sdk_build

    # Force update current.txt
    $m clobber
    $m update-api
}

finalize_aidl_vndk_sdk_resources

