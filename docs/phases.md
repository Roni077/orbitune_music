# Orbitune - Complete Development Phases & Master Feature Checklist

This document contains the complete execution roadmap and the comprehensive master checklist for **Orbitune — Modern Online Music Player**, built with **Material 3 Expressive UI/UX** (`material_3_expressive: ^1.0.8`), **Extractor Media Engine** (`extractor: ^1.0.0`), **YouTube Explode**, and **JioSaavn 320kbps Decryption**.

---

## 🗺️ Part 1: Phase-by-Phase Implementation Roadmap

### **Phase 1: Project Setup, Material 3 Expressive System & Design Tokens**
- [x] **Dependencies & Setup**
  - [x] Configure `pubspec.yaml` with latest major packages: `material_3_expressive: ^1.0.8`, `extractor: ^1.0.0`, `just_audio: ^0.9.41`, `youtube_explode_dart: ^2.3.4`, `flutter_riverpod: ^2.6.1`, `hive_flutter: ^1.1.0`, `lucide_icons_flutter: ^3.0.0`
  - [x] Setup Android permissions (`FOREGROUND_SERVICE`, `WAKE_LOCK`, `POST_NOTIFICATIONS`, `READ_MEDIA_AUDIO`)
  - [x] Setup Android `arm64-v8a` ABI filter in `build.gradle.kts`
  - [x] Setup iOS `Info.plist` with `UIBackgroundModes` (`audio`, `fetch`)
- [x] **Material 3 Expressive UI/UX Design System**
  - [x] Material 3 Expressive theme tokens with expressive shapes & spring physics
  - [x] Deep Midnight Theme (`#0B0B14`, `#14142B`), Pure OLED Black, and Dynamic Theming
  - [x] Google Fonts typography hierarchy (`Righteous` for brand/titles, `Poppins` for body)
  - [x] Custom Glassmorphic container with blur & gradient border (`GlassContainer`)
  - [x] Skeleton shimmer placeholder loaders (`ImageShimmer`)
  - [x] Spring feedback touch animations via `ExpressiveCard`
  - [x] Clean modern stroke iconography via `lucide_icons_flutter` (0 emojis in UI)
  - [x] Haptic feedback on button interactions & scrubber drags
  - [x] Dynamic color extraction system via `PaletteHelper`
  - [x] Status: ✅ **Phase 1 Complete (flutter analyze 0 issues, flutter test passed, graphify updated)**

### **Phase 2: Local Storage, Hive Database & Domain Entities**
- [x] **Milestone**: High-speed offline-first persistence layer with Hive and Riverpod providers.
- [x] **Key Tasks**:
  - [x] Initialize Hive boxes: `favorites_box`, `playlists_box`, `history_box`, `stats_box`, `settings_box`, `downloads_box`, `lyrics_cache_box`, `search_cache_box` via `HiveService`.
  - [x] Implement domain models: `Track`, `AudioQuality`, `PlaybackMode`, `PlaybackStatus`, `QueueItem`, `AlbumModel`, `ArtistModel`, `PlaylistModel`, `SearchResult`, `UserPlaylist`, `FavoriteSong`, `HistoryItem`, `ListeningStats`, `AppSettings`, `EQPreset`, `EQProfile`, `DownloadTask`, `LyricLine`.
  - [x] Implement Hive data repositories: `LibraryRepository`, `SettingsRepository`, `DownloadRepository`, `LyricsCacheRepository`, `SearchCacheRepository`.
  - [x] Implement Riverpod state providers: `favoritesProvider`, `userPlaylistsProvider`, `historyProvider`, `statsProvider`, `settingsProvider`, `downloadListProvider`.
  - [x] Status: ✅ **Phase 2 Complete (flutter analyze 0 issues, 24 unit & widget tests passed)**

