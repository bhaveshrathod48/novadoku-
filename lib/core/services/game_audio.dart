import 'dart:async';
import 'dart:developer' as developer;

import 'package:audioplayers/audioplayers.dart';

import '../constants/app_assets.dart';
import 'feedback_services.dart';

/// Music and protected gameplay effects retain their channels. UI clicks use
/// one preloaded restartable voice so controls never interrupt puzzle feedback.
final class GameAudio implements AudioService {
  GameAudio(this._output);

  final AudioOutput _output;
  Future<void> _musicCommands = Future.value();
  Future<void> _effectCommands = Future.value();
  Future<void> _uiCommands = Future.value();
  int _uiRequest = 0;
  Future<bool>? _uiPreload;
  Future<void>? _preload;
  Timer? _effectEnd;
  bool _music = false;
  bool _effects = false;
  bool _closed = false;
  int _request = 0;
  int _priority = -1;
  bool _effectsReady = false;

  @override
  Future<void> configure({required bool music, required bool effects}) async {
    if (_closed) return;
    // UI readiness must not depend on unrelated music/gameplay decoders. Warm
    // silently even when effects are off, so enabling sound is immediately ready.
    unawaited(_prepareUi());
    final musicChanged = _music != music;
    final effectsChanged = _effects != effects;
    _music = music;
    _effects = effects;
    if (musicChanged) {
      _musicCommands = _musicCommands.then(
        (_) => _run(() async {
          if (_closed || !_music) {
            await _output.setMusic(false);
          } else {
            await _output.prepareMusic();
            if (!_closed && _music) await _output.setMusic(true);
          }
        }),
      );
    }
    if (effectsChanged) {
      if (effects) {
        _preload ??= _run(() async {
          await _output.preloadEffects();
          _effectsReady = true;
        });
      } else {
        ++_uiRequest;
        _enqueueUi(_output.stopUi);
        _cancelEffects();
        _enqueueEffect(_output.stopEffect);
      }
    }
    await Future.wait([_musicCommands, _effectCommands, _uiCommands]);
  }

  @override
  Future<void> play(FeedbackEvent event) {
    if (event.priority == 0) return _playUi();
    if (_closed ||
        !_effects ||
        event.priority < _priority ||
        (event.isXMark && !_effectsReady)) {
      return Future.value();
    }
    final request = ++_request;
    _priority = event.priority;
    _effectEnd?.cancel();
    final age = event.isXMark ? (Stopwatch()..start()) : null;
    return _enqueueEffect(() => _start(event, 0, request, age));
  }

  Future<void> _playUi() {
    if (_closed || !_effects) return Future.value();
    final request = ++_uiRequest;
    bool current() => !_closed && _effects && request == _uiRequest;
    return _enqueueUi(() async {
      if (!current() || !await _prepareUi() || !current()) return;
      await _output.stopUi();
      if (current()) await _output.resumeUi();
    });
  }

  Future<bool> _prepareUi() => _uiPreload ??= () async {
    try {
      await _output.preloadUi();
      return true;
    } catch (error, stack) {
      // A transient source error must not leave every future click disabled.
      _uiPreload = null;
      developer.log(
        'UI audio preload failed; will retry',
        name: 'novadoku.audio',
        error: error,
        stackTrace: stack,
      );
      return false;
    }
  }();

  Future<void> _enqueueUi(Future<void> Function() command) =>
      _uiCommands = _uiCommands.then((_) => _run(command));

  Future<void> _start(
    FeedbackEvent event,
    int index,
    int request, [
    Stopwatch? age,
  ]) async {
    if (!_canStart(request, age)) return;
    await _preload;
    if (!_canStart(request, age)) return;
    final sound = event.sounds[index];
    try {
      await _output.stopEffect();
      if (!_canStart(request, age)) return;
      await _output.prepareEffect(sound);
      if (!_canStart(request, age)) return;
      await _output.resumeEffect();
    } catch (_) {
      if (_isCurrent(request)) {
        _priority = -1;
      }
      rethrow;
    }
    if (!_isCurrent(request)) return;
    _effectEnd = Timer(sound.duration, () {
      if (!_isCurrent(request)) return;
      final next = index + 1;
      if (next == event.sounds.length) {
        _priority = -1;
        if (sound.isXMark) {
          _enqueueEffect(() async {
            if (_isCurrent(request)) await _output.stopEffect();
          });
        }
      } else {
        _enqueueEffect(() => _start(event, next, request));
      }
    });
  }

  bool _isCurrent(int request) => !_closed && _effects && request == _request;

  bool _canStart(int request, Stopwatch? age) {
    if (!_isCurrent(request)) return false;
    // A stalled native command must never turn an old cell edit into late audio.
    if (age != null && age.elapsed > const Duration(milliseconds: 80)) {
      _cancelEffects();
      return false;
    }
    return true;
  }

  Future<void> _enqueueEffect(Future<void> Function() command) =>
      _effectCommands = _effectCommands.then((_) => _run(command));

  void _cancelEffects() {
    ++_request;
    _effectEnd?.cancel();
    _effectEnd = null;
    _priority = -1;
  }

