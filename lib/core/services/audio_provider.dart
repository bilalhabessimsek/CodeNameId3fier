// ==========================================
// FILE: lib/core/services/audio_provider.dart
// ==========================================
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_session/audio_session.dart';
import 'package:rxdart/rxdart.dart';

// Diğer servisler
import 'tag_editor_service.dart';
import 'lyrics_service.dart';
import 'midi_player_service.dart';
import 'permission_service.dart';

class AudioProvider extends ChangeNotifier {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  // Late final kullanımı: Constructor'da mutlaka atanmalı
  late final AudioPlayer _audioPlayer;

  // Servisler
  final PermissionService _permissionService = PermissionService();
  final TagEditorService _tagEditorService = TagEditorService();
  final LyricsService _lyricsService = LyricsService();
  final MidiPlayerService _midiPlayer = MidiPlayerService();

  // Veri Listeleri
  List<SongModel> _songs = [];
  List<SongModel> get songs => _songs;
  List<AlbumModel> _albums = [];
  List<AlbumModel> get albums => _albums;
  List<ArtistModel> _artists = [];
  List<ArtistModel> get artists => _artists;
  List<PlaylistModel> _playlists = [];
  List<PlaylistModel> get playlists => _playlists;
  List<GenreModel> _genres = [];
  List<GenreModel> get genres => _genres;

  List<String> get folders {
    final paths = _songs
        .map((s) => Directory(s.data).parent.path)
        .toSet()
        .toList();
    paths.sort();
    return paths;
  }

  // Favoriler ve İstatistikler
  List<int> _favoriteSongIds = [];
  List<int> get favoriteSongIds => _favoriteSongIds;
  List<SongModel> get favoriteSongs =>
      _songs.where((s) => _favoriteSongIds.contains(s.id)).toList();

  final Map<String, int> _playCounts = {};
  int? _lastPlayedId;

  // Durum Değişkenleri
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _hasPermission = false;
  bool get hasPermission => _hasPermission;
  bool _isPlayerInitialized = false;
  bool get isPlayerInitialized => _isPlayerInitialized;

  SongModel? _currentSong;
  SongModel? get currentSong => _currentSong;
  String? _currentLyrics;
  String? get currentLyrics => _currentLyrics;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  Duration _duration = Duration.zero;
  Duration get duration => _duration;
  Duration _position = Duration.zero;
  Duration get position => _position;

  // Seçim Modu
  bool _isSelectionMode = false;
  bool get isSelectionMode => _isSelectionMode;
  bool _isDraggingSelection = false;
  bool get isDraggingSelection => _isDraggingSelection;
  final Set<int> _selectedSongIds = {};
  Set<int> get selectedSongIds => _selectedSongIds;

  // Oynatma Modları
  bool _isShuffleMode = false;
  bool get isShuffleMode => _isShuffleMode;
  LoopMode _loopMode = LoopMode.off;
  LoopMode get loopMode => _loopMode;

  Timer? _sleepTimer;
  Duration? _sleepTimerRemaining;
  Duration? get sleepTimerRemaining => _sleepTimerRemaining;
  bool get isSleepTimerActive => _sleepTimer != null;

  SongSortType? _sortType = SongSortType.DATE_ADDED;
  OrderType _orderType = OrderType.DESC_OR_GREATER;
  int _customSortType = 0;

  // MIDI Timer
  Timer? _pollingTimer;

  // Constructor
  AudioProvider() {
    _audioPlayer = AudioPlayer();
    _isPlayerInitialized = true;
    _initPlayerListeners();
  }