### **Phase 3: Music Extraction, Streaming Sources & Decryptors**
- [x] **Milestone**: Multi-source stream extraction and decryption engine.
- [x] **Key Tasks**:
  - [x] Implement `extractor_service.dart` using `extractor: ^1.0.0` for direct media stream extraction across social and streaming URLs.
  - [x] Implement `youtube_source.dart` using `youtube_explode_dart: ^2.3.4` for YouTube & YouTube Music search, playlists, and high-bitrate audio streams.
  - [x] Implement `jiosaavn_source.dart` and `audio_decryptor.dart` with DES-ECB cipher key `38346591` for 320kbps MP4/M4A streaming + `saavn.dev` API fallback.
  - [x] Implement `lrc_parser.dart` and `lyrics_repository.dart` with LRCLIB API (`lrclib.net`) and JioSaavn fallback for synchronized karaoke lyrics.
  - [x] Implement `search_repository.dart` for multi-source search aggregation, duplicate detection, metadata normalization, and seamless stream URL resolution.
  - [x] Implement `discovery_repository.dart` for discovery feed, charts, hero banners, and new releases.
  - [x] Status: ✅ **Phase 3 Complete (flutter analyze 0 issues, 39 unit & widget tests passed)**

### **Phase 4: Core Audio Engine, Background Playback & Hardware Media Session**
- [x] **Milestone**: Professional gapless audio playback with lock screen and notification controls.
- [x] **Key Tasks**:
  - [x] Implement `audio_player_service.dart` wrapping `just_audio.AudioPlayer` with streams, seek forward/back, volume fade ramps, playback modes & speed.
  - [x] Implement `JustAudioBackground` media notifications with `MediaItem` tags, high-res album artwork, and play/pause/seek/next/prev/favorite actions via `audio_handler.dart`.
  - [x] Handle audio focus, headphone disconnect (`BECOMING_NOISY`), incoming phone call pause, Bluetooth AVRCP, and Android Auto integration via `audio_session_service.dart`.
  - [x] Implement `player_repository.dart` orchestrating stream resolution, offline check, listening history & stats logging.
  - [x] Implement `player_provider.dart` with `PlayerNotifier` StateNotifier and convenience selector providers.
  - [x] Status: ✅ **Phase 4 Complete (flutter analyze 0 issues, 58 unit & widget tests passed)**

### **Phase 5: Up Next Queue Management & Smart Playlists**
- [x] **Milestone**: Dynamic queue controller with drag-and-drop reordering, auto-queue, and history.
- [x] **Key Tasks**:
  - [x] Implement `queue_provider.dart` and `queue_sheet.dart` modal.
  - [x] Support Add to Queue, Play Next, Remove, Drag-and-drop reordering, Clear Queue, Shuffle Queue, and Save Queue as new Playlist.
  - [x] AutoPlay recommendations when the queue ends.
  - [x] Status: ✅ **Phase 5 Complete (flutter analyze 0 issues, 72 unit & widget tests passed)**

### **Phase 6: Material 3 Expressive Shell & Home Discovery Feed**
- [x] **Milestone**: M3E persistent bottom navigation shell and discovery home dashboard.
- [x] **Key Tasks**:
  - [x] `MainNavigationShell` with M3E floating bottom navigation and fluid docked/floating MiniPlayer.
  - [x] `HomeScreen`: Hero trending banner carousel with parallax, Quick Picks 2x3 grid, Trending Charts (Top 50 Global, Top 50 India, Bollywood, Punjabi), Popular Artists, Genre & Mood discovery chips, Daily Mixes, and Continue Listening.
  - [x] Status: ✅ **Phase 6 Complete (flutter analyze 0 issues, 88 unit & widget tests passed)**

### **Phase 7: Universal Search, Artist Profiles & Album Pages**
- [x] **Milestone**: Real-time debounced multi-source search and detailed discography views.
- [x] **Key Tasks**:
  - [x] `SearchScreen`: 400ms debounced instant search, suggestions, history chips, voice search interface, and source filters (All, JioSaavn 320k, YouTube Music, Extractor).
  - [x] `ArtistDetailScreen`: High-res banner, biography, monthly listeners, top tracks, albums, singles, related artists, and Artist Radio.
  - [x] `AlbumDetailScreen`: Large album artwork, tracklist with duration, Play All, Shuffle Album, and Add to Queue.
  - [x] Status: ✅ **Phase 7 Complete (flutter analyze 0 issues, 99 unit & widget tests passed)**

