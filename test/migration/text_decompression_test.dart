import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/migration/migration_utils.dart' as utils;

// the compressions are obtained by running compress method compress function
// from android\app\src\main\java\com\zulipmobile\TextCompression.kt from the RN
// app

var compressedStr1 = """z|zlib base64|eJzzSM3JyddRKM
nILFYAokSFktTiEoXikqLMvHRFAJdFCi4=""";
var str1 = "Hello, this is a test string!";

var compressedAccountStr = """z|zlib base64|eJyLruZS
KkpNzMlVslLKKCkpKLbS10/OSCzRS61IzC3ISdVX0uFSSs1NzMwB
KshNdYAK6yXn54JkEgsyvVMrgVKGRsYmSly1OlxYzMvJz8nXQ9KI
bKaCUmV+KS5TFZRMTM3MgcZyxQIAd0czmQ==""";
var accountStr = """[{
"realm":"https://chat.example/",
"email":"me@example.com",
"apiKey":"1234"
},
{
"realm":"https://lolo.example.com/",
"email": "you@example.com",
"apiKey": "4567"
}
]""";

var compressedSettingsStr = """z|zlib base64|eJx1jEE
KwzAMBO9+RdC5L+i9PeYParKiAlkutgyB0r83zjGQ484M+01kZWE
D3SeC0y1RvJGPuUK4WwxWREwdcwkVXTi0+F5E7RjSrx22D6pmeLA
9wdEr2sP5ZVj3SNjaqFpUcD49HPKX/ixeN8k=""";
var settingsStr = """{
"locale": "en",
"theme": "default",
"offlineNotification": true,
"onlineNotification": true,
"experimentalFeaturesEnabled": false,
"streamNotification": false}
""";


void main() {
  test('decompress str1', () {
    var decompressed = utils.decompress(compressedStr1);
    check(decompressed).equals(str1);
  });

  test('decompress accounts', () {
    var decompressed = utils.decompress(compressedAccountStr);
    check(decompressed).equals(accountStr);
  });

  test('decompress settings', () {
    var decompressed = utils.decompress(compressedSettingsStr);
    check(decompressed).equals(settingsStr);
  });
}