import 'dart:io';

void main() {
  final dir = Directory('lib');
  for (final file in dir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      final content = file.readAsStringSync();
      if (content.contains('dispose()')) {
        final lines = content.split('\n');
        bool inDispose = false;
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].contains('void dispose() {')) {
            inDispose = true;
          }
          if (inDispose && lines[i].contains('StoreWidget.of(context)')) {
            print('${file.path}:$i: ${lines[i]}');
          }
          if (inDispose && lines[i].contains('of(context)')) {
            print('${file.path}:$i: ${lines[i]}');
          }
          if (inDispose && lines[i].trim() == '}') {
            inDispose = false;
          }
        }
      }
    }
  }
}