### **Phase 8: Immersive Now Playing, Dynamic Theming, Visualizers & Synced Lyrics**
- [x] **Milestone**: Apple Music / Spotify grade fullscreen player with real-time karaoke lyrics and spectrum visualizers.
- [x] **Key Tasks**:
  - [x] `FullPlayerScreen`: Ambient gradient background dynamically extracted via `PaletteGenerator`, blurred artwork background, rotating vinyl disc (`ArtworkDiscView`), waveform seek bar (`WaveformSeekBar`), audio quality badges (Hi-Res, 320kbps, Lossless, YouTube).
  - [x] `LyricsScreen` & `LrcView`: Synced lyrics from LRCLIB API (`lrclib.net`) and JioSaavn, real-time line highlighting, auto-scroll, tap-to-seek timestamp navigation, plain lyrics fallback, and offline lyrics cache.
  - [x] `VisualizerWidget`: Frequency bars (`BarVisualizer`), wave visualizer (`WaveVisualizer`), circular radial visualizer (`CircularVisualizer`), artwork-reactive pulse, and FPS toggle (`VisualizerProvider`).
  - [x] `SleepTimerSheet` & `SleepTimerNotifier`: Custom duration, presets, stop after current track, smooth volume fade.
  - [x] Status: ✅ **Phase 8 Complete (flutter analyze 0 issues, 111 unit & widget tests passed)**

### **Phase 9: 10-Band Equalizer & Audio Enhancements**
* **Milestone**: Professional DSP sound enhancement engine.
* **Key Tasks**:
  - `EqualizerScreen`: 5-Band and 10-Band EQ sliders (60Hz to 14kHz), dB gain indicators (-10dB to +10dB).
  - Built-in EQ presets (Rock, Pop, Jazz, Classical, Hip-Hop, Dance, Bass Boost, Vocal Booster, Flat).
  - Bass Boost slider, Virtualizer 3D surround slider, Loudness enhancement slider, and Balance pan control.

### **Phase 10: Library, Offline Extractor Downloader, Stats, Settings & QA**
* **Milestone**: Full user library, offline downloads, listening stats charts, settings, and test verification.
* **Key Tasks**:
  - `LibraryScreen`: Liked Songs, Custom Playlists CRUD, QR code playlist sharing, JSON import/export, and listening history.
  - `DownloadsScreen` & `DownloadService`: Chunked downloading via `extractor: ^1.0.0` and `dio`, progress notifications, pause/resume/cancel/retry, and offline playback.
  - `StatsScreen`: Listening statistics dashboard with `fl_chart` (Total listening time, Top songs, Top artists, Top genres, Daily/Weekly/Monthly charts).
  - `SettingsScreen`: Audio quality selector, crossfade slider, theme switcher (Dark Midnight, OLED, Dynamic, Light), cache manager, data backup/restore.
  - Unit tests (`audio_decryptor_test.dart`, `lrc_parser_test.dart`, `player_queue_test.dart`, `stats_calculator_test.dart`) and static analysis (`flutter analyze`).

---

## 📋 Part 2: Master Feature Checklist

---

### CORE PLAYBACK
- [x] Play / Pause
- [x] Previous / Next
- [x] Seek bar
- [x] Forward / Rewind
- [x] Shuffle
- [x] Repeat One
- [x] Repeat All
- [x] Repeat Off
- [x] Gapless Playback
- [x] Crossfade
- [x] AutoPlay
- [x] Resume Playback
- [x] Playback Speed
- [x] Volume Control
- [x] Audio Quality Selection
- [x] Background Playback
- [x] Lock Screen Controls
- [x] Notification Controls
- [x] Bluetooth Controls
- [x] Headphone Controls
- [x] Android Auto Support
- [x] Audio Focus Handling
- [x] Bluetooth Disconnect Handling
- [x] Media Session Integration

