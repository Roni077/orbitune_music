import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:orbitune/core/constants/api_endpoints.dart';
import 'package:orbitune/core/utils/audio_decryptor.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/search/domain/models/album_model.dart';
import 'package:orbitune/features/search/domain/models/artist_model.dart';
import 'package:orbitune/features/search/domain/models/playlist_model.dart';
import 'package:orbitune/features/search/domain/models/search_result.dart';

/// Client for JioSaavn API with direct 320kbps DES decryption + Saavn.dev mirror fallback
class JioSaavnSource {
  final http.Client _client;

  JioSaavnSource({http.Client? client}) : _client = client ?? http.Client();

  static const Map<String, String> _defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'application/json, text/plain, */*',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  /// Universal global search across songs, albums, artists, and playlists
  Future<SearchResult> searchAll(String query, {int page = 1, int limit = 20}) async {
    if (query.trim().isEmpty) return SearchResult(query: query, source: 'jiosaavn');

    try {
      // 1. Try Direct JioSaavn Autocomplete/Search API
      final directUrl = Uri.parse(
        '${ApiEndpoints.jioSaavnDirectBase}?__call=autocomplete.get&query=${Uri.encodeComponent(query)}&_format=json&_marker=0&api_version=4&ctx=web6dot0',
      );

      final response = await _client.get(directUrl, headers: _defaultHeaders).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = _parseJsonBody(response.body);
        if (data != null && data is Map) {
          final songs = await _parseDirectSongsList(data['songs']?['data']);
          final albums = _parseDirectAlbumsList(data['albums']?['data']);
          final artists = _parseDirectArtistsList(data['artists']?['data']);
          final playlists = _parseDirectPlaylistsList(data['playlists']?['data']);

          if (songs.isNotEmpty || albums.isNotEmpty || artists.isNotEmpty || playlists.isNotEmpty) {
            return SearchResult(
              query: query,
              source: 'jiosaavn',
              songs: songs,
              albums: albums,
              artists: artists,
              playlists: playlists,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[JioSaavnSource] direct searchAll failed, attempting mirror: $e');
    }

    // 2. Fallback to saavn.dev mirror
    return _searchAllMirror(query, page: page, limit: limit);
  }

  /// Searches only for songs
  Future<List<Track>> searchSongs(String query, {int page = 1, int limit = 20}) async {
    if (query.trim().isEmpty) return const [];

    try {
      final directUrl = Uri.parse(
        '${ApiEndpoints.jioSaavnDirectBase}?__call=search.getResults&q=${Uri.encodeComponent(query)}&p=$page&n=$limit&_format=json&_marker=0&api_version=4&ctx=web6dot0',
      );

      final response = await _client.get(directUrl, headers: _defaultHeaders).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = _parseJsonBody(response.body);
        if (data != null && data is Map && data['results'] != null) {
          final results = data['results'] as List;
          final tracks = await _parseDirectSongsList(results);
          if (tracks.isNotEmpty) return tracks;
        }
      }
    } catch (e) {
      debugPrint('[JioSaavnSource] direct searchSongs failed, trying mirror: $e');
    }

    return _searchSongsMirror(query, page: page, limit: limit);
  }

  /// Fetches complete details of a song by ID
  Future<Track?> getSongDetails(String songId) async {
    try {
      final directUrl = Uri.parse(
        '${ApiEndpoints.jioSaavnDirectBase}?__call=song.getDetails&pids=$songId&_format=json&_marker=0&api_version=4&ctx=web6dot0',
      );

      final response = await _client.get(directUrl, headers: _defaultHeaders).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = _parseJsonBody(response.body);
        if (data != null && data is Map) {
          final songData = data[songId] ?? (data['songs'] != null && (data['songs'] as List).isNotEmpty ? data['songs'][0] : null);
          if (songData != null && songData is Map) {
            return _parseDirectSongItem(songData);
          }
        }
      }
    } catch (e) {
      debugPrint('[JioSaavnSource] direct getSongDetails failed, trying mirror: $e');
    }

    return _getSongDetailsMirror(songId);
  }

  /// Fetches album details along with tracklist
  Future<AlbumModel?> getAlbumDetails(String albumId) async {
    try {
      final directUrl = Uri.parse(
        '${ApiEndpoints.jioSaavnDirectBase}?__call=content.getAlbumDetails&albumid=$albumId&_format=json&_marker=0&api_version=4&ctx=web6dot0',
      );

      final response = await _client.get(directUrl, headers: _defaultHeaders).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = _parseJsonBody(response.body);
        if (data != null && data is Map && data['title'] != null) {
          final songs = await _parseDirectSongsList(data['songs'] ?? data['list']);
          return AlbumModel(
            id: data['id']?.toString() ?? albumId,
            title: AudioDecryptor.cleanHtmlEntities(data['title']?.toString() ?? ''),
            artist: AudioDecryptor.cleanHtmlEntities(data['primary_artists']?.toString() ?? data['artist']?.toString() ?? ''),
            artworkUrl: data['image']?.toString(),
            highResArtworkUrl: AudioDecryptor.formatHighResArtwork(data['image']?.toString()),
            releaseYear: data['year']?.toString(),
            totalTracks: songs.length,
            songs: songs,
            source: 'jiosaavn',
            language: data['language']?.toString(),
          );
        }
      }
    } catch (e) {
      debugPrint('[JioSaavnSource] direct getAlbumDetails failed, trying mirror: $e');
    }

    return _getAlbumDetailsMirror(albumId);
  }

