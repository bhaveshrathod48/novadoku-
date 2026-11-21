import 'dart:async';
import 'dart:convert';

typedef ProgressJson = Map<String, Object?>;

abstract interface class ProgressStorage {
  Future<String?> read(String name);
  Future<void> replace(String name, String content);
  Future<Set<String>> names();
}

final class MemoryProgressStorage implements ProgressStorage {
  final files = <String, String>{};

  @override
  Future<String?> read(String name) async => files[name];

  @override
  Future<void> replace(String name, String content) async =>
      files[name] = content;

  @override
  Future<Set<String>> names() async => files.keys.toSet();
}

final class UnsupportedProgressVersion implements Exception {
  const UnsupportedProgressVersion(this.key);
  final String key;

  @override
  String toString() =>
      'Save data for $key requires a newer version of Novadoku.';
}

typedef _Entry = ({int revision, ProgressJson payload});

/// One writer per app session. Each key owns two checksummed generations.
final class ProgressJournal {
  ProgressJournal(this.storage);

  final ProgressStorage storage;
  final _pending = <String, ProgressJson>{};
  final _revisions = <String, int>{};
  final _readOnly = <String>{};
  Future<void>? _writer;

  Future<T?> read<T>(
    String key,
    FutureOr<T> Function(ProgressJson payload) decode,
  ) async {
    if (_readOnly.contains(key)) throw UnsupportedProgressVersion(key);
    if (_pending[key] case final pending?) return await decode(pending);
    final entries = await _entries(key);
    for (final entry in entries) {
      try {
        final saved = await decode(entry.payload);
        _revisions[key] = entry.revision;
        return saved;
      } on FormatException {
        // The previous generation can still contain a playable snapshot.
      } on ArgumentError {
        // Validation of board geometry also rejects malformed snapshots.
      }
    }
    _revisions[key] = entries.firstOrNull?.revision ?? 0;
    return null;
  }

  void stage(String key, ProgressJson value) => _pending[key] = value;

  Future<void> write(String key, ProgressJson value) async {
    stage(key, value);
    try {
      await flushKey(key);
    } catch (_) {
      // Explicit transactions can roll back in their caller. Never retry a
      // value that caller rejected after failure.
      if (identical(_pending[key], value)) _pending.remove(key);
      rethrow;
    }
  }

  Future<void> flushKey(String key) async {
    try {
      await flush();
    } catch (_) {
      if (_pending.containsKey(key)) rethrow;
    }
  }

  Future<void> flush() => _writer ??= Future<void>.microtask(_drain);

  Future<void> _drain() async {
    final failed = <String>{};
    Object? firstError;
    StackTrace? firstTrace;
    try {
      while (true) {
        final key = _pending.keys
            .where((key) => !failed.contains(key))
            .firstOrNull;
        if (key == null) break;
        final payload = _pending[key]!;
        try {
          if (_readOnly.contains(key)) throw UnsupportedProgressVersion(key);
          final previous =
              _revisions[key] ??
              (await _entries(key)).firstOrNull?.revision ??
              0;
          final revision = previous + 1;
          final body = jsonEncode({
            'version': 1,
            'key': key,
            'revision': revision,
            'payload': payload,
          });
          await storage.replace(
            '$key.${revision % 2}',
            jsonEncode({'body': body, 'checksum': _checksum(body)}),
          );
          _revisions[key] = revision;
          if (identical(_pending[key], payload)) _pending.remove(key);
        } catch (error, trace) {
          failed.add(key);
          firstError ??= error;
          firstTrace ??= trace;
        }
      }
      if (firstError != null) {
        Error.throwWithStackTrace(firstError, firstTrace!);
      }
    } finally {
      _writer = null;
    }
  }

  Future<List<_Entry>> _entries(String key) async {
    final slots = await Future.wait([
      storage.read('$key.0'),
      storage.read('$key.1'),
    ]);
    final entries = <_Entry>[];
    for (final (slot, raw) in slots.indexed) {
      if (raw == null) continue;
      try {
        final json = jsonDecode(raw);
        if (json is! ProgressJson || json['body'] is! String) continue;
        final body = json['body'] as String;
        if (json['checksum'] != _checksum(body)) continue;
        final record = jsonDecode(body);
        if (record is! ProgressJson || record['key'] != key) continue;
        final version = record['version'];
        final revision = record['revision'];
        final payload = record['payload'];
        if (revision is! int || revision <= 0 || revision % 2 != slot) continue;
        bool newer(Object? value, [int supported = 1]) =>
            value is int && value > supported;
        final session = payload is ProgressJson ? payload['session'] : null;
        if (newer(version) ||
            (payload is ProgressJson &&
                newer(
                  payload['version'],
                  payload['puzzle'] is ProgressJson ? 3 : 1,
                )) ||
            (session is ProgressJson && newer(session['version'], 3))) {
          _readOnly.add(key);
          throw UnsupportedProgressVersion(key);
        }
        if (version != 1 || payload is! ProgressJson) continue;
        entries.add((revision: revision, payload: payload));
      } on FormatException {
        // Broken JSON or a truncated write invalidates only this slot.
      }
    }
    return entries..sort((a, b) => b.revision.compareTo(a.revision));
  }

  Future<Set<String>> keys() async => {
    for (final name in await storage.names())
      if (name.endsWith('.0') || name.endsWith('.1'))
        name.substring(0, name.length - 2),
    ..._pending.keys,
  };

  static int _checksum(String value) {
    // Adler-32 detects accidental corruption. It does not authenticate data.
    var a = 1;
    var b = 0;
    for (final byte in utf8.encode(value)) {
      a = (a + byte) % 65521;
      b = (b + a) % 65521;
    }
    return b * 65536 + a;
  }
}
