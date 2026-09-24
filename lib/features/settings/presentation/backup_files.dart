import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const _jsonType = XTypeGroup(
  label: 'Consistency backup',
  extensions: ['json'],
  mimeTypes: ['application/json'],
  uniformTypeIdentifiers: ['public.json'],
);

bool get _isDesktop =>
    !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

/// Saves [contents] via a save dialog on desktop or the share sheet on
/// mobile. Returns false when the user cancelled.
Future<bool> saveBackupFile(String contents, {Rect? shareOrigin}) async {
  final name =
      'consistency-backup-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json';

  if (_isDesktop) {
    final location = await getSaveLocation(
      suggestedName: name,
      acceptedTypeGroups: const [_jsonType],
    );
    if (location == null) return false;
    await File(location.path).writeAsString(contents);
    return true;
  }

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$name');
  await file.writeAsString(contents);
  final result = await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'application/json')],
      subject: 'Consistency backup',
      sharePositionOrigin: shareOrigin,
    ),
  );
  return result.status != ShareResultStatus.dismissed;
}

/// Lets the user pick a backup file; returns its text or null if cancelled.
Future<String?> pickBackupFile() async {
  final file = await openFile(acceptedTypeGroups: const [_jsonType]);
  return file?.readAsString();
}