---

### NOW PLAYING
- [x] Full-screen Player
- [x] Large Album Artwork
- [x] Animated Album Artwork
- [x] Dynamic Artwork Colors
- [x] Blurred Artwork Background
- [x] Song Title
- [x] Artist
- [x] Album
- [x] Progress / Duration
- [x] Favorite Button
- [x] Share Button
- [x] Queue Button
- [x] Lyrics Button
- [x] Equalizer Button
- [x] More Options
- [x] Swipe Left/Right for Next/Previous
- [x] Mini Player
- [x] Expandable Mini Player
- [x] Audio Visualizer
- [x] Waveform Seek Bar

---

### QUEUE
- [x] Up Next
- [x] Add to Queue
- [x] Play Next
- [x] Remove from Queue
- [x] Drag & Drop Reorder
- [x] Clear Queue
- [x] Save Queue as Playlist
- [x] Shuffle Queue
- [x] Queue Persistence
- [x] Queue History
- [x] Multiple Queues

---

### ONLINE DISCOVERY
- [x] Home Feed
- [x] Trending Music
- [x] New Releases
- [x] Popular Songs
- [x] Popular Artists
- [x] Popular Albums
- [x] Charts
- [x] Genre Discovery
- [x] Mood Discovery
- [x] Featured Playlists
- [x] Recommended Songs
- [x] Recommended Artists
- [x] Related Songs
- [x] Artist Radio
- [ ] Song Radio
- [ ] Album Radio
- [x] Personalized Mixes
- [x] Daily Mix
- [ ] Discover Weekly-style Mix
- [x] Recently Played
- [x] Continue Listening

---

### SEARCH
- [x] Global Search
- [x] Instant Search
- [x] Search Suggestions
- [x] Search Autocomplete
- [x] Search History
- [x] Clear Search History
- [x] Voice Search
- [x] Search Songs
- [x] Search Artists
- [x] Search Albums
- [x] Search Playlists
- [x] Search Videos
- [x] Search Genres
- [x] Advanced Search Filters
- [ ] Sort Search Results
- [x] Online + Local Search

---

### ARTISTS
- [x] Artist Profile
- [x] Artist Artwork
- [x] Artist Biography
- [x] Popular Songs
- [x] Albums
- [x] Singles
- [ ] EPs
- [x] Related Artists
- [x] Artist Radio
- [x] Follow / Favorite Artist
- [x] Artist Search
- [x] Artist Discography

---

### ALBUMS
- [x] Album Page
- [x] Album Artwork
- [x] Album Artist
- [x] Release Year
- [x] Track List
- [x] Play Album
- [x] Shuffle Album
- [x] Add Album to Queue
- [ ] Add Album to Playlist
- [x] Favorite Album
- ### PLAYLISTS
- [x] Create Playlist
- [x] Rename Playlist
- [x] Delete Playlist
- [x] Add Songs
- [x] Remove Songs
- [x] Reorder Songs
- [x] Playlist Artwork
- [x] Playlist Description
- [x] Playlist Sharing
- [x] Duplicate Playlist
- [x] Export Playlist
- [x] Import Playlist
- [x] Smart Playlists
- [x] Auto-generated Playlists
- [ ] Collaborative Playlists (if supported)
- [x] Playlist Search

---

### FAVORITES / LIBRARY
- [x] Favorite Songs
- [x] Favorite Artists
- [x] Favorite Albums
- [x] Favorite Playlists
- [x] Recently Played
- [x] Most Played
- [x] Listening History
- [x] Full Listening History
- [x] Recently Added
- [x] Downloads
- [x] Cached Music
- [x] Library Search
- [x] Library Sorting
- [x] Library Filtering

---

### LYRICS
- [x] Lyrics Screen
- [x] Synced Lyrics
- [x] Line-by-Line Highlighting
- [x] Word-by-Word Lyrics
- [x] Karaoke Mode
- [x] Auto Scroll
- [x] Plain Lyrics Fallback
- [x] Lyrics Search
- [x] Lyrics Cache
- [x] Lyrics Offline Cache
- [x] Lyrics Font Size
- [x] Lyrics Theme
- [x] Jump to Lyric Timestamp

