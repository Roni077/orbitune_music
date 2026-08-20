# Orbitune - Comprehensive Project Directory & Architecture Tree

This document details the Feature-First / Clean Architecture structure for the **Orbitune** modern Flutter music player, powered by **Material 3 Expressive** and the **Extractor** media engine.

---

## High-Level Architecture Overview

```
┌────────────────────────────────────────────────────────────────────────┐
│             Presentation Layer (Material 3 Expressive)                 │
│  - M3E Expressive Screens (Home, Search, FullPlayer, Lyrics, Library)  │
│  - M3E Components (Expressive Cards, Shapes, Sliders, Spring Buttons)  │
│  - Riverpod State Notifiers & ViewModels                               │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                           Domain Layer                                 │
│  - Core Entities (Track, Album, Artist, Playlist, Lyrics, Stats)       │
│  - Audio Engine Interfaces & State Machines                            │
│  - Use Cases & Repository Contracts                                    │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                            Data Layer                                  │
│  - Extractor Media Engine (`extractor: ^1.0.0`)                        │
│  - YouTube Explode Client & JioSaavn API + DES Decryptor               │
│  - Synced Lyrics Providers (LRCLIB REST API)                           │
│  - Local Data Sources (Hive DB Boxes, File Downloader via Dio)         │
│  - Native Audio Service (JustAudio + JustAudioBackground)              │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                            Core Layer                                  │
│  - M3E Theme Engine (Dark Midnight, OLED, Dynamic Palette Generator)   │
│  - Audio Session Handler (Audio Focus, Interruption, Noisy Headset)    │
│  - Network Connectivity & Offline Cache Manager                        │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Detailed Directory Tree

```
orbitune/
├── .github/
│   └── workflows/
│       └── flutter_ci.yaml             # Automated lint and test CI
├── docs/
│   ├── packages.md                     # Complete dependencies & native platform manifests
│   ├── phases.md                       # Comprehensive phases with feature tracking checkboxes
│   └── project-tree.md                 # Detailed architecture and directory layout
├── assets/
│   ├── icons/
│   │   ├── app_logo.png                # High-res vector brand logo
│   │   └── waveforms/                  # Audio waveform SVG presets
│   ├── images/
│   │   ├── default_cover.png           # Fallback album artwork
│   │   ├── default_artist.png          # Fallback artist avatar
│   │   └── default_playlist.png        # Fallback playlist artwork
│   └── fonts/                          # Fallback embedded fonts if offline
│
├── lib/
│   ├── main.dart                       # Entry point: Hive init, Background Service init, runApp
│   ├── app.dart                        # MaterialApp.router / ProviderScope wrapper, Theme listener
│   │
│   ├── core/                           # Core infrastructure, themes, utilities & shared widgets
│   │   ├── constants/
│   │   │   ├── api_endpoints.dart      # JioSaavn API, YouTube endpoints, LRCLIB API constants
│   │   │   ├── app_colors.dart         # Deep Midnight, OLED Black, Neon Accent color palettes
│   │   │   ├── app_constants.dart      # Standard animation durations, curve tokens, border radii
│   │   │   ├── app_typography.dart     # Google Fonts Righteous & Poppins typographic hierarchy
│   │   │   └── hive_boxes.dart         # Hive box names & storage keys
│   │   ├── errors/
│   │   │   ├── exceptions.dart         # NetworkException, AudioStreamException, DecryptionException
│   │   │   └── failures.dart           # User-facing failure representations & retry models
│   │   ├── network/
│   │   │   ├── api_client.dart         # Dio & HTTP base client wrapper with retry & cache headers
│   │   │   └── connectivity_service.dart# Connectivity listener (Wi-Fi, Mobile Data, Offline)
│   │   ├── theme/
│   │   │   ├── app_theme.dart          # Material 3 Expressive ThemeData (Dark Midnight, OLED, Light)
│   │   │   ├── color_schemes.dart      # Dynamic ColorScheme generator from PaletteGenerator
│   │   │   ├── expressive_shapes.dart  # Material 3 Expressive corner shape morph tokens
│   │   │   └── theme_provider.dart     # ThemeMode state notifier (Dark, OLED, Dynamic, Light)
│   │   ├── utils/
│   │   │   ├── audio_decryptor.dart    # JioSaavn DES-ECB URL decryption (38346591 cipher key)
│   │   │   ├── formatters.dart         # Duration (03:45), Bitrate (320kbps), Play counts, Dates
│   │   │   ├── lrc_parser.dart         # Synchronized LRC lyrics parser (.lrc string to timestamps)
│   │   │   ├── palette_helper.dart     # Dynamic dominant and vibrant color extractor from images
│   │   │   └── share_helper.dart       # Share card generator and native OS share dialog
│   │   └── widgets/
│   │       ├── animated_play_button.dart# Morphing play/pause button with spring feedback
│   │       ├── audio_badge.dart        # Hi-Res, 320kbps, Lossless, YouTube badges
│   │       ├── custom_app_bar.dart     # Translucent blurred app bar with actions
│   │       ├── custom_bottom_nav.dart  # M3E floating bottom navigation bar
│   │       ├── empty_state_view.dart   # Clean empty state with icon, message & action button
│   │       ├── error_view.dart         # Network error & stream failure view with retry button
│   │       ├── expressive_card.dart    # Material 3 Expressive morphable container with spring touch
│   │       ├── glass_container.dart    # Frosted glass blur container with border gradient
│   │       ├── image_shimmer.dart      # Skeleton shimmer placeholder for images & avatars
│   │       ├── modern_slider.dart      # M3E styled slider for audio seek & equalizer bands
│   │       └── section_header.dart     # Section title with optional 'See All' action button
│   │
│   ├── features/                       # Modular feature domains
│   │   │
│   │   ├── audio_player/               # Core playback engine, audio session & queue management
│   │   │   ├── data/
│   │   │   │   ├── audio_handler.dart  # JustAudioBackground media handler & MediaItem sync
│   │   │   │   └── player_repository.dart# Multi-source audio stream resolver (Saavn/YT/Extractor)
│   │   │   ├── domain/
│   │   │   │   ├── models/
│   │   │   │   │   ├── audio_quality.dart   # Low (96k), Medium (160k), High (320k)
│   │   │   │   │   ├── playback_mode.dart   # Shuffle, RepeatOne, RepeatAll, Off
│   │   │   │   │   ├── playback_state.dart  # Playing, Buffering, Paused, Completed, Error
│   │   │   │   │   ├── queue_item.dart      # Queue element with origin & priority
│   │   │   │   │   └── track.dart           # Unified track model (ID, Title, Artist, URLs, Duration)
│   │   │   │   └── services/
│   │   │   │       ├── audio_player_service.dart# JustAudio controller (gapless, speed, volume)
│   │   │   │       └── audio_session_service.dart# Interruption & noisy headset handler
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   ├── player_provider.dart      # Active playback state, position, buffer, track
│   │   │       │   ├── queue_provider.dart       # Up-next list, reorder, shuffle, auto-queue
│   │   │       │   └── sleep_timer_provider.dart # Sleep timer countdown & fade-out controller
│   │   │       ├── screens/
│   │   │       │   ├── full_player_screen.dart   # Immersive fullscreen player with dynamic gradient
│   │   │       │   ├── queue_sheet.dart          # Draggable reorderable queue modal
│   │   │       │   └── sleep_timer_sheet.dart    # Sleep timer picker (15m, 30m, 60m, end of track)
│   │   │       └── widgets/
│   │   │           ├── artwork_disc_view.dart    # Rotating vinyl disc or rounded artwork with shadows
│   │   │           ├── mini_player.dart          # Expandable floating MiniPlayer with gestures
│   │   │           ├── player_controls.dart      # Prev, Next, Play/Pause, Shuffle, Loop buttons
│   │   │           ├── player_header.dart        # FullPlayer header with collapse, source badge, share
│   │   │           ├── volume_speed_slider.dart  # Playback speed (0.5x-2.0x) & volume controller
│   │   │           └── waveform_seek_bar.dart    # Waveform-styled progress bar with seek preview
│   │   │
│   │   ├── discovery/                  # Home feed, trending charts, radio & mixes
│   │   │   ├── data/
│   │   │   │   └── discovery_repository.dart     # Fetches charts, trending tracks, daily mixes
│   │   │   ├── domain/
│   │   │   │   └── models/
│   │   │   │       ├── chart_playlist.dart       # Top 50, Viral Hits, Bollywood Top 20
│   │   │   │       ├── home_section.dart         # Dynamic section rows (Quick Picks, New Releases)
│   │   │   │       └── trending_item.dart        # Featured hero banner data
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── home_provider.dart        # Discovery feed state & pull-to-refresh
│   │   │       ├── screens/
│   │   │       │   └── home_screen.dart          # Main discovery dashboard with M3E cards
│   │   │       └── widgets/
│   │   │           ├── banner_carousel.dart      # Hero carousel with parallax & gradient overlay
│   │   │           ├── greeting_header.dart      # 'Good Evening' greeting with profile avatar
│   │   │           ├── quick_picks_grid.dart     # 2x3 quick launch grid for recently played
│   │   │           ├── song_card_horizontal.dart # M3E rounded card for playlists & albums
│   │   │           └── trending_chips.dart       # Genre & language pills (Hindi, English, Punjabi)
│   │   │
│   │   ├── search/                     # YouTube Music & Extractor search & stream resolution
│   │   │   ├── data/
│   │   │   │   ├── search_cache_repository.dart# Hive search caching
│   │   │   │   ├── search_repository.dart    # Search aggregator, channel/artist search & stream resolver
│   │   │   │   └── youtube_source.dart       # YouTube Explode pure audio streaming, client rotation & discovery
│   │   │   ├── domain/
│   │   │   │   └── models/
│   │   │   │       ├── album_model.dart          # Album details & song list
│   │   │   │       ├── artist_model.dart         # Artist details, bio & top songs
│   │   │   │       └── playlist_model.dart       # Playlist metadata & items
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   ├── album_detail_provider.dart# Album discography notifier
│   │   │       │   ├── artist_detail_provider.dart# Artist profile notifier
│   │   │       │   └── search_provider.dart      # Search query, filter chips & debounced stream
│   │   │       ├── screens/
│   │   │       │   ├── album_detail_screen.dart  # Album page with full tracklist & play all
│   │   │       │   ├── artist_detail_screen.dart # Artist page with discography & top singles
│   │   │       │   ├── playlist_detail_screen.dart # Playlist tracklist with reorder & play
│   │   │       │   └── search_screen.dart        # Universal search with instant suggestions
│   │   │       └── widgets/
│   │   │           ├── filter_source_bar.dart    # All / YouTube Music toggle
│   │   │           ├── recent_searches_view.dart # Search history chips with clear all
│   │   │           ├── search_bar_widget.dart    # Glowing search bar with clear button
│   │   │           └── track_tile.dart           # Song list item with menu, like & play action
│   │   │
│   │   ├── lyrics/                     # Synchronized LRC & Plain lyrics viewer
│   │   │   ├── data/
│   │   │   │   ├── lyrics_cache_repository.dart # Hive cached lyrics storage
│   │   │   │   └── lyrics_repository.dart    # LRCLIB API client (`lrclib.net`)
│   │   │   ├── domain/
│   │   │   │   └── models/
│   │   │   │       └── lyric_line.dart       # Timestamp and lyric line text
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── lyrics_provider.dart  # Active lyric line sync & auto-scroll notifier
│   │   │       ├── screens/
│   │   │       │   └── lyrics_screen.dart    # Fullscreen karaoke lyrics view
│   │   │       └── widgets/
│   │   │           ├── lrc_view.dart         # Synced lyrics with glowing active line & tap-to-seek
│   │   │           └── plain_lyrics_view.dart# Static text lyrics view
│   │   │
│   │   ├── equalizer/                  # Audio Equalizer & Sound enhancement controls
│   │   │   ├── domain/
│   │   │   │   └── models/
│   │   │   │       ├── eq_preset.dart        # Rock, Pop, Jazz, Classical, Bass Boost, Vocal
│   │   │   │       └── eq_profile.dart       # Custom 5-Band / 10-Band frequencies and gains
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── equalizer_provider.dart# EQ state, active preset, bass boost, virtualizer
│   │   │       └── screens/
│   │   │           └── equalizer_screen.dart # Equalizer UI with M3E sliders & preset chips
│   │   │
│   │   ├── visualizer/                 # Real-time audio spectrum & waveform visualizers
│   │   │   ├── presentation/
│   │   │   │   ├── providers/
│   │   │   │   │   └── visualizer_provider.dart# Visualizer FPS, mode (Bars, Wave, Circle, Disc)
│   │   │   │   └── widgets/
│   │   │   │       ├── bar_visualizer.dart    # Frequency bar visualizer
│   │   │   │       ├── circular_visualizer.dart# Pulsating radial audio visualizer
│   │   │   │       └── wave_visualizer.dart   # Smooth sine-wave visualizer
│   │   │
│   │   ├── library/                    # User Library, Favorites, Playlists, History & Stats
│   │   │   ├── data/
│   │   │   │   └── library_repository.dart   # Hive CRUD operations for user data
│   │   │   ├── domain/
│   │   │   │   └── models/
│   │   │   │       ├── favorite_song.dart    # Liked song entity with timestamp
│   │   │   │       ├── history_item.dart     # Recently played item with play count
│   │   │   │       ├── listening_stats.dart  # Listening duration, top artists & genres
│   │   │   │       └── user_playlist.dart    # Custom user-created playlist entity
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   ├── favorites_provider.dart
│   │   │       │   ├── history_provider.dart
│   │   │       │   ├── stats_provider.dart
│   │   │       │   └── user_playlists_provider.dart
│   │   │       ├── screens/
│   │   │       │   ├── favorites_screen.dart
│   │   │       │   ├── history_screen.dart
│   │   │       │   ├── library_screen.dart
│   │   │       │   ├── playlist_view_screen.dart
│   │   │       │   └── stats_screen.dart     # Interactive listening statistics charts
│   │   │       └── widgets/
│   │   │           ├── create_playlist_dialog.dart
│   │   │           ├── favorite_button.dart  # Animated heart button
│   │   │           └── library_card.dart
│   │   │
│   │   ├── downloader/                 # Extractor Media Downloader & Offline Storage
│   │   │   ├── data/
│   │   │   │   ├── extractor_service.dart    # Extractor engine wrapper (`extractor: ^1.0.0`)
│   │   │   │   └── download_service.dart     # Dio chunked file downloader & tagger
│   │   │   ├── domain/
│   │   │   │   └── models/
│   │   │   │       └── download_task.dart    # Download progress, file path, status, quality
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── download_provider.dart# Active downloads list & progress notifier
│   │   │       ├── screens/
│   │   │       │   └── downloads_screen.dart # Downloaded songs offline player
│   │   │       └── widgets/
│   │   │           └── download_tile.dart    # Progress indicator, cancel & delete actions
│   │   │
│   │   └── settings/                   # Audio Quality, Theme, Cache, Data Backup & Privacy
│   │       ├── domain/
│   │       │   └── models/
│   │       │       └── app_settings.dart     # Streaming quality, theme, cache limits, Wi-Fi only
│   │       └── presentation/
│   │           ├── providers/
│   │           │   └── settings_provider.dart
│   │           └── screens/
│   │               ├── about_screen.dart
│   │               ├── backup_restore_screen.dart
│   │               └── settings_screen.dart
│   │
│   └── shell/
│       └── main_navigation_shell.dart        # Persistent M3E bottom nav bar + MiniPlayer overlay
│
└── test/
    ├── unit/
    │   ├── audio_decryptor_test.dart         # JioSaavn DES decryption validation
    │   ├── lrc_parser_test.dart              # LRC timestamps & line matching tests
    │   ├── player_queue_test.dart            # Queue operations, shuffle & repeat tests
    │   └── stats_calculator_test.dart        # Listening statistics calculation tests
    └── widget/
        ├── mini_player_test.dart             # MiniPlayer gesture & state tests
        ├── full_player_test.dart             # Fullscreen player controls & seeker tests
        └── track_tile_test.dart              # Track tile actions & layout tests
```
