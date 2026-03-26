import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../get/services/store_service.dart';
import '../../../../model/content.dart';
import '../../../themes/content_theme.dart';
import '../../../values/constants.dart';
import '../../../values/theme.dart';
import '../../../widgets/image.dart';
import '../../../widgets/inset_shadow.dart';
import 'helpers.dart';

class WebsitePreview extends StatelessWidget {
  const WebsitePreview({super.key, required this.node});

  final WebsitePreviewNode node;

  @override
  Widget build(BuildContext context) {
    final store = requirePerAccountStore();
    final resolvedImageSrcUrl = store.tryResolveUrl(node.imageSrcUrl);
    final isSmallWidth = MediaQuery.sizeOf(context).width <= 576;

    // On Web on larger width viewports, the title and description container's
    // width is constrained using `max-width: calc(100% - 115px)`, we do not
    // follow the same here for potential benefits listed here:
    //   https://github.com/zulip/zulip-flutter/pull/1049#discussion_r1915740997
    final titleAndDescription = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (node.title != null)
          GestureDetector(
            onTap: () => contentLaunchUrl(context, node.hrefUrl),
            child: Text(
              node.title!,
              style: TextStyle(
                fontSize: 1.2 * kBaseFontSize,
                // Web uses `line-height: normal` for title. MDN docs for it:
                //   https://developer.mozilla.org/en-US/docs/Web/CSS/line-height#normal
                // says actual value depends on user-agent, and default value
                // can be roughly 1.2 (unitless). So, use the same here.
                height: 1.2,
                color: ContentTheme.of(context).colorLink,
              ),
            ),
          ),
        if (node.description != null)
          Container(
            padding: const EdgeInsets.only(top: 3),
            constraints: const BoxConstraints(maxWidth: 500),
            child: Text(node.description!),
          ),
      ],
    );

    final clippedTitleAndDescription = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: InsetShadowBox(
        bottom: 8,
        // TODO(#488) use different color for non-message contexts
        // TODO(#647) use different color for highlighted messages
        // TODO(#681) use different color for DM messages
        color: DesignVariables.of(context).bgMessageRegular,
        child: ClipRect(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 80),
            child: OverflowBox(
              maxHeight: double.infinity,
              alignment: AlignmentDirectional.topStart,
              fit: OverflowBoxFit.deferToChild,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: titleAndDescription,
              ),
            ),
          ),
        ),
      ),
    );

    final image = resolvedImageSrcUrl == null
        ? null
        : GestureDetector(
            onTap: () => contentLaunchUrl(context, node.hrefUrl),
            child: RealmContentNetworkImage(
              resolvedImageSrcUrl,
              fit: BoxFit.cover,
            ),
          );

    final result = isSmallWidth
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 15,
            children: [
              if (image != null)
                SizedBox(height: 110, width: double.infinity, child: image),
              clippedTitleAndDescription,
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (image != null) SizedBox.square(dimension: 80, child: image),
              Flexible(child: clippedTitleAndDescription),
            ],
          );

    return Padding(
      // TODO(?) Web has a bottom margin `--markdown-interelement-space-px`
      //   around the `message_embed` container, which is calculated here:
      //     https://github.com/zulip/zulip/blob/d28f7d86223bab4f11629637d4237381943f6fc1/web/src/information_density.ts#L80-L102
      //   But for now we use a static value of 6.72px instead which is the
      //   default in the web client, see discussion:
      //     https://github.com/zulip/zulip-flutter/pull/1049#discussion_r1915747908
      padding: const EdgeInsets.only(bottom: 6.72),
      child: Container(
        height: !isSmallWidth ? 90 : null,
        decoration: const BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(
              // Web has the same color in light and dark mode.
              color: Color(0xffededed),
              width: 3,
            ),
          ),
        ),
        padding: const EdgeInsets.all(5),
        child: result,
      ),
    );
  }
}
