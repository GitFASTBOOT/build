#!/bin/bash

partition="$1"

echo "# begin ${partition} common build properties"
echo "# autogenerated by common_buildinfo.sh"

echo "ro.${partition}.build.date=`$DATE`"
echo "ro.${partition}.build.date.utc=`$DATE +%s`"
echo "ro.${partition}.build.fingerprint=$BUILD_FINGERPRINT"
echo "ro.${partition}.build.id=$BUILD_ID"
echo "ro.${partition}.build.tags=$BUILD_VERSION_TAGS"
echo "ro.${partition}.build.type=$TARGET_BUILD_TYPE"
echo "ro.${partition}.build.version.incremental=$BUILD_NUMBER"
echo "ro.${partition}.build.version.release=$PLATFORM_VERSION"
echo "ro.${partition}.build.version.sdk=$PLATFORM_SDK_VERSION"

echo "# end ${partition} common build properties"