  /// Fetches playlist details along with its tracks
  Future<PlaylistModel?> getPlaylistDetails(String playlistId) async {
    try {
      final directUrl = Uri.parse(
        '${ApiEndpoints.jioSaavnDirectBase}?__call=playlist.getDetails&listid=$playlistId&_format=json&_marker=0&api_version=4&ctx=web6dot0',
      );

      final response = await _client.get(directUrl, headers: _defaultHeaders).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = _parseJsonBody(response.body);
        if (data != null && data is Map && data['listname'] != null) {
          final songs = await _parseDirectSongsList(data['songs'] ?? data['list']);
          return PlaylistModel(
            id: data['listid']?.toString() ?? playlistId,
            title: AudioDecryptor.cleanHtmlEntities(data['listname']?.toString() ?? ''),
            description: data['description']?.toString(),
            author: data['firstname']?.toString(),
            artworkUrl: data['image']?.toString(),
            highResArtworkUrl: AudioDecryptor.formatHighResArtwork(data['image']?.toString()),
            trackCount: songs.length,
            songs: songs,
            source: 'jiosaavn',
            language: data['language']?.toString(),
          );
        }
      }
    } catch (e) {
      debugPrint('[JioSaavnSource] direct getPlaylistDetails failed, trying mirror: $e');
    }

