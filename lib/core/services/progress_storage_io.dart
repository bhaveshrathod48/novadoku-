import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'progress_journal.dart';

ProgressStorage createProgressStorage() => FileProgressStorage(() async {
  final support = await getApplicationSupportDirectory();
  return Directory('${support.path}/novadoku-progress');
});

final class FileProgressStorage implements ProgressStorage {
  FileProgressStorage(this._locate);

  final Future<Directory> Function() _locate;
  Directory? _directory;

  Future<Directory> _root() async => _directory ??= await _locate();

  @override
  Future<String?> read(String name) async {
    final file = File('${(await _root()).path}/$name');
    try {
      return utf8.decode(await file.readAsBytes());
    } on PathNotFoundException {
      return null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> replace(String name, String content) async {
    final root = await _root();
    await root.create(recursive: true);
    final target = '${root.path}/$name';
    final temporary = File('$target.tmp');
    await temporary.writeAsString(content, flush: true);
    await temporary.rename(target);
  }

  @override
  Future<Set<String>> names() async {
    final directory = await _root();
    try {
      return {
        await for (final file in directory.list(followLinks: false))
          if (file is File) file.uri.pathSegments.last,
      };
    } on PathNotFoundException {
      return {};
    }
  }
}
