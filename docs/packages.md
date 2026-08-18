# Orbitune - Complete Package Architecture & Dependency Manifest

This document specifies the exact package stack, version constraints, architectural role, and native platform configurations (including **arm64-v8a ABI filter**) for the **Orbitune** Modern Online Music Player application.

---

## 1. Core Audio Playback & Platform Media Integration

| Package | Version | Architectural Role & Implementation Details |
|---|---|---|
| [`just_audio`](https://pub.dev/packages/just_audio) | `^0.9.41` | High-fidelity gapless audio playback engine, buffering streams, playback speed modulation (0.5x to 2.0x), volume control, pitch adjustment, and stream headers. |
| [`just_audio_background`](https://pub.dev/packages/just_audio_background) | `^0.0.1-beta.17` | Native Android `MediaBrowserService` & iOS `MPNowPlayingInfoCenter` background integration. Powers notification tray controls, lock screen media player, Bluetooth AVRCP metadata, Android Auto, and Apple CarPlay metadata tags. |
| [`audio_session`](https://pub.dev/packages/audio_session) | `^0.1.21` | Manages system audio focus, ducking during navigation voice prompts, phone call interruptions, and graceful pause on headphone disconnect / Bluetooth loss (`BECOMING_NOISY`). |

---

## 2. Music Streaming Sources, Extractors & Data Decryptors

| Package | Version | Architectural Role & Implementation Details |
|---|---|---|
| [`extractor`](https://pub.dev/packages/extractor) | `^1.0.0` | **Primary Media & Audio Extractor**: Powerful engine to extract direct media, audio-only streams, and download links across YouTube, YouTube Music, and other media sources. |
| [`youtube_explode_dart`](https://pub.dev/packages/youtube_explode_dart) | `^2.3.4` | Pure Dart engine to search songs, artists, albums, playlists, and extract high-bitrate M4A / AAC / Opus streams from YouTube and YouTube Music. |
| [`dart_des`](https://pub.dev/packages/dart_des) | `^1.0.2` | High-speed DES-ECB cipher decryption (`38346591` key) for decrypting JioSaavn `encrypted_media_url` values to retrieve direct 320kbps / 160kbps MP4/M4A CDN streams. |
| [`encrypt`](https://pub.dev/packages/encrypt) | `^5.0.3` | Additional cryptographic utilities for secure credential and token handling. |
| [`http`](https://pub.dev/packages/http) | `^1.2.2` | Fast REST client for lightweight API calls, LRCLIB synchronized lyrics, and JioSaavn discovery endpoints. |
| [`dio`](https://pub.dev/packages/dio) | `^5.7.0` | Enterprise HTTP engine featuring request interceptors, retry interceptors, chunked background file downloads, cancel tokens, and real-time progress callbacks. |

---

## 3. UI/UX Design System: Material 3 Expressive & Typography

| Package | Version | Architectural Role & Implementation Details |
|---|---|---|
| [`material_3_expressive`](https://pub.dev/packages/material_3_expressive) | `^1.0.8` | **Material 3 Expressive Design System**: Implements Google's Material 3 Expressive design tokens, spring-driven press feedback, shape morphing, expressive containment, expressive cards, sliders, bottom sheets, and navigation bars. |
| [`google_fonts`](https://pub.dev/packages/google_fonts) | `^6.2.1` | Typography system with **Righteous** for headings/brand identity, and **Poppins** / **Plus Jakarta Sans** for body metadata and lyrics. |
| [`palette_generator`](https://pub.dev/packages/palette_generator) | `^0.3.3` | Extracts dominant, vibrant, and muted color palettes in real-time from album art to create dynamic, fluid ambient background gradients. |
| [`cached_network_image`](https://pub.dev/packages/cached_network_image) | `^3.4.1` | Asynchronous image loading with disk/memory caching, progressive fades, and shimmer placeholders. |
| [`shimmer`](https://pub.dev/packages/shimmer) | `^3.0.0` | Sleek skeleton loading placeholders for home discovery feeds, artist discography, and search results. |
| [`flutter_animate`](https://pub.dev/packages/flutter_animate) | `^4.5.0` | Declarative micro-animations: rotating vinyl disc, pulsating equalizer bars, spring sheet transitions, and heart like animations. |
| [`marquee`](https://pub.dev/packages/marquee) | `^2.2.3` | Smooth horizontal auto-scrolling for oversized song titles and artist names. |
| [`flutter_spinkit`](https://pub.dev/packages/flutter_spinkit) | `^5.2.1` | Audio buffering waves, pulsing visualizers, and minimal spinners. |
| [`lucide_icons`](https://pub.dev/packages/lucide_icons) | `^0.257.0` | High-quality, modern stroke-based vector icons for all playback controls and actions (100% emoji-free UI). |
| [`intl`](https://pub.dev/packages/intl) | `^0.19.0` | Duration formatting (`mm:ss`, `hh:mm:ss`), view counts, timestamps, and number formatting. |
| [`fl_chart`](https://pub.dev/packages/fl_chart) | `^0.69.0` | Interactive charts for user listening statistics (daily, weekly, monthly listening time, top genres, play count streaks). |
| [`qr_flutter`](https://pub.dev/packages/qr_flutter) | `^4.1.0` | Generates QR codes for instant offline playlist and track sharing. |
| [`share_plus`](https://pub.dev/packages/share_plus) | `^10.0.0` | Native OS share sheet integration to export track links and generated share cards. |
| [`connectivity_plus`](https://pub.dev/packages/connectivity_plus) | `^6.0.5` | Real-time network state monitoring (Wi-Fi, Mobile Data, Offline) with auto-switch to offline mode and adaptive quality. |

---

## 4. State Management & Architecture

| Package | Version | Architectural Role & Implementation Details |
|---|---|---|
| [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) | `^2.6.1` | Declarative, compile-time safe reactive state management. Separates player state machines, active queues, search debouncing, lyrics position sync, library CRUD, and user settings. |

---

## 5. Local Storage, Persistence & Offline Engine

| Package | Version | Architectural Role & Implementation Details |
|---|---|---|
| [`hive_flutter`](https://pub.dev/packages/hive_flutter) | `^1.1.0` | Lightning-fast NoSQL local database for caching Liked Songs, Custom Playlists, Listening History, Listening Statistics, Recent Searches, Cached Lyrics, and App Settings. |
| [`hive`](https://pub.dev/packages/hive) | `^2.2.3` | Pure Dart key-value storage engine with binary serialization. |
| [`path_provider`](https://pub.dev/packages/path_provider) | `^2.1.4` | Resolves platform-specific directories (App Documents, App Support, Cache, Downloads) across Android, iOS, Windows, macOS, and Linux. |
| [`permission_handler`](https://pub.dev/packages/permission_handler) | `^11.3.1` | Manages runtime permissions for Android 13+ `POST_NOTIFICATIONS`, `READ_MEDIA_AUDIO`, and storage access. |

---

## 6. Native Platform Setup & ARM64-v8a Build Filter

### Android Build Configuration (`android/app/build.gradle.kts`)
To build the APK exclusively for **64-bit ARM architectures (`arm64-v8a`)**, the Gradle file is configured with an explicit NDK ABI filter:

```kotlin
android {
    ...
    defaultConfig {
        applicationId = "com.orbitune.music.orbitune"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Filter APK build exclusively for arm64-v8a
        ndk {
            abiFilters.add("arm64-v8a")
        }
    }
}
```

### Android Build Command
```bash
flutter build apk --target-platform android-arm64 --release
```

### Android Manifest (`android/app/src/main/AndroidManifest.xml`)
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.orbitune.music">

    <!-- Network & Wakelock -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    
    <!-- Background Playback & Notifications -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    
    <!-- Bluetooth & Audio Routing -->
    <uses-permission android:name="android.permission.BLUETOOTH"/>
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>

    <!-- Storage & Downloads -->
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>

    <application
        android:label="Orbitune"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <!-- JustAudio Background Audio Service -->
        <service 
            android:name="com.ryanheise.just_audio_background.JustAudioBackgroundService"
            android:icon="@mipmap/ic_launcher"
            android:foregroundServiceType="mediaPlayback"
            android:exported="true">
            <intent-filter>
                <action android:name="android.media.browse.MediaBrowserService"/>
            </intent-filter>
        </service>

        <!-- Media Button Hardware Receiver -->
        <receiver 
            android:name="com.ryanheise.just_audio_background.MediaButtonReceiver"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MEDIA_BUTTON"/>
            </intent-filter>
        </receiver>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

### iOS Configuration (`ios/Runner/Info.plist`)
```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Orbitune requires access to save share cards and artwork.</string>
```
