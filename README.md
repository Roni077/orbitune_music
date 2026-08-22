<div align="center">

# 🪐 Orbitune
### *Modern Online Music Player with Material 3 Expressive UI & Multi-Source Audio Streaming*

[![Build & Test Orbitune](https://github.com/Roni077/orbitune_music/actions/workflows/build.yml/badge.svg)](https://github.com/Roni077/orbitune_music/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)
[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.13%2B-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Material 3 Expressive](https://img.shields.io/badge/UI-Material_3_Expressive-6750A4?style=for-the-badge&logo=materialdesign&logoColor=white)](https://pub.dev/packages/material_3_expressive)
[![State Management](https://img.shields.io/badge/State-Riverpod_2.6-00D2B8?style=for-the-badge)](https://riverpod.dev)
[![Audio Engine](https://img.shields.io/badge/Audio-JustAudio_0.9-FF6F00?style=for-the-badge)](https://pub.dev/packages/just_audio)


</div>

---

## 📖 Overview

**Orbitune** is a next-generation online music player for Android, iOS, and Desktop built from the ground up with **Flutter**, **Material 3 Expressive UI/UX**, and high-fidelity audio streaming and extraction engines.

Orbitune combines pure audio streaming powered by **YouTube Explode** (`youtube_explode_dart`), offline downloads exclusively via the native **Extractor Engine** (`extractor`), synchronized karaoke lyrics from **LRCLIB**, 10-band DSP equalization, dynamic color theming, and offline playback.

---

## ✨ Key Features

### 🎨 Material 3 Expressive UI & Visuals
* **Deep Midnight & Pure OLED Black Themes**: Ultra-sleek dark aesthetics paired with dynamic color theming that extracts ambient gradients directly from album artwork using `PaletteGenerator`.
* **Spring Physics & Micro-Interactions**: Tactile button responses, card press animations, and haptic feedback on scrubber drags and controls.
* **Glassmorphism & Shimmer Loaders**: Blurred frosted glass containers with subtle gradient borders and skeleton shimmer loading states.
* **Typography**: Elegant typography powered by Google Fonts (`Righteous` for branding and display headers, `Poppins` for metadata and synced lyrics).
* **100% Emoji-Free Modern Iconography**: Clean, vector stroke iconography powered by Lucide icons.

### 🎧 High-Fidelity Audio & Pure Streaming
* **Pure YouTube Explode Audio Engine (`youtube_explode_dart: ^2.3.4`)**:
  * Pure audio format extraction (Opus ~160kbps 48kHz, AAC ~128-142kbps).
  * Multi-client rotation (`ios`, `androidVr`, `safari`, `androidMusic`, `web`) for 403 Forbidden and PoToken restriction bypass.
  * Configurable streaming qualities with in-memory candidate caching and lookahead prefetching.
* **Offline Song Downloads via Extractor (`extractor: ^1.0.0`)**:
  * Native yt-dlp audio extraction and offline downloading with metadata and progress reporting.
* **Pro Audio Controls (`just_audio` & `audio_session`)**:
  * Gapless playback, crossfade transitions, and variable playback speeds (0.5x to 2.0x).
  * System audio focus handling, smooth ducking during notifications, and graceful pause on headphone disconnect (`BECOMING_NOISY`).
  * Lock screen player, persistent notification tray controls, Android Auto, and Bluetooth AVRCP integration via `just_audio_background`.

### 🎤 Synchronized Karaoke Lyrics
* Real-time synchronized LRC lyrics powered by the **LRCLIB API** (`lrclib.net`).
* Automatic scrolling with active line spotlight and smooth animations.
* **Tap-to-Seek**: Jump directly to any moment in the song by tapping the corresponding lyric line.
* Plain lyrics fallback and offline lyrics caching in Hive.

### 🎚️ 10-Band Equalizer & Audio Enhancements
* Interactive 10-band and 5-band EQ sliders (60 Hz to 14 kHz) with real-time dB gain indicators (-10 dB to +10 dB).
* Built-in sound presets: *Rock, Pop, Jazz, Classical, Hip-Hop, Dance, Bass Boost, Vocal Booster, Flat*.
* **Bass Boost**, **3D Surround Virtualizer**, **Loudness Enhancement**, and stereo pan balance controls.

### 📊 Audio Visualizers & Now Playing
* Dynamic waveform seek bar with live scrub preview.
* Multiple real-time audio visualizer modes:
  * **Bar Spectrum Visualizer**
  * **Fluid Wave Visualizer**
  * **Circular Radial Visualizer**
* Animated rotating vinyl disc artwork with ambient dynamic lighting.
* Sleep timer with custom countdown presets and smooth fade-out.

### 📂 Library, Offline Downloader & Stats
* **Smart Queue**: Drag-and-drop queue reordering, play next, history, and AutoPlay recommendations.
* **Offline Downloader**: Multi-threaded chunked downloads with pause, resume, cancel, and progress notifications via `dio`.
* **Playlists & Sharing**: Create and manage custom playlists, import/export backup JSON files, and share playlists offline via instant QR codes (`qr_flutter`).
* **Listening Analytics**: Comprehensive dashboard powered by `fl_chart` tracking total listening time, top tracks, top artists, and weekly genre charts.

---

## 🏗️ Architecture & Directory Tree

Orbitune follows a **Feature-First Clean Architecture** with compile-time safe state management using **Riverpod 2.6**:

```
orbitune/
├── docs/                               # Architectural documents, package specs & roadmap
├── assets/
│   ├── icons/                          # Vector brand assets & waveform SVGs
│   └── images/                         # Default fallbacks & placeholders
├── lib/
│   ├── main.dart                       # App entry point (Hive & background service bootstrap)
│   ├── app.dart                        # MaterialApp.router with dynamic theme listeners
│   ├── core/                           # Shared core services, utilities & design tokens
│   │   ├── constants/                  # API endpoints, colors, typography, hive keys
│   │   ├── errors/                     # Failure models & custom exceptions
│   │   ├── network/                    # Dio client, interceptors & connectivity listeners
│   │   ├── theme/                      # Material 3 Expressive themes & shape tokens
│   │   ├── utils/                      # DES audio decryptor, LRC parser, palette helper
│   │   └── widgets/                    # Expressive cards, glass containers, wave visualizers
│   ├── features/                       # Modular feature domains
│   │   ├── audio_player/               # JustAudio service, queue notifier, full player
│   │   ├── discovery/                  # Home feed, trending charts, quick picks, carousels
│   │   ├── downloader/                 # Chunked download tasks & offline file managers
│   │   ├── equalizer/                  # 10-band DSP sliders, presets & audio enhancers
│   │   ├── library/                    # Liked songs, custom playlists, stats, QR share
│   │   ├── lyrics/                     # LRCLIB API client & synchronized LRC karaoke view
│   │   ├── search/                     # Debounced multi-source search & artist discography
│   │   ├── settings/                   # Theme switcher, audio quality, backup & restore
│   │   └── visualizer/                 # Bar, wave, and circular audio visualizers
│   └── shell/                          # Persistent M3E navigation shell & floating MiniPlayer
└── test/                               # Comprehensive unit & widget test suite (152 tests)
```

---

## 📦 Tech Stack & Key Dependencies

| Component | Library / Package | Version | Purpose |
|---|---|---|---|
| **UI Framework** | [`material_3_expressive`](https://pub.dev/packages/material_3_expressive) | `^1.0.8` | Expressive M3 tokens, shapes & spring physics |
| **Icons** | [`lucide_icons_flutter`](https://pub.dev/packages/lucide_icons_flutter) | `^3.0.0` | Modern, clean vector stroke icons |
| **Typography** | [`google_fonts`](https://pub.dev/packages/google_fonts) | `^6.2.1` | Righteous & Poppins font families |
| **State Management** | [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) | `^2.6.1` | Reactive, compile-time safe state architecture |
| **Audio Playback** | [`just_audio`](https://pub.dev/packages/just_audio) | `^0.9.41` | Gapless playback, speed modulation & buffering |
| **Background Media** | [`just_audio_background`](https://pub.dev/packages/just_audio_background) | `^0.0.1-beta.17` | Lock screen player & notification tray integration |
| **Audio Session** | [`audio_session`](https://pub.dev/packages/audio_session) | `^0.1.21` | Focus handling, ducking & noisy headset pause |
| **Media Downloader** | [`extractor`](https://pub.dev/packages/extractor) | `^1.0.0` | Native yt-dlp audio extraction & offline downloads |
| **YouTube Source** | [`youtube_explode_dart`](https://pub.dev/packages/youtube_explode_dart) | `^2.3.4` | Pure Opus/AAC audio streaming & discovery feeds |
| **Local Database** | [`hive_flutter`](https://pub.dev/packages/hive_flutter) | `^1.1.0` | Fast NoSQL key-value persistence |
| **Networking & HTTP** | [`dio`](https://pub.dev/packages/dio) / [`http`](https://pub.dev/packages/http) | `^5.7.0` | REST clients, interceptors & chunked downloads |
| **Color Extraction** | [`palette_generator`](https://pub.dev/packages/palette_generator) | `^0.3.3` | Dynamic color extraction from album artwork |
| **Charts** | [`fl_chart`](https://pub.dev/packages/fl_chart) | `^0.69.0` | Listening analytics & stats visualization |
| **QR Code Sharing** | [`qr_flutter`](https://pub.dev/packages/qr_flutter) | `^4.1.0` | Offline playlist QR code generator |

---

## 🚀 Getting Started

### Prerequisites
* [Flutter SDK](https://flutter.dev/docs/get-started/install) (`^3.13.0` or higher)
* [Dart SDK](https://dart.dev/get-dart) (`^3.13.0` or higher)
* Android Studio / Xcode / VS Code with Flutter extension
* Android SDK 34+ for Android target

### Installation & Run

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Roni077/orbitune_music.git
   cd orbitune_music
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run unit & widget test suite:**
   ```bash
   flutter test
   ```

4. **Launch the application:**
   ```bash
   flutter run
   ```

---

## 📱 Building Release APK (ARM64-v8a)

Orbitune is configured with an NDK ABI filter targeting modern 64-bit ARM devices (`arm64-v8a`) to minimize binary footprint and maximize performance:

```bash
flutter build apk --target-platform android-arm64 --release
```

The compiled release APK will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 🧪 Testing

The codebase includes 152 automated tests covering audio decryptors, LRC lyric parsers, queue state machines, and widget components:

```bash
flutter test
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

<div align="center">
Made with ❤️ by <b>Orbitune Team</b>
</div>
