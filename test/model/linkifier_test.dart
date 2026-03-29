import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/linkifier.dart';

import '../example_data.dart' as eg;

void main() {
  group('tryReverseLinkify', () {

    test('returns shortened text when URL matches main template', () {
      final linkifiers = [
        eg.realmLinkifier(
          urlTemplate: 'https://github.com/zulip/zulip/pull/{id}',
          reverseTemplate: '#{id}',
        ),
      ];
      check(tryReverseLinkify(
        'https://github.com/zulip/zulip/pull/123',
        linkifiers,
      )).equals('#123');
    });

    test('trims surrounding whitespace before matching', () {
      final linkifiers = [
        eg.realmLinkifier(
          urlTemplate: 'https://github.com/zulip/zulip/pull/{id}',
          reverseTemplate: '#{id}',
        ),
      ];
      check(tryReverseLinkify(
        '  https://github.com/zulip/zulip/pull/123  ',
        linkifiers,
      )).equals('#123');
    });

    test('returns null when text has no URL scheme', () {
      final linkifiers = [
        eg.realmLinkifier(
          urlTemplate: 'https://github.com/zulip/zulip/pull/{id}',
          reverseTemplate: '#{id}',
        ),
      ];
      check(tryReverseLinkify('github.com/zulip/zulip/pull/123', linkifiers))
          .isNull();
    });

    test('returns null for plain text that is not a URL', () {
      final linkifiers = [
        eg.realmLinkifier(
          urlTemplate: 'https://github.com/zulip/zulip/pull/{id}',
          reverseTemplate: '#{id}',
        ),
      ];
      check(tryReverseLinkify('hello world', linkifiers)).isNull();
    });

    test('returns null when linkifier has no reverseTemplate', () {
      final linkifiers = [
        eg.realmLinkifier(
          urlTemplate: 'https://github.com/zulip/zulip/pull/{id}',
          reverseTemplate: null,
        ),
      ];
      check(tryReverseLinkify(
        'https://github.com/zulip/zulip/pull/123',
        linkifiers,
      )).isNull();
    });

    test('returns null when URL does not match any template', () {
      final linkifiers = [
        eg.realmLinkifier(
          urlTemplate: 'https://gitlab.com/zulip/zulip/pull/{id}',
          reverseTemplate: '#{id}',
        ),
      ];
      check(tryReverseLinkify(
        'https://github.com/zulip/zulip/pull/123',
        linkifiers,
      )).isNull();
    });

    test('falls through to alternative template when main does not match', () {
      final linkifiers = [
        eg.realmLinkifier(
          urlTemplate: 'https://gitlab.com/zulip/zulip/pull/{id}',
          reverseTemplate: '#{id}',
          alternativeUrlTemplates: [
            'https://github.com/zulip/zulip/pull/{id}',
          ],
        ),
      ];
      check(tryReverseLinkify(
        'https://github.com/zulip/zulip/pull/123',
        linkifiers,
      )).equals('#123');
    });

    test('tries all alternative templates until one matches', () {
      final linkifiers = [
        eg.realmLinkifier(
          urlTemplate: 'https://gitlab.com/zulip/zulip/pull/{id}',
          reverseTemplate: '#{id}',
          alternativeUrlTemplates: [
            'https://www.github.com/zulip/zulip/pull/{id}',
            'https://github.com/zulip/zulip/pull/{id}',
          ],
        ),
      ];
      check(tryReverseLinkify(
        'https://github.com/zulip/zulip/pull/123',
        linkifiers,
      )).equals('#123');
    });

    test('returns result from first matching linkifier', () {
      final linkifiers = [
        eg.realmLinkifier(
          urlTemplate: 'https://github.com/zulip/zulip/pull/{id}',
          reverseTemplate: '#FIRST{id}',
        ),
        eg.realmLinkifier(
          urlTemplate: 'https://github.com/zulip/zulip/pull/{id}',
          reverseTemplate: '#SECOND{id}',
        ),
      ];
      check(tryReverseLinkify(
        'https://github.com/zulip/zulip/pull/123',
        linkifiers,
      )).equals('#FIRST123');
    });

    test('returns null when linkifiers list is empty', () {
      check(tryReverseLinkify(
        'https://github.com/zulip/zulip/pull/123',
        [],
      )).isNull();
    });

    test('handles multiple variables in template', () {
      final linkifiers = [
        eg.realmLinkifier(
          urlTemplate: 'https://github.com/{org}/{repo}/pull/{id}',
          reverseTemplate: '{org}/{repo}#{id}',
        ),
      ];
      check(tryReverseLinkify(
        'https://github.com/django/django/pull/456',
        linkifiers,
      )).equals('django/django#456');
    });

    test('handles {+var} template that allows slashes in value', () {
      final linkifiers = [
        eg.realmLinkifier(
          urlTemplate: 'https://zulip.readthedocs.io/en/latest/{+article}',
          reverseTemplate: 'RTD/{article}',
        ),
      ];
      check(tryReverseLinkify(
        'https://zulip.readthedocs.io/en/latest/overview/changelog.html',
        linkifiers,
      )).equals('RTD/overview/changelog.html');
    });

    test('{var} without + does not match value containing a slash', () {
      final linkifiers = [
        eg.realmLinkifier(
          urlTemplate: 'https://github.com/zulip/zulip/pull/{id}',
          reverseTemplate: '#{id}',
        ),
      ];
      check(tryReverseLinkify(
        'https://github.com/zulip/zulip/pull/123/extra',
        linkifiers,
      )).isNull();
    });

  });
}