---

### AUDIO / EQUALIZER
- [x] Equalizer
- [x] 5-Band EQ
- [x] 10-Band EQ
- [ ] 20-Band EQ
- [x] Custom EQ
- [x] EQ Presets
- [x] Bass Boost
- [x] Virtualizer
- [x] Loudness Enhancement
- [x] Balance Control
- [x] Mono Audio
- [x] Stereo Enhancement
- [ ] ReplayGain
- [x] Volume Normalization
- [ ] Per-Song Volume
- [ ] Per-Artist EQ
- [ ] Per-Device EQ
- [x] Save EQ Profiles

---

### AUDIO VISUALIZER
- [x] Spectrum Analyzer
- [x] Frequency Bars
- [x] Wave Visualizer
- [x] Circular Visualizer
- [ ] Oscilloscope
- [x] Artwork Reactive Visualizer
- [x] Full-screen Visualizer
- [x] Visualizer FPS Control
- [x] Visualizer Enable/Disable

---

### DOWNLOADS / OFFLINE
- [x] Download Song
- [x] Download Album
- [x] Download Playlist
- [x] Download Queue
- [x] Download Progress
- [x] Pause Download
- [x] Resume Download
- [x] Cancel Download
- [x] Retry Failed Download
- [x] Download Manager
- [x] Download History
- [x] Download Quality
- [x] Wi-Fi Only Downloads
- [x] Storage Management
- [x] Automatic Cache Cleanup
- [x] Offline Mode
- [x] Offline Library
- [x] Offline Playlists

---

### SMART FEATURES
- [x] Smart Recommendations
- [x] Smart Queue
- [x] Auto Queue
- [ ] Song Radio
- [ ] Artist Radio
- [ ] Mood Mixes
- [ ] Genre Mixes
- [x] Similar Songs
- [ ] Recently Played Recommendations
- [ ] Time-based Recommendations
- [ ] Listening-based Recommendations
- [x] Most Played
- [ ] Favorite-based Recommendations
- [ ] Discovery History

---

### SLEEP / LISTENING UTILITIES
- [x] Sleep Timer
- [x] Fade-out Before Sleep
- [x] Stop After Current Song
- [ ] Stop After X Songs
- [ ] Music Alarm
- [ ] Focus Mode
- [ ] Relax Mode
- [ ] Workout Mode
- [ ] Driving Mode

---

### SHARING
- [x] Share Song
- [x] Share Album
- [x] Share Artist
- [x] Share Playlist
- [x] Copy Song Link
- [x] Copy Album Link
- [x] Generate Share Card
- [x] Social Share
- [x] QR Code for Playlist

---

### CONNECTIVITY
- [x] Wi-Fi Streaming
- [x] Mobile Data Streaming
- [x] Wi-Fi Only Mode
- [x] Network Quality Detection
- [x] Adaptive Streaming Quality
- [ ] Chromecast / Cast
- [x] Bluetooth Audio
- [ ] Android Auto
- [x] External Audio Devices
- [x] Network Error Recovery

---

### CACHE
- [x] Artwork Cache
- [x] Metadata Cache
- [x] Search Cache
- [x] Lyrics Cache
- [x] Stream Cache where permitted
- [x] Cache Size Limit
- [x] Clear Cache
- [x] Automatic Cache Cleanup
- [x] Cache Statistics

---

### PERSONALIZATION
- [x] Light Theme
- [x] Dark Theme
- [x] AMOLED Theme
- [x] System Theme
- [x] Dynamic Colors
- [x] Custom Accent Color
- [x] Artwork-based Theme
- [x] Custom Player Background
- [x] Player Animations
- [x] Custom Mini Player
- [x] Custom Navigation Bar
- [x] Compact / Comfortable Layout
- [x] Customizable Home Sections

---

