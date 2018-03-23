# config.mk
#
# Product-specific compile-time definitions.
#

include build/make/target/board/treble_common.mk

TARGET_CPU_ABI := x86
TARGET_ARCH := x86
TARGET_ARCH_VARIANT := x86
TARGET_PRELINK_MODULE := false
TARGET_BOOTLOADER_BOARD_NAME := goldfish_$(TARGET_ARCH)

#emulator now uses 64bit kernel to run 32bit x86 image
#
TARGET_USES_64_BIT_BINDER := true

# The IA emulator (qemu) uses the Goldfish devices
HAVE_HTC_AUDIO_DRIVER := true
BOARD_USES_GENERIC_AUDIO := true

# no hardware camera
USE_CAMERA_STUB := true

# Build OpenGLES emulation host and guest libraries
BUILD_EMULATOR_OPENGL := true

# Build partitioned system.img and vendor.img (if applicable)
# for qemu, otherwise, init cannot find PART_NAME
BUILD_QEMU_IMAGES := true

# Build and enable the OpenGL ES View renderer. When running on the emulator,
# the GLES renderer disables itself if host GL acceleration isn't available.
USE_OPENGL_RENDERER := true

TARGET_USERIMAGES_USE_EXT4 := true
# 1.0 GB system image, 64 MB vendor image. Adjust them when needed.
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 1073741824
BOARD_USERDATAIMAGE_PARTITION_SIZE := 576716800
BOARD_PROPERTY_OVERRIDES_SPLIT_ENABLED := true
BOARD_VENDORIMAGE_PARTITION_SIZE := 67108864
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_FLASH_BLOCK_SIZE := 512
TARGET_USERIMAGES_SPARSE_EXT_DISABLED := true
DEVICE_MATRIX_FILE   := device/generic/goldfish/compatibility_matrix.xml

BOARD_SEPOLICY_DIRS += \
        build/target/board/generic/sepolicy \
        build/target/board/generic_x86/sepolicy

BOARD_VNDK_VERSION := current

# Enable A/B update
TARGET_NO_RECOVERY := true
BOARD_BUILD_SYSTEM_ROOT_IMAGE := true
