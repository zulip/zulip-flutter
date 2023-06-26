import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/model/content.dart';

import 'content_checks.dart';

void testParse(String name, String html, List<BlockContentNode> nodes) {
  test(name, () {
    check(parseContent(html))
      .equalsNode(ZulipContent(nodes: nodes));
  });
}

void main() {
  // When writing test cases in this file:
  //
  //  * Try to use actual HTML emitted by a Zulip server.
  //    Record the corresponding Markdown source in a comment.
  //
  //  * Here's a handy `curl` command for getting the server's HTML.
  //    First, as one-time setup, create a file with a test account's
  //    Zulip credentials in "netrc" format, meaning one line that looks like:
  //       machine HOSTNAME login EMAIL password API_KEY
  //
  //  * Then send some test messages, and fetch with a command like this.
  //    (Change "sender" operand to your user ID, and "topic" etc. as desired.)
  /*    $ curl -sS --netrc-file ../.netrc -G https://chat.zulip.org/api/v1/messages \
            --data-urlencode 'narrow=[{"operator":"sender", "operand":2187},
                                      {"operator":"stream", "operand":"test here"},
                                      {"operator":"topic",  "operand":"content"}]' \
            --data-urlencode anchor=newest --data-urlencode num_before=10 --data-urlencode num_after=0 \
            --data-urlencode apply_markdown=true \
          | jq '.messages[] | .content'
   */
  //
  //  * To get the corresponding Markdown source, use the same command
  //    with `apply_markdown` changed to `false`.

  testParse('parse a plain-text paragraph',
    // "hello world"
    '<p>hello world</p>', const [
      ParagraphNode(nodes: [TextNode('hello world')]),
    ]);

  testParse('parse two plain-text paragraphs',
    // "hello\n\nworld"
    '<p>hello</p>\n<p>world</p>', const [
      ParagraphNode(nodes: [TextNode('hello')]),
      ParagraphNode(nodes: [TextNode('world')]),
    ]);

  // TODO write more tests for this code
}