### STATISTICS
- [x] Total Listening Time
- [x] Songs Played
- [x] Top Songs
- [x] Top Artists
- [x] Top Albums
- [x] Top Genres
- [x] Daily Statistics
- [x] Weekly Statistics
- [x] Monthly Statistics
- [x] Yearly Statistics
- [x] Listening Streak
- [x] Discovery Statistics
- [x] Play Count
- [x] Export Statistics

---

### DATA / PRIVACY
- [x] No unnecessary account requirement
- [x] Local-first settings
- [x] Clear Search History
- [x] Clear Listening History
- [x] Clear Cache
- [x] Export App Data
- [x] Import App Data
- [x] Backup Playlists
- [x] Restore Playlists
- [x] Privacy Controls
- [x] Network Usage Statistics

---

### ACCESSIBILITY
- [x] Screen Reader Support
- [x] Semantic Labels
- [x] Large Text Support
- [x] High Contrast
- [x] Large Touch Targets
- [x] Reduced Motion
- [x] Keyboard Navigation
- [x] Accessible Player Controls

---

### PERFORMANCE
- [x] Lazy Loading
- [x] Image Caching
- [x] Pagination
- [x] Search Debouncing
- [x] Background Data Loading
- [x] Fast App Startup
- [x] Low Memory Usage
- [x] Low Battery Usage
- [x] Smooth Scrolling
- [x] Efficient Database Queries
- [x] Automatic Retry
- [x] Network Timeout Handling
- [x] Offline-first Fallback

---

### ERROR STATES
- [x] No Internet
- [x] Song Unavailable
- [x] Stream Failed
- [x] Provider Unavailable
- [x] Search Failed
- [x] Lyrics Unavailable
- [x] Artwork Unavailable
- [x] Download Failed
- [x] Unsupported Format
- [x] Storage Full
- [x] Permission Denied
- [x] Retry Button
- [x] Graceful Provider Fallback

---

### MODERN UI COMPONENTS
- [x] Material 3 Design
- [x] Glass / Blur Effects
- [x] Rounded Cards
- [x] Dynamic Gradients
- [x] Skeleton Loading
- [x] Smooth Page Transitions
- [x] Animated Bottom Sheets
- [x] Swipe Gestures
- [x] Pull to Refresh
- [x] Context Menus
- [x] Bottom Sheet Actions
- [x] Haptic Feedback
- [x] Micro Animations
- [x] Empty States
- [x] Error States
- [x] Responsive Layout

---

### ADVANCED FEATURES
- [x] Multi-source Music Providers
- [x] Provider Fallback
- [x] Provider Priority
- [x] Source Quality Selection
- [x] Audio Quality Badges
- [x] Track Metadata Normalization
- [x] Duplicate Song Detection
- [x] Smart Song Matching
- [x] Automatic Artwork Matching
- [x] Automatic Artist Matching
- [x] Cross-source Search
- [x] Cross-source Queue
- [x] Universal Track Model
- [x] Universal Playlist Model

---

### SETTINGS
- [x] Playback Settings
- [x] Audio Settings
- [x] Equalizer Settings
- [x] Streaming Settings
- [x] Download Settings
- [x] Cache Settings
- [x] Appearance Settings
- [x] Library Settings
- [x] Notification Settings
- [x] Privacy Settings
- [x] Data Management
- [x] Language Selection
- [x] About Orbitune
- [x] Open Source Licenses
- [x] Version Information

---

### EXTRA PREMIUM FEATURES
- [x] Hi-Res Audio Badge
- [x] Lossless Audio Badge
- [x] Bitrate Display
- [x] Codec Display
- [x] Sample Rate Display
- [x] Audio Output Information
- [x] Real-time Audio Spectrum
- [x] Crossfade Custom Duration
- [x] Gapless Album Mode
- [x] ReplayGain
- [x] Smart Volume Normalization
- [x] Advanced Queue Editor
- [x] Listening Insights
- [x] Smart Mix Generator
- [ ] Custom Radio Stations
- [ ] Home Screen Widget
- [ ] Lock Screen Player
- [ ] Android Auto Interface
- [ ] Wearable / Watch Controls
