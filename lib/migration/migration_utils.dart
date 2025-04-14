import 'dart:convert';
import 'package:archive/archive.dart';

/// Custom reviver for inventive data types JSON doesn't handle.
///
/// To be passed to `jsonDecode` as its `reviver` argument. New
/// reviving logic must also appear in the corresponding replacer
/// to stay in sync.
Object? reviver(Object? key, Object? value) {
  const serializedTypeFieldName = '__serializedType__';
  if (value != null &&
      value is Map<String, dynamic> &&
      value.containsKey(serializedTypeFieldName)) {
    final data = value['data'];
    switch (value[serializedTypeFieldName]) {
      case 'Date':
        return DateTime.parse(data as String);
      case 'ZulipVersion':
        return data as String;
      case 'URL':
        return Uri.parse(data as String);
      default:
      // Fail immediately for unhandled types to avoid corrupt data structures.
        throw FormatException(
          'Unhandled serialized type: ${value[serializedTypeFieldName]}',
        );
    }
  }
  return value;
}


var header = "z|zlib base64|";
String decompress(String input) {
  // Convert input string to bytes using Latin1 encoding (equivalent to ISO-8859-1)
  List<int> inputBytes = latin1.encode(input);

  // Extract header length
  int headerLength = header.length;

  // Get the Base64 content, skipping the header
  String base64Content = latin1.decode(inputBytes.sublist(headerLength));

  // Remove any whitespace or line breaks from the Base64 content
  base64Content = base64Content.replaceAll(RegExp(r'\s+'), '');

  // Decode the cleaned Base64 content
  List<int> decodedBytes = base64.decode(base64Content);

  // Create a ZLibDecoder for decompression
  final decoder = ZLibDecoder();

  // Decompress the bytes
  List<int> decompressedBytes = decoder.decodeBytes(decodedBytes);

  // Convert the bytes back to a string using UTF-8 encoding
  return utf8.decode(decompressedBytes);
}