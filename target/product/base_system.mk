#
# Copyright (C) 2020 The Android Open Source Project
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

$(call inherit-product, $(SRC_TARGET_DIR)/product/minimal_system.mk)

# Base modules and settings for the system partition.
PRODUCT_PACKAGES += \
    am \
    android.hidl.allocator@1.0-service \
    android.hidl.base-V1.0-java \
    android.hidl.manager-V1.0-java \
    android.hidl.memory@1.0-impl \
    android.hidl.memory@1.0-impl.vendor \
    android.system.suspend@1.0-service \
    android.test.base \
    android.test.mock \
    android.test.runner \
    ANGLE \
    appops \
    app_process \
    appwidget \
    atrace \
    audioserver \
    BackupRestoreConfirmation \
    bcc \
    blank_screen \
    blkid \
    bmgr \
    bootanimation \
    bootstat \
    bpfloader \
    bu \
    bugreport \
    bugreportz \
    cgroups.json \
    charger \
    cmd \
    com.android.apex.cts.shim.v1 \
    com.android.cronet \
    com.android.i18n \
    com.android.ipsec \
    com.android.location.provider \
    com.android.media \
    com.android.media.swcodec \
    com.android.resolv \
    com.android.neuralnetworks \
    com.android.sdkext \
    com.android.tethering \
    com.android.tzdata \
    ContactsProvider \
    content \
    device_config \
    dmctl \
    dnsmasq \
    DownloadProvider \
    dpm \
    dumpstate \
    dumpsys \
    DynamicSystemInstallationService \
    e2fsck \
    ExtServices \
    ExtShared \
    flags_health_check \
    framework-minus-apex \
    framework-res \
    framework-sysconfig.xml \
    fsck_msdos \
    fsverity-release-cert-der \
    fs_config_files_system \
    fs_config_dirs_system \
    group_system \
    gsid \
    gsi_tool \
    heapprofd \
    heapprofd_client \
    gatekeeperd \
    gpuservice \
    hid \
    hwservicemanager \
    idmap \
    idmap2 \
    idmap2d \
    ime \
    ims-common \
    incident \
    incidentd \
    incident_helper \
    input \
    installd \
    iorapd \
    ip \
    iptables \
    ip-up-vpn \
    javax.obex \
    keystore \
    ld.mc \
    libaaudio \
    libamidi \
    libandroid \
    libandroidfw \
    libandroid_runtime \
    libandroid_servers \
    libartpalette-system \
    libaudioeffect_jni \
    libbinder_ndk \
    libcamera2ndk \
    libcutils \
    libdrmframework \
    libdrmframework_jni \
    libEGL \
    libETC1 \
    libfdtrack \
    libFFTEm \
    libfilterfw \
    libgatekeeper \
    libGLESv1_CM \
    libGLESv2 \
    libGLESv3 \
    libgui \
    libhardware \
    libhardware_legacy \
    libinput \
    libinputflinger \
    libiprouteutil \
    libjnigraphics \
    libjpeg \
    liblog \
    libmdnssd \
    libmedia \
    libmedia_jni \
    libmediandk \
    libmtp \
    libnetd_client \
    libnetlink \
    libnetutils \
    libneuralnetworks_packageinfo \
    libOpenMAXAL \
    libOpenSLES \
    libpdfium \
    libpixelflinger \
    libpower \
    libpowermanager \
    libradio_metadata \
    librtp_jni \
    libsensorservice \
    libsfplugin_ccodec \
    libskia \
    libsonic \
    libsonivox \
    libsoundpool \
    libspeexresampler \
    libsqlite \
    libstagefright \
    libstagefright_foundation \
    libstagefright_omx \
    libsurfaceflinger \
    libsysutils \
    libui \
    libusbhost \
    libutils \
    libvulkan \
    libwifi-service \
    libwilhelm \
    lmkd \
    LocalTransport \
    locksettings \
    lpdump \
    lshal \
    mdnsd \
    media \
    mediacodec.policy \
    mediadrmserver \
    mediaextractor \
    mediametrics \
    media_profiles_V1_0.dtd \
    MediaProvider \
    mediaserver \
    mke2fs \
    monkey \
    mtpd \
    ndc \
    netd \
    NetworkStackNext \
    org.apache.http.legacy \
    otacerts \
    PackageInstaller \
    passwd_system \
    perfetto \
    PermissionController \
    ping \
    ping6 \
    platform.xml \
    pm \
    pppd \
    privapp-permissions-platform.xml \
    racoon \
    recovery-persist \
    resize2fs \
    rss_hwm_reset \
    sanitizer.libraries.txt \
    schedtest \
    screencap \
    sdcard \
    secdiscard \
    SecureElement \
    sensorservice \
    service \
    services \
    settings \
    SettingsProvider \
    sgdisk \
    Shell \
    sm \
    snapshotctl \
    statsd \
    storaged \
    surfaceflinger \
    svc \
    task_profiles.json \
    tc \
    telecom \
    telephony-common \
    traced \
    traced_probes \
    tune2fs \
    tzdatacheck \
    uiautomator \
    uncrypt \
    usbd \
    vdc \
    viewcompiler \
    voip-common \
    WallpaperBackup \
    watchdogd \
    wificond \
    wifi-service \
    wm \

