import 'dart:io';

void main() {
  final dir = Directory('.');
  for (final file in dir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      final content = file.readAsStringSync();
      if (content.contains('addStream') && content.contains('close')) {
         print('${file.path} contains both addStream and close');
      }
    }
  }
}
