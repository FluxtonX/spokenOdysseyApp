# Smart glasses SDK (LIB_GLASSES_SDK). The bridge reads a few private SDK fields by name
# (GlassesPlatformPlugin.stopSdkTransfer), so nothing in the SDK may be renamed or removed.
-keep class com.oudmon.** { *; }
-keep class ImageProcessor { *; }
-keep class org.jvcompress.** { *; }
-dontwarn com.oudmon.**

# Fast-Android-Networking + OkHttp, used by the SDK's Wi-Fi media import.
-keep class com.androidnetworking.** { *; }
-dontwarn com.androidnetworking.**
-dontwarn okhttp3.**
-dontwarn okio.**
