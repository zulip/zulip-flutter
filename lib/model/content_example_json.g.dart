// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'content_example_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContentExampleJson _$ContentExampleJsonFromJson(Map<String, dynamic> json) =>
    ContentExampleJson(
      description: json['description'] as String,
      markdown: json['markdown'] as String?,
      html: json['html'] as String,
      expectedNodes: (json['expectedNodes'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      expectedText: json['expectedText'] as String?,
    );

Map<String, dynamic> _$ContentExampleJsonToJson(ContentExampleJson instance) =>
    <String, dynamic>{
      'description': instance.description,
      'markdown': instance.markdown,
      'html': instance.html,
      'expectedNodes': instance.expectedNodes,
      'expectedText': instance.expectedText,
    };

KatexExampleJson _$KatexExampleJsonFromJson(Map<String, dynamic> json) =>
    KatexExampleJson(
      description: json['description'] as String,
      texSource: json['texSource'] as String?,
      markdown: json['markdown'] as String?,
      html: json['html'] as String,
      expectedNodes: (json['expectedNodes'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      expectedText: json['expectedText'] as String?,
    );

Map<String, dynamic> _$KatexExampleJsonToJson(KatexExampleJson instance) =>
    <String, dynamic>{
      'description': instance.description,
      'texSource': instance.texSource,
      'markdown': instance.markdown,
      'html': instance.html,
      'expectedNodes': instance.expectedNodes,
      'expectedText': instance.expectedText,
    };

ExportedExamples _$ExportedExamplesFromJson(Map<String, dynamic> json) =>
    ExportedExamples(
      contentExamples: (json['contentExamples'] as List<dynamic>)
          .map((e) => ContentExampleJson.fromJson(e as Map<String, dynamic>))
          .toList(),
      katexExamples: (json['katexExamples'] as List<dynamic>)
          .map((e) => KatexExampleJson.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ExportedExamplesToJson(ExportedExamples instance) =>
    <String, dynamic>{
      'contentExamples': instance.contentExamples,
      'katexExamples': instance.katexExamples,
    };
