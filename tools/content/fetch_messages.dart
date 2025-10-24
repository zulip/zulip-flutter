import 'dart:convert';
import 'dart:io';
import 'dart:math';

// Avoid any Flutter-related dependencies so this can be run as a CLI program.
import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:ini/ini.dart' as ini;
import 'package:zulip/api/backoff.dart';

import 'model.dart';

/// Fetch all public message contents from a Zulip server in bulk.
///
/// It outputs JSON entries of the message IDs and the rendered HTML contents in
/// JSON Lines (https://jsonlines.org) format. The output can be used later to
/// perform checks for discovering unimplemented features.
///
/// Because message IDs are only unique within a single server, the script
/// names corpora by the server host names.
///
/// This script is meant to be run via `tools/content/check-features`.
///
/// For more help, run `tools/content/check-features --help`.
///
/// See also:
/// * tools/content/unimplemented_features_test.dart, which runs checks against
///   the fetched corpora.
void main(List<String> args) async {
  final argParser = ArgParser();
  argParser.addOption(
    'config-file',
    help: 'A zuliprc file with identity information including email, API key\n'
          'and the Zulip server URL to fetch the messages from (required).\n\n'
          'To get the file, see\n'
          'https://zulip.com/api/configuring-python-bindings#download-a-zuliprc-file.',
    valueHelp: 'path/to/zuliprc',
  );
  argParser.addOption(
    'corpus-dir',
    help: 'The directory to look for/store the corpus file (required).\n'
          'The script will first read from the existing corpus file\n'
          '(assumed to be named as "your-zulip-server.com.jsonl")\n'
          'to avoid duplicates before fetching more messages.',
    valueHelp: 'path/to/corpus-dir',
  );
  argParser.addFlag(
    'fetch-newer',
    help: 'Fetch newer messages instead of older ones.\n'
          'Only useful when there is a matching corpus file in corpus-dir.',
    defaultsTo: false,
  );
  argParser.addFlag(
    'help', abbr: 'h',
    negatable: false,
    help: 'Show this help message.',
  );

  void printUsage() {
    // Give it a pass when printing the help message.
    // ignore: avoid_print
    print('usage: fetch_messages --config-file <CONFIG_FILE>\n\n'
          'Fetch message contents from a Zulip server in bulk.\n\n'
          '${argParser.usage}');
  }

  Never throwWithUsage(String error) {
    printUsage();
    throw Exception('\nError: $error');
  }

  final parsedArguments = argParser.parse(args);
  if (parsedArguments['help'] as bool) {
    printUsage();
    exit(0);
  }

  final zuliprc = parsedArguments['config-file'] as String?;
  if (zuliprc == null) {
    throwWithUsage('"config-file is required');
  }

  final configFile = File(zuliprc);
  if (!configFile.existsSync()) {
    throwWithUsage('Config file "$zuliprc" does not exist');
  }

  // `zuliprc` is a file in INI format containing the user's identity
  // information.
  //
  // See also:
  //   https://zulip.com/api/configuring-python-bindings#configuration-keys-and-environment-variables
  final parsedConfig = ini.Config.fromString(configFile.readAsStringSync());
  await fetchMessages(
    email: parsedConfig.get('api', 'email') as String,
    apiKey: parsedConfig.get('api', 'key') as String,
    site: Uri.parse(parsedConfig.get('api', 'site') as String),
    outputDirStr: parsedArguments['corpus-dir'] as String,
    fetchNewer: parsedArguments['fetch-newer'] as bool,
  );
}

