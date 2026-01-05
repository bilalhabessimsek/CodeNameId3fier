import 'dart:io';

void main() async {
  final outputFile = File('all_code_bundle.txt');
  final buffer = StringBuffer();

  final dirsToScan = ['lib'];
  final filesToInclude = [
    'pubspec.yaml',
    'android/app/src/main/AndroidManifest.xml',
  ];

  for (final dirPath in dirsToScan) {
    final dir = Directory(dirPath);
    if (await dir.exists()) {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          buffer.writeln('=========================================');
          buffer.writeln('FILE: ${entity.path}');
          buffer.writeln('=========================================');
          buffer.writeln(await entity.readAsString());
          buffer.writeln('\n');
        }
      }
    }
  }

  for (final filePath in filesToInclude) {
    final file = File(filePath);
    if (await file.exists()) {
      buffer.writeln('=========================================');
      buffer.writeln('FILE: $filePath');
      buffer.writeln('=========================================');
      buffer.writeln(await file.readAsString());
      buffer.writeln('\n');
    }
  }

  await outputFile.writeAsString(buffer.toString());
  stdout.writeln('Done! Combined code written to all_code_bundle.txt');
}
