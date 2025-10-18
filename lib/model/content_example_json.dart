import 'package:json_annotation/json_annotation.dart';

part 'content_example_json.g.dart';

/// Represents a ContentExample as JSON-serializable data
@JsonSerializable()
class ContentExampleJson {
  final String description;
  final String? markdown;
  final String html;
  final List<Map<String, dynamic>> expectedNodes;
  final String? expectedText;

  ContentExampleJson({
    required this.description,
    required this.markdown,
    required this.html,
    required this.expectedNodes,
    required this.expectedText,
  });

  factory ContentExampleJson.fromJson(Map<String, dynamic> json) =>
      _$ContentExampleJsonFromJson(json);

  Map<String, dynamic> toJson() => _$ContentExampleJsonToJson(this);
}

/// Represents a KatexExample as JSON-serializable data
@JsonSerializable()
class KatexExampleJson {
  final String description;
  final String? texSource;
  final String? markdown;
  final String html;
  final List<Map<String, dynamic>> expectedNodes;
  final String? expectedText;

  KatexExampleJson({
    required this.description,
    required this.texSource,
    required this.markdown,
    required this.html,
    required this.expectedNodes,
    required this.expectedText,
  });

  factory KatexExampleJson.fromJson(Map<String, dynamic> json) =>
      _$KatexExampleJsonFromJson(json);

  Map<String, dynamic> toJson() => _$KatexExampleJsonToJson(this);
}

/// Represents all exported examples
@JsonSerializable()
class ExportedExamples {
  final List<ContentExampleJson> contentExamples;
  final List<KatexExampleJson> katexExamples;

  ExportedExamples({
    required this.contentExamples,
    required this.katexExamples,
  });

  factory ExportedExamples.fromJson(Map<String, dynamic> json) =>
      _$ExportedExamplesFromJson(json);

  Map<String, dynamic> toJson() => _$ExportedExamplesToJson(this);
}