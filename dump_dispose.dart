import 'dart:io';

void main() {
  final dir = Directory('lib/widgets');
  final out = File('dispose_methods.txt').openWrite();
  for (final file in dir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      final content = file.readAsStringSync();
      if (content.contains('dispose()')) {
        final lines = content.split('\n');
        bool inDispose = false;
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].contains('void dispose() {')) {
            inDispose = true;
            out.writeln('--- ${file.path}:$i ---');
          }
          if (inDispose) {
            out.writeln(lines[i]);
            if (lines[i].trim() == '}') {
              inDispose = false;
            }
          }
        }
      }
    }
  }
  out.close();
}