  // Pozisyon Stream'i (UI Güncellemesi İçin) - Optimize Edilmiş
  Stream<PositionData> get positionDataStream {
    return Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
      _audioPlayer.positionStream,
      _audioPlayer.bufferedPositionStream,
      _audioPlayer.durationStream,
      (position, bufferedPosition, duration) {
        // MIDI oynatılıyorsa kendi değerlerimizi dönelim
        if (isMidiPlaying) {
          return PositionData(_position, Duration.zero, _duration);
        }
        return PositionData(
          position,
          bufferedPosition,
          duration ?? Duration.zero,
        );
      },
    );
  }

  int? get audioSessionId => _audioPlayer.androidAudioSessionId;

  // Başlatma
  Future<void> initialize() async {
    debugPrint("DEBUG: AudioProvider: Başlatılıyor...");
    try {
      await _loadPlayCounts();
      await _loadFavorites();
      await _loadPlaybackState();
      await loadLostHistory();

      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // İlk izin kontrolü
      await checkAndRequestPermissions();

      // MIDI Polling Başlat
      _initMidiPolling();
    } catch (e) {
      debugPrint("ERROR: AudioProvider başlatma hatası: $e");
    }
  }

  void _initPlayerListeners() {
    // Oynatma Durumu
    _audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;
      debugPrint(
        "DEBUG: AudioProvider: PlayerState changed: playing=$isPlaying, state=$processingState",
      );

      if (_isPlaying != isPlaying) {
        _isPlaying = isPlaying;
        notifyListeners();
      }

      if (processingState == ProcessingState.completed) {
        if (!isMidiPlaying) {
          // just_audio otomatik olarak bir sonraki şarkıya geçer
        }
      }
    });

    // Şarkı Değişimi (Playlist takibi)
    _audioPlayer.sequenceStateStream.listen((sequenceState) {
      final source = sequenceState.currentSource;
      if (source == null) return;

      final tag = source.tag;
      if (tag is MediaItem) {
        final songId = int.tryParse(tag.id);
        if (songId != null && songId != _lastPlayedId) {
          _lastPlayedId = songId;
          _incrementPlayCount(songId);

          try {
            // Şarkıyı yerel listeden bul ve güncelle
            final song = _songs.firstWhere((s) => s.id == songId);
            _currentSong = song;
            _loadLyrics(song.data);
            notifyListeners();
          } catch (_) {
            debugPrint("Çalan şarkı yerel listede bulunamadı: $songId");
          }
        }
      }
    });

    // Hata Dinleyici
    _audioPlayer.playbackEventStream.listen(
      (event) {},
      onError: (Object e, StackTrace st) {
        if (e is PlatformException) {
          debugPrint("Audio Player Hatası: ${e.message}");
          // Hata durumunda bir sonraki şarkıya geçmeyi deneyebiliriz
          if (_audioPlayer.hasNext) _audioPlayer.seekToNext();
        }
      },
    );
  }

  // ======================================================
  // İzin Yönetimi (Android 13+ Uyumlu)
  // ======================================================
  Future<void> checkAndRequestPermissions() async {
    _isLoading = true;
    notifyListeners();

    final granted = await _permissionService.requestStoragePermission();
    _hasPermission = granted;

    debugPrint("DEBUG: Permissions granted: $_hasPermission");

    if (_hasPermission) {
      await fetchAllData();
      _scanForMidiFilesInBackground(); // MIDI taraması
    } else {
      debugPrint("İzin verilmedi.");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAllData() async {
    await fetchSongs();
    await fetchAlbums();
    await fetchPlaylists();
    await fetchGenres();
    await fetchArtists();
  }

  Future<void> fetchSongs() async {
    try {
      List<SongModel> fetchedSongs = await _audioQuery.querySongs(
        sortType: _sortType,
        orderType: _orderType,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      // Özel Sıralama Mantığı
      if (_customSortType != 0) {
        fetchedSongs.sort((a, b) {
          String keyA = a.id.toString();
          String keyB = b.id.toString();
          int countA = _playCounts[keyA] ?? 0;
          int countB = _playCounts[keyB] ?? 0;
          return _customSortType == 1
              ? countB.compareTo(countA) // En çok dinlenen
              : countA.compareTo(countB); // En az dinlenen
        });
      }
      _songs = fetchedSongs;
      checkRecoveredSongs();
      debugPrint("DEBUG: Songs fetched: ${_songs.length}");
      notifyListeners();
    } catch (e) {
      debugPrint("Şarkı getirme hatası: $e");
    }
  }

  // ======================================================
  // Oynatma Mantığı (ConcatenatingAudioSource Yerine Yeni API)
  // ======================================================

  bool get isMidiPlaying =>
      _currentSong != null &&
      (_currentSong!.data.toLowerCase().endsWith('.mid') == true ||
          _currentSong!.data.toLowerCase().endsWith('.midi') == true);

  // MIDI Polling
  void _initMidiPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) async {
      if (!isMidiPlaying || !_isPlaying) return;

      try {
        final pos = await _midiPlayer.getPosition();
        final dur = await _midiPlayer.getDuration();
        _position = Duration(milliseconds: pos);

        if (dur > 0) {
          _duration = Duration(milliseconds: dur);
        }

        // Auto-Next
        if (dur > 0 && pos >= dur - 500) {
          debugPrint("MIDI Bitti. Sonrakine geçiliyor...");
          await _midiPlayer.stop();
          playNext();
        }
        notifyListeners(); // Update UI for slider (polling based)
      } catch (e) {
        // print(e);
      }
    });
  }

  // Yeni Metot: Liste Çalma
  Future<void> playSongList(
    List<SongModel> songs, {
    int initialIndex = 0,
    bool shuffle = false,
  }) async {
    if (shuffle) {
      // Toggle shuffle if not enabled, or force ensure it is enabled?
      if (!_isShuffleMode) toggleShuffle();
      initialIndex = Random().nextInt(songs.length);
    }
    if (songs.isEmpty) return;

    // Tasarım tercihi: Şimdilik sadece seçilen şarkıyı çal,
    // ancak gerçekte tüm listeyi setAudioSources ile yüklemeliyiz
    // ki kullanıcı next/prev yapabilsin.
    // Ancak bu karmaşık olabilir (_songs vs. local list).
    // Basit çözüm: playSong'u çağır, o zaten _songs üzerinden çalışıyor.
    // Eğer 'songs' parametresi _songs'un bir alt kümesi (örn albüm) ise,
    // o zaman Player queue'yu bu liste ile değiştirmeliyiz.

    // Şimdilik sadece şarkıyı çalıyoruz.
    if (initialIndex >= 0 && initialIndex < songs.length) {
      await playSong(songs[initialIndex]);
    }
  }

  Future<void> playSong(SongModel song) async {
    debugPrint("DEBUG: playSong called: ${song.title}");
    // 1. Durumu güncelle
    _currentSong = song;
    _lastPlayedId = song.id;
    _loadLyrics(song.data);
    notifyListeners();

    // 2. MIDI Kontrolü
    if (isMidiPlaying) {
      await _audioPlayer.stop();
      await _midiPlayer.play(song.data);
      _isPlaying = true;
      notifyListeners();
      return;
    }

    // 3. JustAudio Oynatma
    await _midiPlayer.stop();

    try {
      // Oynatma listesini oluştur (ConcatenatingAudioSource YERİNE)
      // Sadece standart ses dosyalarını filtrele
      final standardSongs = _songs
          .where(
            (s) =>
                !s.data.toLowerCase().endsWith('.mid') &&
                !s.data.toLowerCase().endsWith('.midi'),
          )
          .toList();

      final index = standardSongs.indexWhere((s) => s.id == song.id);

      // Güvenli URI oluşturma
      final safeAudioSourceList = standardSongs.map((s) {
        Uri uri;
        if (s.uri != null && s.uri!.isNotEmpty) {
          uri = Uri.parse(s.uri!);
        } else {
          uri = Uri.file(s.data);
        }
        return AudioSource.uri(
          uri,
          tag: MediaItem(
            id: s.id.toString(),
            album: s.album ?? "Bilinmeyen Albüm",
            title: s.title,
            artist: s.artist ?? "Bilinmeyen Sanatçı",
            artUri: Uri.parse(
              "content://media/external/audio/media/${s.id}/albumart",
            ),
          ),
        );
      }).toList();

      // 0.10.x API Kullanımı
      await _audioPlayer.setAudioSource(
        ConcatenatingAudioSource(children: safeAudioSourceList),
        initialIndex: index >= 0 ? index : 0,
      );

      await _audioPlayer.play();
    } catch (e) {
      debugPrint("Oynatma Hatası: $e");
    }
  }

  // Oynatma Kontrolleri
  Future<void> pause() async {
    isMidiPlaying ? await _midiPlayer.pause() : await _audioPlayer.pause();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> resume() async {
    isMidiPlaying ? await _midiPlayer.resume() : await _audioPlayer.play();
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> playNext() async {
    if (isMidiPlaying) {
      // MIDI için manuel sonraki şarkı mantığı
      if (_songs.isNotEmpty && _currentSong != null) {
        int index = _songs.indexOf(_currentSong!);
        if (index < _songs.length - 1) playSong(_songs[index + 1]);
      }
    } else {
      if (_audioPlayer.hasNext) {
        await _audioPlayer.seekToNext();
      }
    }
  }

  Future<void> playPrevious() async {
    if (isMidiPlaying) {
      if (_songs.isNotEmpty && _currentSong != null) {
        int index = _songs.indexOf(_currentSong!);
        if (index > 0) playSong(_songs[index - 1]);
      }
    } else {
      if (_audioPlayer.hasPrevious) {
        await _audioPlayer.seekToPrevious();
      }
    }
  }

  Future<void> seek(Duration pos) async {
    isMidiPlaying
        ? await _midiPlayer.seek(pos.inMilliseconds)
        : await _audioPlayer.seek(pos);
  }

  void toggleShuffle() async {
    _isShuffleMode = !_isShuffleMode;
    await _audioPlayer.setShuffleModeEnabled(_isShuffleMode);
    _savePlaybackState();
    notifyListeners();
  }

  void toggleRepeatMode() async {
    if (_loopMode == LoopMode.off) {
      _loopMode = LoopMode.all;
    } else if (_loopMode == LoopMode.all) {
      _loopMode = LoopMode.one;
    } else {
      _loopMode = LoopMode.off;
    }
    await _audioPlayer.setLoopMode(_loopMode);
    _savePlaybackState();
    notifyListeners();
  }

  // ======================================================
  // Yardımcı Metotlar (Mevcut koddan uyarlanmıştır)
  // ======================================================

  Future<void> _loadPlayCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (var key in keys) {
      if (key.startsWith('play_count_')) {
        final id = key.replaceFirst('play_count_', '');
        _playCounts[id] = prefs.getInt(key) ?? 0;
      }
    }
  }

  Future<void> _incrementPlayCount(int songId) async {
    final key = songId.toString();
    _playCounts[key] = (_playCounts[key] ?? 0) + 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('play_count_$key', _playCounts[key]!);
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList('favorite_songs');
    if (stored != null) {
      _favoriteSongIds = stored.map((e) => int.parse(e)).toList();
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(int songId) async {
    if (_favoriteSongIds.contains(songId)) {
      _favoriteSongIds.remove(songId);
    } else {
      _favoriteSongIds.add(songId);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'favorite_songs',
      _favoriteSongIds.map((e) => e.toString()).toList(),
    );
  }

  bool isFavorite(int songId) => _favoriteSongIds.contains(songId);

  Future<void> _loadPlaybackState() async {
    final prefs = await SharedPreferences.getInstance();
    _isShuffleMode = prefs.getBool('shuffle_mode') ?? false;
    final loopModeIndex = prefs.getInt('loop_mode') ?? LoopMode.all.index;
    _loopMode = LoopMode.values[loopModeIndex];
    notifyListeners();
  }

  Future<void> _savePlaybackState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('shuffle_mode', _isShuffleMode);
    await prefs.setInt('loop_mode', _loopMode.index);
  }

  Future<void> _loadLyrics(String path) async {
    final lyrics = await _lyricsService.getOfflineLyrics(path);
    if (lyrics != null) {
      _currentLyrics = _lyricsService.formatLyrics(lyrics);
      notifyListeners();
    }
  }

  // MIDI Scan
  Future<void> _scanForMidiFilesInBackground() async {
    List<SongModel> midiSongs = await _scanForMidiFiles();
    if (midiSongs.isNotEmpty) {
      _songs.addAll(midiSongs);
      _songs = _songs.toSet().toList();
      notifyListeners();
    }
  }

  Future<List<SongModel>> _scanForMidiFiles() async {
    List<SongModel> midiSongs = [];
    if (!Platform.isAndroid) return midiSongs;
    final List<String> pathsToScan = [
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Audio',
      '/storage/emulated/0/Documents',
    ];
    for (final path in pathsToScan) {
      final dir = Directory(path);
      if (await dir.exists()) {
        try {
          await for (final entity in dir.list(
            recursive: true,
            followLinks: false,
          )) {
            if (entity is File) {
              final p = entity.path.toLowerCase();
              if (p.endsWith('.mid') || p.endsWith('.midi')) {
                int id = entity.path.hashCode;
                String title = entity.uri.pathSegments.last;
                if (title.contains('.')) {
                  title = title.substring(0, title.lastIndexOf('.'));
                }
                midiSongs.add(
                  SongModel({
                    "_id": id,
                    "_data": entity.path,
                    "title": title,
                    "artist": "MIDI File",
                    "album": "Unknown",
                    "duration": 0,
                    "_size": await entity.length(),
                    "is_music": true,
                  }),
                );
              }
            }
          }
        } catch (_) {}
      }
    }
    return midiSongs;
  }

  // --- Grouping & Playlists Helpers ---
  Future<void> fetchAlbums() async {
    _albums = await _audioQuery.queryAlbums(
      sortType: AlbumSortType.ALBUM,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    notifyListeners();
  }

  List<SongModel> getSongsFromAlbum(int albumId) =>
      _songs.where((song) => song.albumId == albumId).toList();

  Future<void> fetchPlaylists() async {
    _playlists = await _audioQuery.queryPlaylists(
      sortType: PlaylistSortType.DATE_ADDED,
      orderType: OrderType.DESC_OR_GREATER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    notifyListeners();
  }

  Future<void> fetchArtists() async {
    _artists = await _audioQuery.queryArtists(
      sortType: ArtistSortType.ARTIST,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    notifyListeners();
  }

  Future<void> fetchGenres() async {
    _genres = await _audioQuery.queryGenres(
      sortType: GenreSortType.GENRE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    notifyListeners();
  }

  Future<List<SongModel>> getSongsFromGenre(int genreId) async =>
      await _audioQuery.queryAudiosFrom(
        AudiosFromType.GENRE_ID,
        genreId,
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        ignoreCase: true,
      );
  Future<List<SongModel>> getSongsFromPlaylist(int playlistId) async =>
      await _audioQuery.queryAudiosFrom(
        AudiosFromType.PLAYLIST,
        playlistId,
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        ignoreCase: true,
      );

  List<SongModel> getSongsFromFolder(String folderPath) => _songs
      .where((song) => Directory(song.data).parent.path == folderPath)
      .toList();

  Future<void> createPlaylist(String name) async {
    await _audioQuery.createPlaylist(name);
    await fetchPlaylists();
  }

  Future<void> addToPlaylist(int playlistId, int audioId) async {
    await _audioQuery.addToPlaylist(playlistId, audioId);
    await fetchPlaylists();
  }

  Future<void> addSongsToPlaylist(int playlistId, List<int> songIds) async {
    for (var id in songIds) {
      await _audioQuery.addToPlaylist(playlistId, id);
    }
    await fetchPlaylists();
  }

  Future<void> deletePlaylist(int playlistId) async {
    await _audioQuery.removePlaylist(playlistId);
    await fetchPlaylists();
  }

  // Smart Playlists
  Future<void> createSmartPlaylistFromGenre(GenreModel genre) async {
    _isLoading = true;
    notifyListeners();
    final s = await getSongsFromGenre(genre.id);
    if (s.isNotEmpty) {
      await _audioQuery.createPlaylist(genre.genre);
      await fetchPlaylists();
      final p = _playlists.firstWhere(
        (element) => element.playlist == genre.genre,
      );
      for (var song in s) {
        await _audioQuery.addToPlaylist(p.id, song.id);
      }
      await fetchPlaylists();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createSmartPlaylistFromAlbum(AlbumModel album) async {
    _isLoading = true;
    notifyListeners();
    final s = getSongsFromAlbum(album.id);
    if (s.isNotEmpty) {
      await _audioQuery.createPlaylist(album.album);
      await fetchPlaylists();
      final p = _playlists.firstWhere(
        (element) => element.playlist == album.album,
      );
      for (var song in s) {
        await _audioQuery.addToPlaylist(p.id, song.id);
      }
      await fetchPlaylists();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createSmartPlaylistFromArtist(ArtistModel artist) async {
    _isLoading = true;
    notifyListeners();
    final s = _songs.where((element) => element.artistId == artist.id).toList();
    if (s.isNotEmpty) {
      await _audioQuery.createPlaylist(artist.artist);
      await fetchPlaylists();
      final p = _playlists.firstWhere(
        (element) => element.playlist == artist.artist,
      );
      for (var song in s) {
        await _audioQuery.addToPlaylist(p.id, song.id);
      }
      await fetchPlaylists();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> updateSongTags({
    required SongModel song,
    required String title,
    required String artist,
    String? album,
    String? genre,
  }) async {
    final error = await _tagEditorService.updateTags(
      filePath: song.data,
      title: title,
      artist: artist,
      album: album,
      genre: genre,
    );
    if (error == null) await fetchAllData();
    return error;
  }

  // Selection
  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) {
      _selectedSongIds.clear();
      _isDraggingSelection = false;
    }
    notifyListeners();
  }

  void setDraggingSelection(bool v) {
    _isDraggingSelection = v;
    notifyListeners();
  }

  void toggleSelection(int id) {
    if (_selectedSongIds.contains(id)) {
      _selectedSongIds.remove(id);
    } else {
      _selectedSongIds.add(id);
    }
    notifyListeners();
  }

  void addSongsToSelection(List<int> ids) {
    _selectedSongIds.addAll(ids);
    notifyListeners();
  }

  void selectRange(int start, int end, {List<SongModel>? sourceList}) {
    final list = sourceList ?? _songs;
    int s = start < end ? start : end;
    int e = start < end ? end : start;
    if (list.length > e) {
      for (int i = s; i <= e; i++) {
        _selectedSongIds.add(list[i].id);
      }
    }
    notifyListeners();
  }

  Future<void> deleteSelectedSongs() async => await physicallyDeleteSongs(
    _songs.where((s) => _selectedSongIds.contains(s.id)).toList(),
  );
  Future<void> addSelectedToPlaylist(int pid) async {
    for (var id in _selectedSongIds) {
      await addToPlaylist(pid, id);
    }
    _isSelectionMode = false;
    _selectedSongIds.clear();
    notifyListeners();
  }

  Future<void> updateSort(dynamic opt) async {
    if (opt is int) {
      _customSortType = opt;
      _sortType = SongSortType.TITLE;
    } else if (opt is SongSortType) {
      _customSortType = 0;
      _sortType = opt;
      _orderType =
          (opt == SongSortType.DATE_ADDED || opt == SongSortType.DURATION)
          ? OrderType.DESC_OR_GREATER
          : OrderType.ASC_OR_SMALLER;
    }
    await fetchSongs();
  }

  // --- Maintenance & Feature Methods ---

  Future<List<SongModel>> findDuplicateFiles() async {
    Map<String, SongModel> uniqueSongs = {};
    List<SongModel> duplicates = [];
    for (var song in _songs) {
      // STRICT CHECK: Only Title (User Request)
      String key = song.title.trim();
      if (uniqueSongs.containsKey(key)) {
        duplicates.add(song);
      } else {
        uniqueSongs[key] = song;
      }
    }
    return duplicates;
  }

  Future<List<SongModel>> detectUnplayableAndMissingFiles() async {
    try {
      final results = await Future.wait(
        _songs.map((song) async {
          try {
            final file = File(song.data);
            if (!await file.exists()) {
              debugPrint("DEBUG: Detect: Missing file found: ${song.data}");
              return song;
            }

            // Check for 0 duration (Corrupt/Empty files)
            // But exclude MIDI files as they often have 0 duration in metadata
            final isMidi =
                song.data.toLowerCase().endsWith('.mid') ||
                song.data.toLowerCase().endsWith('.midi');

            if (!isMidi && (song.duration == null || song.duration == 0)) {
              debugPrint(
                "DEBUG: Detect: CORRUPT file (0 duration): ${song.title} (${song.data})",
              );
              // Only consider it corrupt if file size is small (< 100KB) ?
              // User asked for "süresi olmayan ve de midi olmayan"
              return song;
            }
          } catch (e) {
            debugPrint("DEBUG: Detect: Error checking ${song.data}: $e");
            return song;
          }
          return null;
        }),
      );
      return results.whereType<SongModel>().toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<SongModel>> detectCorruptFiles() async {
    List<SongModel> corruptFiles = [];
    final tempPlayer = AudioPlayer();
    try {
      for (var song in _songs) {
        try {
          final uri = Uri.file(song.data);
          await tempPlayer.setAudioSource(AudioSource.uri(uri), preload: false);
        } catch (e) {
          corruptFiles.add(song);
        }
      }
    } finally {
      await tempPlayer.dispose();
    }
    return corruptFiles;
  }

  // ROBUST DELETION (Android 11+ Compatible)
  Future<bool> physicallyDeleteSongs(
    List<SongModel> songsToDelete, {
    void Function(int current, int total)? onProgress,
    BuildContext? context, // Added BuildContext parameter
  }) async {
    if (songsToDelete.isEmpty) return true;

    debugPrint(
      "DEBUG: physicallyDeleteSongs: Starting for ${songsToDelete.length} songs.",
    );

    // 1. Force Permission Check (Only if context is provided and mounted)
    if (Platform.isAndroid && context != null && context.mounted) {
      debugPrint(
        "DEBUG: physicallyDeleteSongs: Checking permissions with context.",
      );
      final hasPermission = await _permissionService
          .checkAndRequestFullStoragePermission(context);
      if (!hasPermission) {
        debugPrint("DEBUG: physicallyDeleteSongs: ABORTED. Permission denied.");
        return false;
      }
    } else if (Platform.isAndroid) {
      // Fallback for no context: check current status only
      final status = await ph.Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        debugPrint(
          "DEBUG: physicallyDeleteSongs: ABORTED. No permission and no context to ask.",
        );
        return false;
      }
    }

    // 2. Prevent File Locks
    try {
      debugPrint("DEBUG: Releasing file locks for deletion...");
      await _audioPlayer.stop();
      await _midiPlayer.stop();
      await _audioPlayer.setAudioSources([]);
      _isPlaying = false;
      _currentSong = null;
      notifyListeners();
    } catch (e) {
      debugPrint("DEBUG: Error releasing locks: $e");
    }

    bool allDeleted = true;
    final total = songsToDelete.length;
    int deletedCount = 0;

    // 3. Batched Deletion Process
    const int chunkSize = 15; // Process 15 files at once
    final List<int> idsToRemoveFromList = [];

    for (int i = 0; i < songsToDelete.length; i += chunkSize) {
      final chunk = songsToDelete.sublist(
        i,
        (i + chunkSize > songsToDelete.length)
            ? songsToDelete.length
            : i + chunkSize,
      );

      // Run deletions in this chunk in parallel
      await Future.wait(
        chunk.map((song) async {
          await addToLostHistory(song.title, song.artist ?? "Bilinmiyor");

          try {
            final file = File(song.data);
            if (await file.exists()) {
              try {
                // Non-blocking delete
                await file.delete();
                idsToRemoveFromList.add(song.id);
              } catch (e) {
                // Minimal retry for large batches
                debugPrint("DEBUG: First delete failed for ${song.title}: $e");
                try {
                  await Future.delayed(const Duration(milliseconds: 200));
                  await file.delete();
                  idsToRemoveFromList.add(song.id);
                } catch (_) {
                  allDeleted = false;
                }
              }
            } else {
              // Ghost file
              idsToRemoveFromList.add(song.id);
            }
          } catch (e) {
            allDeleted = false;
          }

          deletedCount++;
          onProgress?.call(deletedCount, total);
        }),
      );

      // Batch removal from internal list and notify UI periodically for large sets
      if (idsToRemoveFromList.isNotEmpty) {
        final idsSet = idsToRemoveFromList.toSet();
        _songs.removeWhere((s) => idsSet.contains(s.id));
        idsToRemoveFromList.clear();
        notifyListeners();
      }
    }

    // 4. Batch Media Scanner update (One go if possible or small chunks)
    // MediaScanner usually takes a single path, but running too many at once is bad.
    // We already did the critical deletions.

    // 5. Final Refresh Strategy
    if (songsToDelete.length > 50) {
      debugPrint(
        "DEBUG: Bulk deletion complete. Skipping immediate re-fetch to avoid MediaStore ghosts.",
      );
      // We already cleaned _songs via removeWhere in the loop.
      // Just notify the listeners to refresh UI with our cleaned local list.
    } else {
      debugPrint(
        "DEBUG: Small batch deletion. Skipping fetch to prevent ghosts.",
      );
      // We rely on local list update.
    }

    debugPrint(
      "DEBUG: Deletion operation finished. Current memory count: ${_songs.length}",
    );
    notifyListeners();
    return allDeleted;
  }

  void removeSongsFromLibrary(List<SongModel> songsToRemove) {
    if (songsToRemove.isEmpty) return;
    final idsToRemove = songsToRemove.map((e) => e.id).toSet();
    _songs.removeWhere((song) => idsToRemove.contains(song.id));
    notifyListeners();
  }

  // Lost History
  List<Map<String, String>> _lostSongsHistory = [];
  List<Map<String, String>> get lostSongsHistory => _lostSongsHistory;
  Future<void> loadLostHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final h = prefs.getString('lost_songs_history');
    if (h != null) {
      _lostSongsHistory = List<Map<String, String>>.from(
        jsonDecode(h).map((x) => Map<String, String>.from(x)),
      );
    }
    notifyListeners();
  }

  Future<void> addToLostHistory(
    String t,
    String a, {
    bool isManual = false,
  }) async {
    _lostSongsHistory.add({
      'title': t,
      'artist': a,
      'deletedAt': DateTime.now().toIso8601String(),
      'status': isManual ? 'Aranıyor' : 'Silindi',
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lost_songs_history', jsonEncode(_lostSongsHistory));
    notifyListeners();
  }

  Future<void> removeFromLostHistory(int i) async {
    _lostSongsHistory.removeAt(i);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lost_songs_history', jsonEncode(_lostSongsHistory));
    notifyListeners();
  }

  void checkRecoveredSongs() {
    _lostSongsHistory.removeWhere(
      (l) =>
          _songs.any((s) => s.title.toLowerCase() == l['title']?.toLowerCase()),
    );
    // Update prefs implicit
  }

  void setSleepTimer(Duration d) {
    cancelSleepTimer();
    _sleepTimerRemaining = d;
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_sleepTimerRemaining!.inSeconds > 0) {
        _sleepTimerRemaining = Duration(
          seconds: _sleepTimerRemaining!.inSeconds - 1,
        );
        notifyListeners();
      } else {
        pause();
        cancelSleepTimer();
      }
    });
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerRemaining = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _sleepTimer?.cancel();
    _audioPlayer.dispose();
    _midiPlayer.stop();
    super.dispose();
  }
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
  PositionData(this.position, this.bufferedPosition, this.duration);
}