Future<void> fetchMessages({
  required String email,
  required String apiKey,
  required Uri site,
  required String outputDirStr,
  required bool fetchNewer,
}) async {
  int? anchorMessageId;
  final outputDir = Directory(outputDirStr);
  outputDir.createSync(recursive: true);
  final outputFile = File('$outputDirStr/${site.host}.jsonl');
  if (!outputFile.existsSync()) outputFile.createSync();
  // Look for the known newest/oldest message so that we can continue
  // fetching from where we left off.
  await for (final message in readMessagesFromJsonl(outputFile)) {
    anchorMessageId ??= message.id;
    // Newer Zulip messages have higher message IDs.
    anchorMessageId = (fetchNewer ? max : min)(message.id, anchorMessageId);
  }
  final output = outputFile.openWrite(mode: FileMode.writeOnlyAppend);

  final client = http.Client();
  final authHeader = 'Basic ${base64Encode(utf8.encode('$email:$apiKey'))}';

  // These are working constants chosen arbitrarily.
  const batchSize = 5000;
  const maxRetries = 10;
  const fetchInterval = Duration(seconds: 5);

  int retries = 0;
  BackoffMachine? backoff;

  while (true) {
    // This loops until there is no message fetched in an iteration.
    final _GetMessagesResult result;
    try {
      // This is the one place where some output would be helpful,
      // for indicating progress.
      // ignore: avoid_print
      print('Fetching $batchSize messages starting from message ID $anchorMessageId');
      result = await _getMessages(client, realmUrl: site,
        authHeader: authHeader,
        anchorString: anchorMessageId != null ? jsonEncode(anchorMessageId)
                                              : fetchNewer ? 'oldest' : 'newest',
        // When the anchor message does not exist in the corpus,
        // we should include it.
        includeAnchor: anchorMessageId == null,
        numBefore: (!fetchNewer) ? batchSize : 0,
        numAfter: (fetchNewer) ? batchSize : 0,
      );
    } catch (e) {
      // We could have more fine-grained error handling and avoid retrying on
      // non-network-related failures, but that's not necessary.
      if (retries >= maxRetries) {
        rethrow;
      }
      retries++;
      await (backoff ??= BackoffMachine()).wait();
      continue;
    }

    final messageEntries = result.messages.map(MessageEntry.fromJson);
    if (messageEntries.isEmpty) {
      // Sanity check to ensure that the server agrees
      // there is no more messages to fetch.
      if (fetchNewer) assert(result.foundNewest);
      if (!fetchNewer) assert(result.foundOldest);
      break;
    }

    // Find and use the newest/oldest message as the next message fetch anchor.
    anchorMessageId = messageEntries.map((x) => x.id).reduce(fetchNewer ? max : min);
    messageEntries.map(jsonEncode).forEach((json) => output.writeln(json));

    // This I/O operation could fail, but crashing is fine here.
    final flushFuture = output.flush();
    // Make sure the delay happens concurrently to the flush.
    await Future<void>.delayed(fetchInterval);
    await flushFuture;
    backoff = null;
  }
}

/// https://zulip.com/api/get-messages#response
// Partially ported from [GetMessagesResult] to avoid depending on Flutter libraries.
class _GetMessagesResult {
  const _GetMessagesResult(this.foundOldest, this.foundNewest, this.messages);

  final bool foundOldest;
  final bool foundNewest;
  final List<Map<String, Object?>> messages;

  factory _GetMessagesResult.fromJson(Map<String, Object?> json) =>
    _GetMessagesResult(
      json['found_oldest'] as bool,
      json['found_newest'] as bool,
      (json['messages'] as List<Object?>).map((x) => (x as Map<String, Object?>)).toList());
}

/// https://zulip.com/api/get-messages
Future<_GetMessagesResult> _getMessages(http.Client client, {
  required Uri realmUrl,
  required String authHeader,
  required String anchorString,
  required bool includeAnchor,
  required int numBefore,
  required int numAfter,
}) async {
  final url = realmUrl.replace(
    path: '/api/v1/messages',
    queryParameters: {
      // This fallback will only be used when first fetching from a server.
      'anchor': anchorString,
      'include_anchor': jsonEncode(includeAnchor),
      'num_before': jsonEncode(numBefore),
      'num_after': jsonEncode(numAfter),
      'narrow': jsonEncode([{'operator': 'channels', 'operand': 'public'}]),
    });
  final response = await client.send(
    http.Request('GET', url)..headers['Authorization'] = authHeader);
  final bytes = await response.stream.toBytes();
  final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>?;

  if (response.statusCode != 200 || json == null) {
    // Just crashing early here should be fine for this tool.  We don't need
    // to handle the specific error codes.
    throw Exception('Failed to get messages. Code: ${response.statusCode}\n'
                    'Details: ${json ?? 'unknown'}');
  }
  return _GetMessagesResult.fromJson(json);
}