  @override
  Future<void> dispose() async {
    if (_closed) return;
    _closed = true;
    ++_uiRequest;
    _cancelEffects();
    // Preparation also owns the retained X decoder; finish before disposal.
    await Future.wait([
      _musicCommands,
      _effectCommands,
      _uiCommands,
      ?_uiPreload,
      ?_preload,
    ]);
    await _run(_output.dispose);
  }

  static Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stack) {
      developer.log(
        'Audio operation failed',
        name: 'novadoku.audio',
        error: error,
        stackTrace: stack,
      );
    }
  }
}

abstract interface class AudioOutput {
  Future<void> preloadUi();
  Future<void> resumeUi();
  Future<void> stopUi();
  Future<void> preloadEffects();
  Future<void> prepareMusic();
  Future<void> setMusic(bool playing);
  Future<void> prepareEffect(SoundCue cue);
  Future<void> resumeEffect();
  Future<void> stopEffect();
  Future<void> dispose();
}

final class BundledAudioOutput implements AudioOutput {
  final _cache = AudioCache(cacheId: 'novadoku-audio-v1', prefix: '');
  AudioPlayer? _music;
  AudioPlayer? _effects;
  AudioPlayer? _ui;
  final _xPlayers = <SoundCue, AudioPlayer>{};
  AudioPlayer? _activeX;
  bool _usingX = false;
  bool _musicPrepared = false;

  static final _context = AudioContext(
    android: const AudioContextAndroid(
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  Future<AudioPlayer> _newPlayer(ReleaseMode mode) async {
    final player = AudioPlayer()
      ..audioCache = _cache
      ..positionUpdater = null;
    try {
      await player.setAudioContext(_context);
      await player.setReleaseMode(mode);
      return player;
    } catch (_) {
      try {
        await player.dispose();
      } catch (_) {
        // Initialization can fail before the platform allocates a player.
      }
      rethrow;
    }
  }

  @override
  Future<void> preloadEffects() async {
    await _cache.loadAll(
      // The UI source owns its own preload. Concurrent cache writes to the
      // same MP3 can otherwise race its native decoder initialization.
      {
        for (final cue in SoundCue.values)
          if (cue != SoundCue.button) cue.asset,
      }.toList(),
    );
    await Future.wait([
      _prepareX(SoundCue.markX),
      _prepareX(SoundCue.markXSwipe),
    ]);
  }

  @override
  Future<void> preloadUi() async {
    if (_ui != null) return;
    final player = await _newPlayer(ReleaseMode.stop);
    try {
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setVolume(SoundCue.button.volume);
      await player.setSource(AssetSource(SoundCue.button.asset));
      _ui = player;
    } catch (_) {
      await player.dispose();
      rethrow;
    }
  }

  @override
  Future<void> resumeUi() async => await _ui?.resume();

  @override
  Future<void> stopUi() async => await _ui?.stop();

  Future<AudioPlayer> _prepareX(SoundCue cue) async {
    final existing = _xPlayers[cue];
    if (existing != null) return existing;
    final player = await _newPlayer(ReleaseMode.stop);
    try {
      // Android predecodes this short cue in SoundPool; no per-cell source
      // reload or MediaPlayer seek is needed. Other players keep their mode.
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setVolume(cue.volume);
      await player.setSource(AssetSource(cue.asset));
      _xPlayers[cue] = player;
      return player;
    } catch (_) {
      await player.dispose();
      rethrow;
    }
  }

  @override
  Future<void> prepareMusic() async {
    if (_musicPrepared) return;
    final player = _music ??= await _newPlayer(ReleaseMode.loop);
    await player.setVolume(0.31);
    await player.setSource(AssetSource(AppAssets.backgroundMusic));
    _musicPrepared = true;
  }

  @override
  Future<void> setMusic(bool playing) async {
    final player = _music;
    if (player == null) return;
    if (playing) {
      await player.resume();
    } else {
      await player.pause();
    }
  }

  @override
  Future<void> prepareEffect(SoundCue cue) async {
    if (cue.isXMark) {
      _activeX = await _prepareX(cue);
      _usingX = true;
      return;
    }
    _usingX = false;
    final player = _effects ??= await _newPlayer(ReleaseMode.stop);
    await player.setVolume(cue.volume);
    await player.setSource(AssetSource(cue.asset));
  }

  @override
  Future<void> resumeEffect() async =>
      await (_usingX ? _activeX : _effects)?.resume();

  @override
  Future<void> stopEffect() async =>
      await (_usingX ? _activeX : _effects)?.stop();

  @override
  Future<void> dispose() async {
    final music = _music;
    final effects = _effects;
    final ui = _ui;
    final xPlayers = _xPlayers.values.toList();
    _xPlayers.clear();
    _music = _effects = _activeX = _ui = null;
    await Future.wait([
      if (music != null) music.dispose(),
      if (effects != null) effects.dispose(),
      if (ui != null) ui.dispose(),
      for (final player in xPlayers) player.dispose(),
    ]);
  }
}
