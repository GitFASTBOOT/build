<<<<<<< HEAD   (3619c8 Merge "Merge empty history for sparse-7625297-L4670000095071)
=======
# python3
"""Clang_Tidy_Warn Project List data for Chrome.

This file stores the Chrome project_list used in warn.py and
its dependencies. It has been put into this file for easier navigation and
unification of the Chrome and Android warn.py.
"""


def create_pattern(pattern):
  """Return a tuple of name and warn patten."""
  return [pattern, '(^|.*/)' + pattern + '/.*: warning:']


# A list of [project_name, file_path_pattern].
project_list = [
    create_pattern('android_webview'),
    create_pattern('apps'),
    create_pattern('ash/app_list'),
    create_pattern('ash/public'),
    create_pattern('ash/assistant'),
    create_pattern('ash/display'),
    create_pattern('ash/resources'),
    create_pattern('ash/login'),
    create_pattern('ash/system'),
    create_pattern('ash/wm'),
    create_pattern('ash/shelf'),
    create_pattern('ash'),
    create_pattern('base/trace_event'),
    create_pattern('base/debug'),
    create_pattern('base/third_party'),
    create_pattern('base/files'),
    create_pattern('base/test'),
    create_pattern('base/util'),
    create_pattern('base/task'),
    create_pattern('base/metrics'),
    create_pattern('base/strings'),
    create_pattern('base/memory'),
    create_pattern('base'),
    create_pattern('build'),
    create_pattern('build_overrides'),
    create_pattern('buildtools'),
    create_pattern('cc'),
    create_pattern('chrome/services'),
    create_pattern('chrome/app'),
    create_pattern('chrome/renderer'),
    create_pattern('chrome/test'),
    create_pattern('chrome/common/safe_browsing'),
    create_pattern('chrome/common/importer'),
    create_pattern('chrome/common/media_router'),
    create_pattern('chrome/common/extensions'),
    create_pattern('chrome/common'),
    create_pattern('chrome/browser/sync_file_system'),
    create_pattern('chrome/browser/safe_browsing'),
    create_pattern('chrome/browser/download'),
    create_pattern('chrome/browser/ui'),
    create_pattern('chrome/browser/supervised_user'),
    create_pattern('chrome/browser/search'),
    create_pattern('chrome/browser/browsing_data'),
    create_pattern('chrome/browser/predictors'),
    create_pattern('chrome/browser/net'),
    create_pattern('chrome/browser/devtools'),
    create_pattern('chrome/browser/resource_coordinator'),
    create_pattern('chrome/browser/page_load_metrics'),
    create_pattern('chrome/browser/extensions'),
    create_pattern('chrome/browser/ssl'),
    create_pattern('chrome/browser/printing'),
    create_pattern('chrome/browser/profiles'),
    create_pattern('chrome/browser/chromeos'),
    create_pattern('chrome/browser/performance_manager'),
    create_pattern('chrome/browser/metrics'),
    create_pattern('chrome/browser/component_updater'),
    create_pattern('chrome/browser/media'),
    create_pattern('chrome/browser/notifications'),
    create_pattern('chrome/browser/web_applications'),
    create_pattern('chrome/browser/media_galleries'),
    create_pattern('chrome/browser'),
    create_pattern('chrome'),
    create_pattern('chromecast'),
    create_pattern('chromeos/services'),
    create_pattern('chromeos/dbus'),
    create_pattern('chromeos/assistant'),
    create_pattern('chromeos/components'),
    create_pattern('chromeos/settings'),
    create_pattern('chromeos/constants'),
    create_pattern('chromeos/network'),
    create_pattern('chromeos'),
    create_pattern('cloud_print'),
    create_pattern('components/crash'),
    create_pattern('components/subresource_filter'),
    create_pattern('components/invalidation'),
    create_pattern('components/autofill'),
    create_pattern('components/onc'),
    create_pattern('components/arc'),
    create_pattern('components/safe_browsing'),
    create_pattern('components/services'),
    create_pattern('components/cast_channel'),
    create_pattern('components/download'),
    create_pattern('components/feed'),
    create_pattern('components/offline_pages'),
    create_pattern('components/bookmarks'),
    create_pattern('components/cloud_devices'),
    create_pattern('components/mirroring'),
    create_pattern('components/spellcheck'),
    create_pattern('components/viz'),
    create_pattern('components/gcm_driver'),
    create_pattern('components/ntp_snippets'),
    create_pattern('components/translate'),
    create_pattern('components/search_engines'),
    create_pattern('components/background_task_scheduler'),
    create_pattern('components/signin'),
    create_pattern('components/chromeos_camera'),
    create_pattern('components/reading_list'),
    create_pattern('components/assist_ranker'),
    create_pattern('components/payments'),
    create_pattern('components/feedback'),
    create_pattern('components/ui_devtools'),
    create_pattern('components/password_manager'),
    create_pattern('components/omnibox'),
    create_pattern('components/content_settings'),
    create_pattern('components/dom_distiller'),
    create_pattern('components/nacl'),
    create_pattern('components/metrics'),
    create_pattern('components/policy'),
    create_pattern('components/optimization_guide'),
    create_pattern('components/exo'),
    create_pattern('components/update_client'),
    create_pattern('components/data_reduction_proxy'),
    create_pattern('components/sync'),
    create_pattern('components/drive'),
    create_pattern('components/variations'),
    create_pattern('components/history'),
    create_pattern('components/webcrypto'),
    create_pattern('components'),
    create_pattern('content/public'),
    create_pattern('content/renderer'),
    create_pattern('content/test'),
    create_pattern('content/common'),
    create_pattern('content/browser'),
    create_pattern('content/zygote'),
    create_pattern('content'),
    create_pattern('courgette'),
    create_pattern('crypto'),
    create_pattern('dbus'),
    create_pattern('device/base'),
    create_pattern('device/vr'),
    create_pattern('device/gamepad'),
    create_pattern('device/test'),
    create_pattern('device/fido'),
    create_pattern('device/bluetooth'),
    create_pattern('device'),
    create_pattern('docs'),
    create_pattern('extensions/docs'),
    create_pattern('extensions/components'),
    create_pattern('extensions/buildflags'),
    create_pattern('extensions/renderer'),
    create_pattern('extensions/test'),
    create_pattern('extensions/common'),
    create_pattern('extensions/shell'),
    create_pattern('extensions/browser'),
    create_pattern('extensions/strings'),
    create_pattern('extensions'),
    create_pattern('fuchsia'),
    create_pattern('gin'),
    create_pattern('google_apis'),
    create_pattern('google_update'),
    create_pattern('gpu/perftests'),
    create_pattern('gpu/GLES2'),
    create_pattern('gpu/command_buffer'),
    create_pattern('gpu/tools'),
    create_pattern('gpu/gles2_conform_support'),
    create_pattern('gpu/ipc'),
    create_pattern('gpu/khronos_glcts_support'),
    create_pattern('gpu'),
    create_pattern('headless'),
    create_pattern('infra'),
    create_pattern('ipc'),
    create_pattern('jingle'),
    create_pattern('media'),
    create_pattern('mojo'),
    create_pattern('native_client'),
    create_pattern('ative_client_sdk'),
    create_pattern('net'),
    create_pattern('out'),
    create_pattern('pdf'),
    create_pattern('ppapi'),
    create_pattern('printing'),
    create_pattern('remoting'),
    create_pattern('rlz'),
    create_pattern('sandbox'),
    create_pattern('services/audio'),
    create_pattern('services/content'),
    create_pattern('services/data_decoder'),
    create_pattern('services/device'),
    create_pattern('services/file'),
    create_pattern('services/identity'),
    create_pattern('services/image_annotation'),
    create_pattern('services/media_session'),
    create_pattern('services/metrics'),
    create_pattern('services/network'),
    create_pattern('services/preferences'),
    create_pattern('services/proxy_resolver'),
    create_pattern('services/resource_coordinator'),
    create_pattern('services/service_manager'),
    create_pattern('services/shape_detection'),
    create_pattern('services/strings'),
    create_pattern('services/test'),
    create_pattern('services/tracing'),
    create_pattern('services/video_capture'),
    create_pattern('services/viz'),
    create_pattern('services/ws'),
    create_pattern('services'),
    create_pattern('skia/config'),
    create_pattern('skia/ext'),
    create_pattern('skia/public'),
    create_pattern('skia/tools'),
    create_pattern('skia'),
    create_pattern('sql'),
    create_pattern('storage'),
    create_pattern('styleguide'),
    create_pattern('testing'),
    create_pattern('third_party/Python-Markdown'),
    create_pattern('third_party/SPIRV-Tools'),
    create_pattern('third_party/abseil-cpp'),
    create_pattern('third_party/accessibility-audit'),
    create_pattern('third_party/accessibility_test_framework'),
    create_pattern('third_party/adobe'),
    create_pattern('third_party/afl'),
    create_pattern('third_party/android_build_tools'),
    create_pattern('third_party/android_crazy_linker'),
    create_pattern('third_party/android_data_chart'),
    create_pattern('third_party/android_deps'),
    create_pattern('third_party/android_media'),
    create_pattern('third_party/android_ndk'),
    create_pattern('third_party/android_opengl'),
    create_pattern('third_party/android_platform'),
    create_pattern('third_party/android_protobuf'),
    create_pattern('third_party/android_sdk'),
    create_pattern('third_party/android_support_test_runner'),
    create_pattern('third_party/android_swipe_refresh'),
    create_pattern('third_party/android_system_sdk'),
    create_pattern('third_party/android_tools'),
    create_pattern('third_party/angle'),
    create_pattern('third_party/apache-mac'),
    create_pattern('third_party/apache-portable-runtime'),
    create_pattern('third_party/apache-win32'),
    create_pattern('third_party/apk-patch-size-estimator'),
    create_pattern('third_party/apple_apsl'),
    create_pattern('third_party/arcore-android-sdk'),
    create_pattern('third_party/ashmem'),
    create_pattern('third_party/auto'),
    create_pattern('third_party/axe-core'),
    create_pattern('third_party/bazel'),
    create_pattern('third_party/binutils'),
    create_pattern('third_party/bison'),
    create_pattern('third_party/blanketjs'),
    create_pattern('third_party/blink/common'),
    create_pattern('third_party/blink/manual_tests'),
    create_pattern('third_party/blink/perf_tests'),
    create_pattern('third_party/blink/public/common'),
    create_pattern('third_party/blink/public/default_100_percent'),
    create_pattern('third_party/blink/public/default_200_percent'),
    create_pattern('third_party/blink/public/platform'),
    create_pattern('third_party/blink/public/mojom/ad_tagging'),
    create_pattern('third_party/blink/public/mojom/app_banner'),
    create_pattern('third_party/blink/public/mojom/appcache'),
    create_pattern('third_party/blink/public/mojom/array_buffer'),
    create_pattern('third_party/blink/public/mojom/associated_interfaces'),
    create_pattern('third_party/blink/public/mojom/autoplay'),
    create_pattern('third_party/blink/public/mojom/background_fetch'),
    create_pattern('third_party/blink/public/mojom/background_sync'),
    create_pattern('third_party/blink/public/mojom/badging'),
    create_pattern('third_party/blink/public/mojom/blob'),
    create_pattern('third_party/blink/public/mojom/bluetooth'),
    create_pattern('third_party/blink/public/mojom/broadcastchannel'),
    create_pattern('third_party/blink/public/mojom/cache_storage'),
    create_pattern('third_party/blink/public/mojom/choosers'),
    create_pattern('third_party/blink/public/mojom/clipboard'),
    create_pattern('third_party/blink/public/mojom/commit_result'),
    create_pattern('third_party/blink/public/mojom/contacts'),
    create_pattern('third_party/blink/public/mojom/cookie_store'),
    create_pattern('third_party/blink/public/mojom/crash'),
    create_pattern('third_party/blink/public/mojom/credentialmanager'),
    create_pattern('third_party/blink/public/mojom/csp'),
    create_pattern('third_party/blink/public/mojom/devtools'),
    create_pattern('third_party/blink/public/mojom/document_metadata'),
    create_pattern('third_party/blink/public/mojom/dom_storage'),
    create_pattern('third_party/blink/public/mojom/dwrite_font_proxy'),
    create_pattern('third_party/blink/public/mojom/feature_policy'),
    create_pattern('third_party/blink/public/mojom/fetch'),
    create_pattern('third_party/blink/public/mojom/file'),
    create_pattern('third_party/blink/public/mojom/filesystem'),
    create_pattern('third_party/blink/public/mojom/font_unique_name_lookup'),
    create_pattern('third_party/blink/public/mojom/frame'),
    create_pattern('third_party/blink/public/mojom/frame_sinks'),
    create_pattern('third_party/blink/public/mojom/geolocation'),
    create_pattern('third_party/blink/public/mojom/hyphenation'),
    create_pattern('third_party/blink/public/mojom/idle'),
    create_pattern('third_party/blink/public/mojom/indexeddb'),
    create_pattern('third_party/blink/public/mojom/input'),
    create_pattern('third_party/blink/public/mojom/insecure_input'),
    create_pattern('third_party/blink/public/mojom/installation'),
    create_pattern('third_party/blink/public/mojom/installedapp'),
    create_pattern('third_party/blink/public/mojom/keyboard_lock'),
    create_pattern('third_party/blink/public/mojom/leak_detector'),
    create_pattern('third_party/blink/public/mojom/loader'),
    create_pattern('third_party/blink/public/mojom/locks'),
    create_pattern('third_party/blink/public/mojom/manifest'),
    create_pattern('third_party/blink/public/mojom/media_controls'),
    create_pattern('third_party/blink/public/mojom/mediasession'),
    create_pattern('third_party/blink/public/mojom/mediastream'),
    create_pattern('third_party/blink/public/mojom/messaging'),
    create_pattern('third_party/blink/public/mojom/mime'),
    create_pattern('third_party/blink/public/mojom/native_file_system'),
    create_pattern('third_party/blink/public/mojom/net'),
    create_pattern('third_party/blink/public/mojom/notifications'),
    create_pattern('third_party/blink/public/mojom/oom_intervention'),
    create_pattern('third_party/blink/public/mojom/page'),
    create_pattern('third_party/blink/public/mojom/payments'),
    create_pattern('third_party/blink/public/mojom/permissions'),
    create_pattern('third_party/blink/public/mojom/picture_in_picture'),
    create_pattern('third_party/blink/public/mojom/plugins'),
    create_pattern('third_party/blink/public/mojom/portal'),
    create_pattern('third_party/blink/public/mojom/presentation'),
    create_pattern('third_party/blink/public/mojom/push_messaging'),
    create_pattern('third_party/blink/public/mojom/quota'),
    create_pattern('third_party/blink/public/mojom/remote_objects'),
    create_pattern('third_party/blink/public/mojom/reporting'),
    create_pattern('third_party/blink/public/mojom/script'),
    create_pattern('third_party/blink/public/mojom/selection_menu'),
    create_pattern('third_party/blink/public/mojom/serial'),
    create_pattern('third_party/blink/public/mojom/service_worker'),
    create_pattern('third_party/blink/public/mojom/site_engagement'),
    create_pattern('third_party/blink/public/mojom/sms'),
    create_pattern('third_party/blink/public/mojom/speech'),
    create_pattern('third_party/blink/public/mojom/ukm'),
    create_pattern('third_party/blink/public/mojom/unhandled_tap_notifier'),
    create_pattern('third_party/blink/public/mojom/usb'),
    create_pattern('third_party/blink/public/mojom/use_counter'),
    create_pattern('third_party/blink/public/mojom/user_agent'),
    create_pattern('third_party/blink/public/mojom/wake_lock'),
    create_pattern('third_party/blink/public/mojom/web_client_hints'),
    create_pattern('third_party/blink/public/mojom/web_feature'),
    create_pattern('third_party/blink/public/mojom/webaudio'),
    create_pattern('third_party/blink/public/mojom/webauthn'),
    create_pattern('third_party/blink/public/mojom/webdatabase'),
    create_pattern('third_party/blink/public/mojom/webshare'),
    create_pattern('third_party/blink/public/mojom/window_features'),
    create_pattern('third_party/blink/public/mojom/worker'),
    create_pattern('third_party/blink/public/web'),
    create_pattern('third_party/blink/renderer/bindings'),
    create_pattern('third_party/blink/renderer/build'),
    create_pattern('third_party/blink/renderer/controller'),
    create_pattern('third_party/blink/renderer/core/accessibility'),
    create_pattern('third_party/blink/renderer/core/animation'),
    create_pattern('third_party/blink/renderer/core/aom'),
    create_pattern('third_party/blink/renderer/core/clipboard'),
    create_pattern('third_party/blink/renderer/core/content_capture'),
    create_pattern('third_party/blink/renderer/core/context_features'),
    create_pattern('third_party/blink/renderer/core/css'),
    create_pattern('third_party/blink/renderer/core/display_lock'),
    create_pattern('third_party/blink/renderer/core/dom'),
    create_pattern('third_party/blink/renderer/core/editing'),
    create_pattern('third_party/blink/renderer/core/events'),
    create_pattern('third_party/blink/renderer/core/execution_context'),
    create_pattern('third_party/blink/renderer/core/exported'),
    create_pattern('third_party/blink/renderer/core/feature_policy'),
    create_pattern('third_party/blink/renderer/core/fetch'),
    create_pattern('third_party/blink/renderer/core/fileapi'),
    create_pattern('third_party/blink/renderer/core/frame'),
    create_pattern('third_party/blink/renderer/core/fullscreen'),
    create_pattern('third_party/blink/renderer/core/geometry'),
    create_pattern('third_party/blink/renderer/core/html'),
    create_pattern('third_party/blink/renderer/core/imagebitmap'),
    create_pattern('third_party/blink/renderer/core/input'),
    create_pattern('third_party/blink/renderer/core/inspector'),
    create_pattern('third_party/blink/renderer/core/intersection_observer'),
    create_pattern('third_party/blink/renderer/core/invisible_dom'),
    create_pattern('third_party/blink/renderer/core/layout'),
    create_pattern('third_party/blink/renderer/core/loader'),
    create_pattern('third_party/blink/renderer/core/messaging'),
    create_pattern('third_party/blink/renderer/core/mojo'),
    create_pattern('third_party/blink/renderer/core/offscreencanvas'),
    create_pattern('third_party/blink/renderer/core/origin_trials'),
    create_pattern('third_party/blink/renderer/core/page'),
    create_pattern('third_party/blink/renderer/core/paint'),
    create_pattern('third_party/blink/renderer/core/probe'),
    create_pattern('third_party/blink/renderer/core/resize_observer'),
    create_pattern('third_party/blink/renderer/core/scheduler'),
    create_pattern('third_party/blink/renderer/core/script'),
    create_pattern('third_party/blink/renderer/core/scroll'),
    create_pattern('third_party/blink/renderer/core/streams'),
    create_pattern('third_party/blink/renderer/core/style'),
    create_pattern('third_party/blink/renderer/core/svg'),
    create_pattern('third_party/blink/renderer/core/testing'),
    create_pattern('third_party/blink/renderer/core/timezone'),
    create_pattern('third_party/blink/renderer/core/timing'),
    create_pattern('third_party/blink/renderer/core/trustedtypes'),
    create_pattern('third_party/blink/renderer/core/typed_arrays'),
    create_pattern('third_party/blink/renderer/core/url'),
    create_pattern('third_party/blink/renderer/core/win'),
    create_pattern('third_party/blink/renderer/core/workers'),
    create_pattern('third_party/blink/renderer/core/xml'),
    create_pattern('third_party/blink/renderer/core/xmlhttprequest'),
    create_pattern('third_party/blink/renderer/devtools'),
    create_pattern('third_party/blink/renderer/modules'),
    create_pattern('third_party/blink/renderer/platform'),
    create_pattern('third_party/blink/tools'),
    create_pattern('third_party/blink/web_tests'),
    create_pattern('third_party/boringssl'),
    create_pattern('third_party/bouncycastle'),
    create_pattern('third_party/breakpad'),
    create_pattern('third_party/brotli'),
    create_pattern('third_party/bspatch'),
    create_pattern('third_party/byte_buddy'),
    create_pattern('third_party/cacheinvalidation'),
    create_pattern('third_party/catapult'),
    create_pattern('third_party/cct_dynamic_module'),
    create_pattern('third_party/ced'),
    create_pattern('third_party/chaijs'),
    create_pattern('third_party/checkstyle'),
    create_pattern('third_party/chromevox'),
    create_pattern('third_party/chromite'),
    create_pattern('third_party/cld_3'),
    create_pattern('third_party/closure_compiler'),
    create_pattern('third_party/colorama'),
    create_pattern('third_party/crashpad'),
    create_pattern('third_party/crc32c'),
    create_pattern('third_party/cros_system_api'),
    create_pattern('third_party/custom_tabs_client'),
    create_pattern('third_party/d3'),
    create_pattern('third_party/dav1d'),
    create_pattern('third_party/dawn'),
    create_pattern('third_party/decklink'),
    create_pattern('third_party/depot_tools'),
    create_pattern('third_party/devscripts'),
    create_pattern('third_party/devtools-node-modules'),
    create_pattern('third_party/dom_distiller_js'),
    create_pattern('third_party/elfutils'),
    create_pattern('third_party/emoji-segmenter'),
    create_pattern('third_party/errorprone'),
    create_pattern('third_party/espresso'),
    create_pattern('third_party/expat'),
    create_pattern('third_party/feed'),
    create_pattern('third_party/ffmpeg'),
    create_pattern('third_party/flac'),
    create_pattern('third_party/flatbuffers'),
    create_pattern('third_party/flot'),
    create_pattern('third_party/fontconfig'),
    create_pattern('third_party/freetype'),
    create_pattern('third_party/fuchsia-sdk'),
    create_pattern('third_party/gestures'),
    create_pattern('third_party/gif_player'),
    create_pattern('third_party/glfw'),
    create_pattern('third_party/glslang'),
    create_pattern('third_party/gnu_binutils'),
    create_pattern('third_party/google-truth'),
    create_pattern('third_party/google_android_play_core'),
    create_pattern('third_party/google_appengine_cloudstorage'),
    create_pattern('third_party/google_input_tools'),
    create_pattern('third_party/google_toolbox_for_mac'),
    create_pattern('third_party/google_trust_services'),
    create_pattern('third_party/googletest'),
    create_pattern('third_party/gperf'),
    create_pattern('third_party/gradle_wrapper'),
    create_pattern('third_party/grpc'),
    create_pattern('third_party/gson'),
    create_pattern('third_party/guava'),
    create_pattern('third_party/gvr-android-keyboard'),
    create_pattern('third_party/gvr-android-sdk'),
    create_pattern('third_party/hamcrest'),
    create_pattern('third_party/harfbuzz-ng'),
    create_pattern('third_party/hunspell'),
    create_pattern('third_party/hunspell_dictionaries'),
    create_pattern('third_party/iaccessible2'),
    create_pattern('third_party/iccjpeg'),
    create_pattern('third_party/icu/android'),
    create_pattern('third_party/icu/android_small'),
    create_pattern('third_party/icu/cast'),
    create_pattern('third_party/icu/chromeos'),
    create_pattern('third_party/icu/common'),
    create_pattern('third_party/icu/filters'),
    create_pattern('third_party/icu/flutter'),
    create_pattern('third_party/icu/fuzzers'),
    create_pattern('third_party/icu/ios'),
    create_pattern('third_party/icu/patches'),
    create_pattern('third_party/icu/scripts'),
    create_pattern('third_party/icu/source'),
    create_pattern('third_party/icu/tzres'),
    create_pattern('third_party/icu4j'),
    create_pattern('third_party/ijar'),
    create_pattern('third_party/ink'),
    create_pattern('third_party/inspector_protocol'),
    create_pattern('third_party/instrumented_libraries'),
    create_pattern('third_party/intellij'),
    create_pattern('third_party/isimpledom'),
    create_pattern('third_party/jacoco'),
    create_pattern('third_party/jinja2'),
    create_pattern('third_party/jsoncpp'),
    create_pattern('third_party/jsr-305'),
    create_pattern('third_party/jstemplate'),
    create_pattern('third_party/junit'),
    create_pattern('third_party/khronos'),
    create_pattern('third_party/lcov'),
    create_pattern('third_party/leveldatabase'),
    create_pattern('third_party/libFuzzer'),
    create_pattern('third_party/libXNVCtrl'),
    create_pattern('third_party/libaddressinput'),
    create_pattern('third_party/libaom'),
    create_pattern('third_party/libcxx-pretty-printers'),
    create_pattern('third_party/libdrm'),
    create_pattern('third_party/libevdev'),
    create_pattern('third_party/libjingle_xmpp'),
    create_pattern('third_party/libjpeg'),
    create_pattern('third_party/libjpeg_turbo'),
    create_pattern('third_party/liblouis'),
    create_pattern('third_party/libovr'),
    create_pattern('third_party/libphonenumber'),
    create_pattern('third_party/libpng'),
    create_pattern('third_party/libprotobuf-mutator'),
    create_pattern('third_party/libsecret'),
    create_pattern('third_party/libsrtp'),
    create_pattern('third_party/libsync'),
    create_pattern('third_party/libudev'),
    create_pattern('third_party/libusb'),
    create_pattern('third_party/libvpx'),
    create_pattern('third_party/libwebm'),
    create_pattern('third_party/libwebp'),
    create_pattern('third_party/libxml'),
    create_pattern('third_party/libxslt'),
    create_pattern('third_party/libyuv'),
    create_pattern('third_party/lighttpd'),
    create_pattern('third_party/logilab'),
    create_pattern('third_party/lss'),
    create_pattern('third_party/lzma_sdk'),
    create_pattern('third_party/mach_override'),
    create_pattern('third_party/markdown'),
    create_pattern('third_party/markupsafe'),
    create_pattern('third_party/material_design_icons'),
    create_pattern('third_party/mesa_headers'),
    create_pattern('third_party/metrics_proto'),
    create_pattern('third_party/microsoft_webauthn'),
    create_pattern('third_party/mingw-w64'),
    create_pattern('third_party/minigbm'),
    create_pattern('third_party/minizip'),
    create_pattern('third_party/mocha'),
    create_pattern('third_party/mockito'),
    create_pattern('third_party/modp_b64'),
    create_pattern('third_party/motemplate'),
    create_pattern('third_party/mozilla'),
    create_pattern('third_party/nacl_sdk_binaries'),
    create_pattern('third_party/nasm'),
    create_pattern('third_party/netty-tcnative'),
    create_pattern('third_party/netty4'),
    create_pattern('third_party/node'),
    create_pattern('third_party/nvml'),
    create_pattern('third_party/objenesis'),
    create_pattern('third_party/ocmock'),
    create_pattern('third_party/openh264'),
    create_pattern('third_party/openscreen'),
    create_pattern('third_party/openvr'),
    create_pattern('third_party/opus'),
    create_pattern('third_party/ots'),
    create_pattern('third_party/ow2_asm'),
    create_pattern('third_party/pdfium'),
    create_pattern('third_party/pefile'),
    create_pattern('third_party/perfetto'),
    create_pattern('third_party/perl'),
    create_pattern('third_party/pexpect'),
    create_pattern('third_party/pffft'),
    create_pattern('third_party/ply'),
    create_pattern('third_party/polymer'),
    create_pattern('third_party/proguard'),
    create_pattern('third_party/protobuf'),
    create_pattern('third_party/protoc_javalite'),
    create_pattern('third_party/pycoverage'),
    create_pattern('third_party/pyelftools'),
    create_pattern('third_party/pyjson5'),
    create_pattern('third_party/pylint'),
    create_pattern('third_party/pymock'),
    create_pattern('third_party/pystache'),
    create_pattern('third_party/pywebsocket'),
    create_pattern('third_party/qcms'),
    create_pattern('third_party/quic_trace'),
    create_pattern('third_party/qunit'),
    create_pattern('third_party/r8'),
    create_pattern('third_party/re2'),
    create_pattern('third_party/requests'),
    create_pattern('third_party/rnnoise'),
    create_pattern('third_party/robolectric'),
    create_pattern('third_party/s2cellid'),
    create_pattern('third_party/sfntly'),
    create_pattern('third_party/shaderc'),
    create_pattern('third_party/simplejson'),
    create_pattern('third_party/sinonjs'),
    create_pattern('third_party/skia'),
    create_pattern('third_party/smhasher'),
    create_pattern('third_party/snappy'),
    create_pattern('third_party/speech-dispatcher'),
    create_pattern('third_party/spirv-cross'),
    create_pattern('third_party/spirv-headers'),
    create_pattern('third_party/sqlite'),
    create_pattern('third_party/sqlite4java'),
    create_pattern('third_party/sudden_motion_sensor'),
    create_pattern('third_party/swiftshader'),
    create_pattern('third_party/tcmalloc'),
    create_pattern('third_party/test_fonts'),
    create_pattern('third_party/tlslite'),
    create_pattern('third_party/ub-uiautomator'),
    create_pattern('third_party/unrar'),
    create_pattern('third_party/usb_ids'),
    create_pattern('third_party/usrsctp'),
    create_pattern('third_party/v4l-utils'),
    create_pattern('third_party/vulkan'),
    create_pattern('third_party/wayland'),
    create_pattern('third_party/wayland-protocols'),
    create_pattern('third_party/wds'),
    create_pattern('third_party/web-animations-js'),
    create_pattern('third_party/webdriver'),
    create_pattern('third_party/webgl'),
    create_pattern('third_party/webrtc'),
    create_pattern('third_party/webrtc_overrides'),
    create_pattern('third_party/webxr_test_pages'),
    create_pattern('third_party/widevine'),
    create_pattern('third_party/win_build_output'),
    create_pattern('third_party/woff2'),
    create_pattern('third_party/wtl'),
    create_pattern('third_party/xdg-utils'),
    create_pattern('third_party/xstream'),
    create_pattern('third_party/yasm'),
    create_pattern('third_party/zlib'),
    create_pattern('tools'),
    create_pattern('ui/accelerated_widget_mac'),
    create_pattern('ui/accessibility'),
    create_pattern('ui/android'),
    create_pattern('ui/aura'),
    create_pattern('ui/aura_extra'),
    create_pattern('ui/base'),
    create_pattern('ui/chromeos'),
    create_pattern('ui/compositor'),
    create_pattern('ui/compositor_extra'),
    create_pattern('ui/content_accelerators'),
    create_pattern('ui/display'),
    create_pattern('ui/events'),
    create_pattern('ui/file_manager'),
    create_pattern('ui/gfx'),
    create_pattern('ui/gl'),
    create_pattern('ui/latency'),
    create_pattern('ui/login'),
    create_pattern('ui/message_center'),
    create_pattern('ui/native_theme'),
    create_pattern('ui/ozone'),
    create_pattern('ui/platform_window'),
    create_pattern('ui/resources'),
    create_pattern('ui/shell_dialogs'),
    create_pattern('ui/snapshot'),
    create_pattern('ui/strings'),
    create_pattern('ui/surface'),
    create_pattern('ui/touch_selection'),
    create_pattern('ui/views'),
    create_pattern('ui/views_bridge_mac'),
    create_pattern('ui/views_content_client'),
    create_pattern('ui/web_dialogs'),
    create_pattern('ui/webui'),
    create_pattern('ui/wm'),
    create_pattern('url'),
    create_pattern('v8/benchmarks'),
    create_pattern('v8/build_overrides'),
    create_pattern('v8/custom_deps'),
    create_pattern('v8/docs'),
    create_pattern('v8/gni'),
    create_pattern('v8/include'),
    create_pattern('v8/infra'),
    create_pattern('v8/samples'),
    create_pattern('v8/src'),
    create_pattern('v8/test'),
    create_pattern('v8/testing'),
    create_pattern('v8/third_party'),
    create_pattern('v8/tools'),

    # keep out/obj and other patterns at the end.
    [
        'out/obj', '.*/(gen|obj[^/]*)/(include|EXECUTABLES|SHARED_LIBRARIES|'
        'STATIC_LIBRARIES|NATIVE_TESTS)/.*: warning:'
    ],
    ['other', '.*']  # all other unrecognized patterns
]
>>>>>>> BRANCH (77b382 Merge "Version bump to AAQ4.211109.001 [core/build_id.mk]" i)