# VINTF data for system image
PRODUCT_PACKAGES += \
    system_manifest.xml \
    system_compatibility_matrix.xml \

# Host tools to install
PRODUCT_HOST_PACKAGES += \
    BugReport \
    art-tools \
    atest \
    bcc \
    bit \
    e2fsck \
    fastboot \
    flags_health_check \
    icu-data_host_i18n_apex \
    icu_tzdata.dat_host_tzdata_apex \
    idmap2 \
    incident_report \
    ld.mc \
    lpdump \
    mdnsd \
    minigzip \
    mke2fs \
    resize2fs \
    sgdisk \
    sqlite3 \
    tinyplay \
    tune2fs \
    tzdatacheck \
    unwind_info \
    unwind_reg_info \
    unwind_symbols \
    viewcompiler \
    tzdata_host \
    tzdata_host_tzdata_apex \
    tzlookup.xml_host_tzdata_apex \
    tz_version_host \
    tz_version_host_tzdata_apex \

ifeq ($(ART_APEX_JARS),)
$(error ART_APEX_JARS is empty; cannot initialize PRODUCT_BOOT_JARS variable)
endif

# The order matters for runtime class lookup performance.
PRODUCT_BOOT_JARS := \
    $(ART_APEX_JARS) \
    framework-minus-apex \
    ext \
    com.android.i18n:core-icu4j \
    telephony-common \
    voip-common \
    ims-common \

PRODUCT_UPDATABLE_BOOT_JARS := \
    com.android.conscrypt:conscrypt \
    com.android.media:updatable-media \
    com.android.sdkext:framework-sdkextensions \
    com.android.tethering:framework-tethering

# Add the compatibility library that is needed when android.test.base
# is removed from the bootclasspath.
# Default to excluding android.test.base from the bootclasspath.
ifneq ($(REMOVE_ATB_FROM_BCP),false)
PRODUCT_PACKAGES += framework-atb-backward-compatibility
PRODUCT_BOOT_JARS += framework-atb-backward-compatibility
else
PRODUCT_BOOT_JARS += android.test.base
endif

PRODUCT_COPY_FILES += system/core/rootdir/init.zygote32.rc:system/etc/init/hw/init.zygote32.rc
PRODUCT_SYSTEM_PROPERTIES += ro.zygote?=zygote32

# Packages included only for eng or userdebug builds, previously debug tagged
PRODUCT_PACKAGES_DEBUG += \
    adb_keys \
    arping \
    gdbserver \
    idlcli \
    init-debug.rc \
    iotop \
    iperf3 \
    iw \
    logpersist.start \
    logtagd.rc \
    procrank \
    remount \
    showmap \
    sqlite3 \
    ss \
    start_with_lockagent \
    sanitizer-status \
    tracepath \
    tracepath6 \
    traceroute6 \
    unwind_info \
    unwind_reg_info \
    unwind_symbols \

# The set of packages whose code can be loaded by the system server.
PRODUCT_SYSTEM_SERVER_APPS += \
    SettingsProvider \
    WallpaperBackup

# Packages included only for eng/userdebug builds, when building with SANITIZE_TARGET=address
PRODUCT_PACKAGES_DEBUG_ASAN := \
    fuzz \
    honggfuzz

PRODUCT_PACKAGES_DEBUG_JAVA_COVERAGE := \
    libdumpcoverage

PRODUCT_COPY_FILES += $(call add-to-product-copy-files-if-exists,\
    frameworks/base/config/preloaded-classes:system/etc/preloaded-classes)

# Note: it is acceptable to not have a dirty-image-objects file. In that case, the special bin
#       for known dirty objects in the image will be empty.
PRODUCT_COPY_FILES += $(call add-to-product-copy-files-if-exists,\
    frameworks/base/config/dirty-image-objects:system/etc/dirty-image-objects)

$(call inherit-product, $(SRC_TARGET_DIR)/product/runtime_libart.mk)