    return _getPlaylistDetailsMirror(playlistId);
  }

  /// Fetches artist details, top songs, and albums
  Future<ArtistModel?> getArtistDetails(String artistId) async {
    try {
      final directUrl = Uri.parse(
        '${ApiEndpoints.jioSaavnDirectBase}?__call=artist.getArtistPageDetails&artistId=$artistId&_format=json&_marker=0&api_version=4&ctx=web6dot0',
      );

      final response = await _client.get(directUrl, headers: _defaultHeaders).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = _parseJsonBody(response.body);
        if (data != null && data is Map && data['name'] != null) {
          final topSongs = await _parseDirectSongsList(data['topSongs'] ?? data['songs']);
          final albums = _parseDirectAlbumsList(data['topAlbums'] ?? data['albums']);
          final singles = await _parseDirectSongsList(data['singles']);

          return ArtistModel(
            id: data['artistId']?.toString() ?? artistId,
            name: AudioDecryptor.cleanHtmlEntities(data['name']?.toString() ?? ''),
            avatarUrl: data['image']?.toString(),
            bannerUrl: AudioDecryptor.formatHighResArtwork(data['image']?.toString()),
            bio: data['bio']?.toString(),
            fansCount: (data['fan_count'] as num?)?.toInt() ?? 0,
            topTracks: topSongs,
            albums: albums,
            singles: singles,
            source: 'jiosaavn',
          );
        }
      }
    } catch (e) {
      debugPrint('[JioSaavnSource] direct getArtistDetails failed, trying mirror: $e');
    }

    return _getArtistDetailsMirror(artistId);
  }

  /// Fetches song recommendations / Radio based on [songId]
  Future<List<Track>> getSongRecommendations(String songId, {int limit = 15}) async {
    try {
      final directUrl = Uri.parse(
        '${ApiEndpoints.jioSaavnDirectBase}?__call=reco.getrecos&pid=$songId&_format=json&_marker=0&api_version=4&ctx=web6dot0',
      );

      final response = await _client.get(directUrl, headers: _defaultHeaders).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = _parseJsonBody(response.body);
        if (data != null && data is List) {
          return await _parseDirectSongsList(data);
        }
      }
    } catch (e) {
      debugPrint('[JioSaavnSource] direct getSongRecommendations failed: $e');
    }

    return const [];
  }

  /// Fetches trending / discovery modules
  Future<Map<String, dynamic>> getTrendingModules({String language = 'hindi,english'}) async {
    try {
      final url = Uri.parse('${ApiEndpoints.jioSaavnApiMirror}/modules?language=$language');
      final response = await _client.get(url, headers: _defaultHeaders).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          final modules = data['data'] as Map<String, dynamic>;
          final trendingSongs = <Track>[];
          final charts = <PlaylistModel>[];
          final topAlbums = <AlbumModel>[];

          if (modules['trending']?['songs'] != null) {
            for (final s in (modules['trending']['songs'] as List)) {
              final track = _parseMirrorSongItem(s as Map<String, dynamic>);
              if (track != null) trendingSongs.add(track);
            }
          }

          if (modules['charts'] != null) {
            for (final c in (modules['charts'] as List)) {
              final p = _parseMirrorPlaylistItem(c as Map<String, dynamic>);
              if (p != null) charts.add(p);
            }
          }

          if (modules['albums'] != null) {
            for (final a in (modules['albums'] as List)) {
              final alb = _parseMirrorAlbumItem(a as Map<String, dynamic>);
              if (alb != null) topAlbums.add(alb);
            }
          }

          return {
            'trendingSongs': trendingSongs,
            'charts': charts,
            'albums': topAlbums,
          };
        }
      }
    } catch (e) {
      debugPrint('[JioSaavnSource] getTrendingModules error: $e');
    }

    return {
      'trendingSongs': <Track>[],
      'charts': <PlaylistModel>[],
      'albums': <AlbumModel>[],
    };
  }

  /// Fetches synced / plain lyrics for a song
  Future<String?> getLyrics(String songId) async {
    try {
      final url = Uri.parse(
        '${ApiEndpoints.jioSaavnDirectBase}?__call=lyrics.getLyrics&lyrics_id=$songId&_format=json&_marker=0&api_version=4&ctx=web6dot0',
      );

      final response = await _client.get(url, headers: _defaultHeaders).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = _parseJsonBody(response.body);
        if (data != null && data is Map && data['lyrics'] != null) {
          return AudioDecryptor.cleanHtmlEntities(data['lyrics'].toString());
        }
      }
    } catch (e) {
      debugPrint('[JioSaavnSource] getLyrics error: $e');
    }
    return null;
  }

  // -------------------------------------------------------------
  // Direct JioSaavn API Parsers & Helpers
  // -------------------------------------------------------------

  dynamic _parseJsonBody(String body) {
    try {
      var cleaned = body.trim();
      // Remove JSONP padding or trailing HTML comment tags if any
      if (cleaned.startsWith('/**/') || cleaned.startsWith('//')) {
        final firstBrace = cleaned.indexOf('{');
        final firstBracket = cleaned.indexOf('[');
        int start = -1;
        if (firstBrace != -1 && (firstBracket == -1 || firstBrace < firstBracket)) {
          start = firstBrace;
        } else if (firstBracket != -1) {
          start = firstBracket;
        }
        if (start != -1) {
          cleaned = cleaned.substring(start);
        }
      }
      return jsonDecode(cleaned);
    } catch (_) {
      return null;
    }
  }

  Future<List<Track>> _parseDirectSongsList(dynamic list) async {
    if (list == null || list is! List) return const [];
    final List<Track> tracks = [];
    for (final item in list) {
      if (item is Map) {
        final t = _parseDirectSongItem(item);
        if (t != null) tracks.add(t);
      }
    }
    return tracks;
  }

  Track? _parseDirectSongItem(Map<dynamic, dynamic> item) {
    final id = item['id']?.toString() ?? item['song_id']?.toString();
    if (id == null || id.isEmpty) return null;

    final rawTitle = item['song']?.toString() ?? item['title']?.toString() ?? 'Unknown Track';
    final cleanedTitle = AudioDecryptor.cleanTrackTitle(rawTitle);
    final rawArtist = item['primary_artists']?.toString() ??
        item['singers']?.toString() ??
        item['artist']?.toString() ??
        item['music']?.toString() ??
        'Unknown Artist';
    final artist = AudioDecryptor.cleanHtmlEntities(rawArtist);
    final album = AudioDecryptor.cleanHtmlEntities(item['album']?.toString() ?? '');

    final durationSeconds = (item['duration'] as num?)?.toInt() ?? int.tryParse(item['duration']?.toString() ?? '0') ?? 0;
    final artwork = item['image']?.toString();
    final highResArtwork = AudioDecryptor.formatHighResArtwork(artwork);

    // Decrypt 320kbps direct audio stream URL
    final encryptedMediaUrl = item['encrypted_media_url']?.toString();
    final decryptedUrl = AudioDecryptor.decryptMediaUrl(encryptedMediaUrl, quality: AudioQuality.high320k);

    final releaseDate = item['release_date']?.toString() ?? item['year']?.toString();
    final language = item['language']?.toString();
    final hasLyrics = item['has_lyrics'] == 'true' || item['has_lyrics'] == true;

    return Track(
      id: id,
      title: cleanedTitle.isNotEmpty ? cleanedTitle : rawTitle,
      artist: artist.isNotEmpty ? artist : 'Unknown Artist',
      album: album.isNotEmpty ? album : null,
      duration: Duration(seconds: durationSeconds),
      artworkUrl: artwork,
      highResArtworkUrl: highResArtwork,
      streamUrl: decryptedUrl,
      downloadUrl: decryptedUrl,
      source: 'jiosaavn',
      bitrate: 320,
      audioQuality: AudioQuality.high320k,
      releaseDate: releaseDate,
      language: language,
      hasSyncedLyrics: hasLyrics,
      extra: {
        'encrypted_media_url': encryptedMediaUrl,
        'perma_url': item['perma_url'],
        'play_count': item['play_count'],
        'copyright_text': item['copyright_text'],
      },
    );
  }

  List<AlbumModel> _parseDirectAlbumsList(dynamic list) {
    if (list == null || list is! List) return const [];
    final List<AlbumModel> albums = [];
    for (final item in list) {
      if (item is Map) {
        final id = item['id']?.toString() ?? item['albumid']?.toString();
        if (id != null && id.isNotEmpty) {
          albums.add(AlbumModel(
            id: id,
            title: AudioDecryptor.cleanHtmlEntities(item['title']?.toString() ?? item['name']?.toString() ?? ''),
            artist: AudioDecryptor.cleanHtmlEntities(item['artist']?.toString() ?? item['primary_artists']?.toString() ?? ''),
            artworkUrl: item['image']?.toString(),
            highResArtworkUrl: AudioDecryptor.formatHighResArtwork(item['image']?.toString()),
            releaseYear: item['year']?.toString(),
            source: 'jiosaavn',
            language: item['language']?.toString(),
          ));
        }
      }
    }
    return albums;
  }

  List<ArtistModel> _parseDirectArtistsList(dynamic list) {
    if (list == null || list is! List) return const [];
    final List<ArtistModel> artists = [];
    for (final item in list) {
      if (item is Map) {
        final id = item['id']?.toString() ?? item['artistid']?.toString();
        if (id != null && id.isNotEmpty) {
          artists.add(ArtistModel(
            id: id,
            name: AudioDecryptor.cleanHtmlEntities(item['name']?.toString() ?? item['title']?.toString() ?? ''),
            avatarUrl: item['image']?.toString(),
            bannerUrl: AudioDecryptor.formatHighResArtwork(item['image']?.toString()),
            bio: item['description']?.toString(),
            source: 'jiosaavn',
          ));
        }
      }
    }
    return artists;
  }

  List<PlaylistModel> _parseDirectPlaylistsList(dynamic list) {
    if (list == null || list is! List) return const [];
    final List<PlaylistModel> playlists = [];
    for (final item in list) {
      if (item is Map) {
        final id = item['id']?.toString() ?? item['listid']?.toString();
        if (id != null && id.isNotEmpty) {
          playlists.add(PlaylistModel(
            id: id,
            title: AudioDecryptor.cleanHtmlEntities(item['title']?.toString() ?? item['name']?.toString() ?? item['listname']?.toString() ?? ''),
            description: item['description']?.toString(),
            author: item['firstname']?.toString(),
            artworkUrl: item['image']?.toString(),
            highResArtworkUrl: AudioDecryptor.formatHighResArtwork(item['image']?.toString()),
            source: 'jiosaavn',
            language: item['language']?.toString(),
          ));
        }
      }
    }
    return playlists;
  }

  // -------------------------------------------------------------
  // Fallback saavn.dev Mirror Handlers
  // -------------------------------------------------------------

  Future<SearchResult> _searchAllMirror(String query, {int page = 1, int limit = 20}) async {
    try {
      final url = Uri.parse('${ApiEndpoints.jioSaavnApiMirror}/search?query=${Uri.encodeComponent(query)}&page=$page&limit=$limit');
      final response = await _client.get(url, headers: _defaultHeaders).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'];
        if (data != null && data is Map<String, dynamic>) {
          final songs = <Track>[];
          final albums = <AlbumModel>[];
          final artists = <ArtistModel>[];
          final playlists = <PlaylistModel>[];

          if (data['songs']?['results'] != null) {
            for (final s in (data['songs']['results'] as List)) {
              final t = _parseMirrorSongItem(s as Map<String, dynamic>);
              if (t != null) songs.add(t);
            }
          }

          if (data['albums']?['results'] != null) {
            for (final a in (data['albums']['results'] as List)) {
              final alb = _parseMirrorAlbumItem(a as Map<String, dynamic>);
              if (alb != null) albums.add(alb);
            }
          }

          if (data['artists']?['results'] != null) {
            for (final ar in (data['artists']['results'] as List)) {
              final art = _parseMirrorArtistItem(ar as Map<String, dynamic>);
              if (art != null) artists.add(art);
            }
          }

          if (data['playlists']?['results'] != null) {
            for (final p in (data['playlists']['results'] as List)) {
              final pl = _parseMirrorPlaylistItem(p as Map<String, dynamic>);
              if (pl != null) playlists.add(pl);
            }
          }

          return SearchResult(
            query: query,
            source: 'jiosaavn',
            songs: songs,
            albums: albums,
            artists: artists,
            playlists: playlists,
          );
        }
      }
    } catch (e) {
      debugPrint('[JioSaavnSource] _searchAllMirror failed: $e');
    }

    return SearchResult(query: query, source: 'jiosaavn');
  }

  Future<List<Track>> _searchSongsMirror(String query, {int page = 1, int limit = 20}) async {
    try {
      final url = Uri.parse('${ApiEndpoints.jioSaavnApiMirror}/search/songs?query=${Uri.encodeComponent(query)}&page=$page&limit=$limit');
      final response = await _client.get(url, headers: _defaultHeaders).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final results = body['data']?['results'];
        if (results != null && results is List) {
          final List<Track> tracks = [];
          for (final s in results) {
            final t = _parseMirrorSongItem(s as Map<String, dynamic>);
            if (t != null) tracks.add(t);
          }
          return tracks;
        }
      }
    } catch (e) {
      debugPrint('[JioSaavnSource] _searchSongsMirror failed: $e');
    }
    return const [];
  }

  Future<Track?> _getSongDetailsMirror(String songId) async {
    try {
      final url = Uri.parse('${ApiEndpoints.jioSaavnApiMirror}/songs/$songId');
      final response = await _client.get(url, headers: _defaultHeaders).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final songData = body['data'];
        if (songData != null) {
          if (songData is List && songData.isNotEmpty) {
            return _parseMirrorSongItem(songData[0] as Map<String, dynamic>);
          } else if (songData is Map<String, dynamic>) {
            return _parseMirrorSongItem(songData);
          }
        }
      }
    } catch (e) {
      debugPrint('[JioSaavnSource] _getSongDetailsMirror failed: $e');
    }
    return null;
  }

  Future<AlbumModel?> _getAlbumDetailsMirror(String albumId) async {
    try {
      final url = Uri.parse('${ApiEndpoints.jioSaavnApiMirror}/albums?id=$albumId');
      final response = await _client.get(url, headers: _defaultHeaders).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'];
        if (data != null && data is Map<String, dynamic>) {
          return _parseMirrorAlbumItem(data);
        }
      }
    } catch (e) {
      debugPrint('[JioSaavnSource] _getAlbumDetailsMirror failed: $e');
    }
    return null;
  }

  Future<ArtistModel?> _getArtistDetailsMirror(String artistId) async {
    try {
      final url = Uri.parse('${ApiEndpoints.jioSaavnApiMirror}/artists?id=$artistId');
      final response = await _client.get(url, headers: _defaultHeaders).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'];
        if (data != null && data is Map<String, dynamic>) {
          return _parseMirrorArtistItem(data);
        }
      }
    } catch (e) {
      debugPrint('[JioSaavnSource] _getArtistDetailsMirror failed: $e');
    }
    return null;
  }

  Future<PlaylistModel?> _getPlaylistDetailsMirror(String playlistId) async {
    try {
      final url = Uri.parse('${ApiEndpoints.jioSaavnApiMirror}/playlists?id=$playlistId');
      final response = await _client.get(url, headers: _defaultHeaders).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'];
        if (data != null && data is Map<String, dynamic>) {
          return _parseMirrorPlaylistItem(data);
        }
      }
    } catch (e) {
      debugPrint('[JioSaavnSource] _getPlaylistDetailsMirror failed: $e');
    }
    return null;
  }

  Track? _parseMirrorSongItem(Map<String, dynamic> item) {
    final id = item['id']?.toString();
    if (id == null || id.isEmpty) return null;

    final rawTitle = item['name']?.toString() ?? item['title']?.toString() ?? 'Unknown Track';
    final cleanedTitle = AudioDecryptor.cleanTrackTitle(rawTitle);

    String artist = 'Unknown Artist';
    if (item['artists']?['primary'] != null && (item['artists']['primary'] as List).isNotEmpty) {
      artist = (item['artists']['primary'] as List).map((a) => a['name']?.toString() ?? '').where((n) => n.isNotEmpty).join(', ');
    } else if (item['primaryArtists'] != null) {
      artist = item['primaryArtists'].toString();
    }
    artist = AudioDecryptor.cleanHtmlEntities(artist);

    String? album;
    if (item['album'] is Map) {
      album = AudioDecryptor.cleanHtmlEntities(item['album']['name']?.toString() ?? '');
    } else if (item['album'] != null) {
      album = AudioDecryptor.cleanHtmlEntities(item['album'].toString());
    }

    final durationSeconds = (item['duration'] as num?)?.toInt() ?? int.tryParse(item['duration']?.toString() ?? '0') ?? 0;

    String? artwork;
    String? highResArtwork;
    if (item['image'] is List && (item['image'] as List).isNotEmpty) {
      final images = item['image'] as List;
      artwork = images.first['url']?.toString() ?? images.first['link']?.toString();
      highResArtwork = images.last['url']?.toString() ?? images.last['link']?.toString();
    } else if (item['image'] is String) {
      artwork = item['image'] as String;
      highResArtwork = AudioDecryptor.formatHighResArtwork(artwork);
    }

    // Direct download/stream URLs
    String? streamUrl;
    if (item['downloadUrl'] is List && (item['downloadUrl'] as List).isNotEmpty) {
      final urls = item['downloadUrl'] as List;
      // Pick highest quality (last item e.g. 320kbps)
      streamUrl = urls.last['url']?.toString() ?? urls.last['link']?.toString();
    }

    final releaseDate = item['releaseDate']?.toString() ?? item['year']?.toString();
    final language = item['language']?.toString();
    final hasLyrics = item['hasLyrics'] == true || item['hasLyrics'] == 'true';

    return Track(
      id: id,
      title: cleanedTitle.isNotEmpty ? cleanedTitle : rawTitle,
      artist: artist.isNotEmpty ? artist : 'Unknown Artist',
      album: album,
      duration: Duration(seconds: durationSeconds),
      artworkUrl: artwork,
      highResArtworkUrl: highResArtwork,
      streamUrl: streamUrl,
      downloadUrl: streamUrl,
      source: 'jiosaavn',
      bitrate: 320,
      audioQuality: AudioQuality.high320k,
      releaseDate: releaseDate,
      language: language,
      hasSyncedLyrics: hasLyrics,
      extra: {
        'url': item['url'],
        'playCount': item['playCount'],
      },
    );
  }

  AlbumModel? _parseMirrorAlbumItem(Map<String, dynamic> item) {
    final id = item['id']?.toString();
    if (id == null || id.isEmpty) return null;

    final title = AudioDecryptor.cleanHtmlEntities(item['name']?.toString() ?? item['title']?.toString() ?? '');
    String artist = 'Unknown Artist';
    if (item['artists']?['primary'] != null && (item['artists']['primary'] as List).isNotEmpty) {
      artist = (item['artists']['primary'] as List).map((a) => a['name']?.toString() ?? '').where((n) => n.isNotEmpty).join(', ');
    } else if (item['primaryArtists'] != null) {
      artist = item['primaryArtists'].toString();
    }

    String? artwork;
    String? highResArtwork;
    if (item['image'] is List && (item['image'] as List).isNotEmpty) {
      final images = item['image'] as List;
      artwork = images.first['url']?.toString() ?? images.first['link']?.toString();
      highResArtwork = images.last['url']?.toString() ?? images.last['link']?.toString();
    }

    final List<Track> songs = [];
    if (item['songs'] != null && item['songs'] is List) {
      for (final s in (item['songs'] as List)) {
        final t = _parseMirrorSongItem(s as Map<String, dynamic>);
        if (t != null) songs.add(t);
      }
    }

    return AlbumModel(
      id: id,
      title: title,
      artist: AudioDecryptor.cleanHtmlEntities(artist),
      artworkUrl: artwork,
      highResArtworkUrl: highResArtwork,
      releaseYear: item['year']?.toString(),
      totalTracks: songs.isNotEmpty ? songs.length : ((item['songCount'] as num?)?.toInt() ?? 0),
      songs: songs,
      source: 'jiosaavn',
      language: item['language']?.toString(),
    );
  }

  ArtistModel? _parseMirrorArtistItem(Map<String, dynamic> item) {
    final id = item['id']?.toString();
    if (id == null || id.isEmpty) return null;

    final name = AudioDecryptor.cleanHtmlEntities(item['name']?.toString() ?? '');

    String? avatarUrl;
    String? bannerUrl;
    if (item['image'] is List && (item['image'] as List).isNotEmpty) {
      final images = item['image'] as List;
      avatarUrl = images.first['url']?.toString() ?? images.first['link']?.toString();
      bannerUrl = images.last['url']?.toString() ?? images.last['link']?.toString();
    }

    final List<Track> topTracks = [];
    if (item['topSongs'] != null && item['topSongs'] is List) {
      for (final s in (item['topSongs'] as List)) {
        final t = _parseMirrorSongItem(s as Map<String, dynamic>);
        if (t != null) topTracks.add(t);
      }
    }

    final List<AlbumModel> albums = [];
    if (item['topAlbums'] != null && item['topAlbums'] is List) {
      for (final a in (item['topAlbums'] as List)) {
        final alb = _parseMirrorAlbumItem(a as Map<String, dynamic>);
        if (alb != null) albums.add(alb);
      }
    }

    return ArtistModel(
      id: id,
      name: name,
      avatarUrl: avatarUrl,
      bannerUrl: bannerUrl,
      bio: item['bio'] is List ? (item['bio'] as List).join(' ') : item['bio']?.toString(),
      fansCount: (item['followerCount'] as num?)?.toInt() ?? 0,
      topTracks: topTracks,
      albums: albums,
      source: 'jiosaavn',
    );
  }

  PlaylistModel? _parseMirrorPlaylistItem(Map<String, dynamic> item) {
    final id = item['id']?.toString();
    if (id == null || id.isEmpty) return null;

    final title = AudioDecryptor.cleanHtmlEntities(item['name']?.toString() ?? item['title']?.toString() ?? '');

    String? artwork;
    String? highResArtwork;
    if (item['image'] is List && (item['image'] as List).isNotEmpty) {
      final images = item['image'] as List;
      artwork = images.first['url']?.toString() ?? images.first['link']?.toString();
      highResArtwork = images.last['url']?.toString() ?? images.last['link']?.toString();
    }

    final List<Track> songs = [];
    if (item['songs'] != null && item['songs'] is List) {
      for (final s in (item['songs'] as List)) {
        final t = _parseMirrorSongItem(s as Map<String, dynamic>);
        if (t != null) songs.add(t);
      }
    }

    return PlaylistModel(
      id: id,
      title: title,
      description: item['description']?.toString(),
      author: item['firstname']?.toString() ?? item['author']?.toString(),
      artworkUrl: artwork,
      highResArtworkUrl: highResArtwork,
      trackCount: songs.isNotEmpty ? songs.length : ((item['songCount'] as num?)?.toInt() ?? 0),
      songs: songs,
      source: 'jiosaavn',
      language: item['language']?.toString(),
    );
  }

  /// Closes the HTTP client
  void close() {
    _client.close();
  }
}
