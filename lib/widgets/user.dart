import 'package:flutter/material.dart';

import '../api/model/model.dart';
import '../model/avatar_url.dart';
import '../model/binding.dart';
import '../model/emoji.dart';
import '../model/presence.dart';
import 'content.dart';
import 'emoji.dart';
import 'icons.dart';
import 'store.dart';
import 'theme.dart';

/// A rounded square with size [size] showing a user's avatar.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.userId,
    required this.size,
    required this.borderRadius,
    this.backgroundColor,
    this.showPresence = true,
    this.replaceIfMuted = true,
  });

  final int userId;
  final double size;
  final double borderRadius;
  final Color? backgroundColor;
  final bool showPresence;
  final bool replaceIfMuted;

  @override
  Widget build(BuildContext context) {
    // (The backgroundColor is only meaningful if presence will be shown;
    // see [PresenceCircle.backgroundColor].)
    assert(backgroundColor == null || showPresence);
    return AvatarShape(
      size: size,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      userIdForPresence: showPresence ? userId : null,
      child: AvatarImage(userId: userId, size: size, replaceIfMuted: replaceIfMuted));
  }
}

/// The appropriate avatar image for a user ID.
///
/// If the user isn't found, gives a [SizedBox.shrink].
///
/// Wrap this with [AvatarShape].
class AvatarImage extends StatelessWidget {
  const AvatarImage({
    super.key,
    required this.userId,
    required this.size,
    this.replaceIfMuted = true,
  });

  final int userId;
  final double size;
  final bool replaceIfMuted;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final user = store.getUser(userId);

    if (user == null) { // TODO(log)
      return const SizedBox.shrink();
    }

    if (replaceIfMuted && store.isUserMuted(userId)) {
      return _AvatarPlaceholder(size: size);
    }

    final resolvedUrl = switch (user.avatarUrl) {
      null          => null, // TODO(#255): handle computing gravatars
      var avatarUrl => store.tryResolveUrl(avatarUrl),
    };

    if (resolvedUrl == null) {
      return const SizedBox.shrink();
    }

    final avatarUrl = AvatarUrl.fromUserData(resolvedUrl: resolvedUrl);
    final physicalSize = (MediaQuery.devicePixelRatioOf(context) * size).ceil();

    return RealmContentNetworkImage(
      avatarUrl.get(physicalSize),
      filterQuality: FilterQuality.medium,
      fit: BoxFit.cover,
    );
  }
}

/// A placeholder avatar for muted users.
///
/// Wrap this with [AvatarShape].
// TODO(#1558) use this as a fallback in more places (?) and update dartdoc.
class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder({required this.size});

  /// The size of the placeholder box.
  ///
  /// This should match the `size` passed to the wrapping [AvatarShape].
  /// The placeholder's icon will be scaled proportionally to this.
  final double size;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: designVariables.avatarPlaceholderBg),
      child: Icon(ZulipIcons.person,
        // Where the avatar placeholder appears in the Figma,
        // this is how the icon is sized proportionally to its box.
        size: size * 20 / 32,
        color: designVariables.avatarPlaceholderIcon));
  }
}

/// A rounded square shape, to wrap an [AvatarImage] or similar.
///
/// If [userIdForPresence] is provided, this will paint a [PresenceCircle]
/// on the shape.
class AvatarShape extends StatelessWidget {
  const AvatarShape({
    super.key,
    required this.size,
    required this.borderRadius,
    this.backgroundColor,
    this.userIdForPresence,
    required this.child,
  });

  final double size;
  final double borderRadius;
  final Color? backgroundColor;
  final int? userIdForPresence;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // (The backgroundColor is only meaningful if presence will be shown;
    // see [PresenceCircle.backgroundColor].)
    assert(backgroundColor == null || userIdForPresence != null);

    Widget result = SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
        clipBehavior: Clip.antiAlias,
        child: child));

    if (userIdForPresence != null) {
      final presenceCircleSize = size / 4; // TODO(design) is this right?
      result = Stack(children: [
        result,
        Positioned.directional(textDirection: Directionality.of(context),
          end: 0,
          bottom: 0,
          child: PresenceCircle(
            userId: userIdForPresence!,
            size: presenceCircleSize,
            backgroundColor: backgroundColor)),
      ]);
    }

    return result;
  }
}

/// The green or orange-gradient circle representing [PresenceStatus].
///
/// [backgroundColor] must not be [Colors.transparent].
/// It exists to match the background on which the avatar image is painted.
/// If [backgroundColor] is not passed, [DesignVariables.mainBackground] is used.
///
/// By default, nothing paints for a user in the "offline" status
/// (i.e. a user without a [PresenceStatus]).
/// Pass true for [explicitOffline] to paint a gray circle.
class PresenceCircle extends StatefulWidget {
  const PresenceCircle({
    super.key,
    required this.userId,
    required this.size,
    this.backgroundColor,
    this.explicitOffline = false,
  });

  final int userId;
  final double size;
  final Color? backgroundColor;
  final bool explicitOffline;

  /// Creates a [WidgetSpan] with a [PresenceCircle], for use in rich text
  /// before a user's name.
  ///
  /// The [PresenceCircle] will have `explicitOffline: true`.
  static InlineSpan asWidgetSpan({
    required int userId,
    required double fontSize,
    required TextScaler textScaler,
    Color? backgroundColor,
  }) {
    final size = textScaler.scale(fontSize) / 2;
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: 4),
        child: PresenceCircle(
          userId: userId,
          size: size,
          backgroundColor: backgroundColor,
          explicitOffline: true)));
  }

  @override
  State<PresenceCircle> createState() => _PresenceCircleState();
}

class _PresenceCircleState extends State<PresenceCircle> with PerAccountStoreAwareStateMixin {
  Presence? model;

  @override
  void onNewStore() {
    model?.removeListener(_modelChanged);
    model = PerAccountStoreWidget.of(context).presence
      ..addListener(_modelChanged);
  }

  @override
  void dispose() {
    model!.removeListener(_modelChanged);
    super.dispose();
  }

  void _modelChanged() {
    setState(() {
      // The actual state lives in [model].
      // This method was called because that just changed.
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = model!.presenceStatusForUser(
      widget.userId, utcNow: ZulipBinding.instance.utcNow());
    final designVariables = DesignVariables.of(context);
    final effectiveBackgroundColor = widget.backgroundColor ?? designVariables.mainBackground;
    assert(effectiveBackgroundColor != Colors.transparent);

    Color? color;
    LinearGradient? gradient;
    switch (status) {
      case null:
        if (widget.explicitOffline) {
          // TODO(a11y) this should be an open circle, like on web,
          //   to differentiate by shape (vs. the "active" status which is also
          //   a solid circle)
          color = designVariables.statusAway;
        } else {
          return SizedBox.square(dimension: widget.size);
        }
      case PresenceStatus.active:
        color = designVariables.statusOnline;
      case PresenceStatus.idle:
        gradient = LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [designVariables.statusIdle, effectiveBackgroundColor],
          stops: [0.05, 1.00],
        );
    }

    return SizedBox.square(dimension: widget.size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: effectiveBackgroundColor,
            width: 2,
            strokeAlign: BorderSide.strokeAlignOutside),
          color: color,
          gradient: gradient,
          shape: BoxShape.circle)));
  }
}

/// A user status emoji to be displayed in different parts of the app.
///
/// Use [userId] to show status emoji for that user.
/// Use [emoji] to show the specific emoji passed.
///
/// Only one of [userId] or [emoji] should be passed.
///
/// Use [padding] to control the padding of status emoji from neighboring
/// widgets.
/// When there is no status emoji to be shown, the padding will be omitted too.
///
/// Use [neverAnimate] to forcefully disable the animation for animated emojis.
/// Defaults to true.
class UserStatusEmoji extends StatelessWidget {
  const UserStatusEmoji({
    super.key,
    this.userId,
    this.emoji,
    required this.size,
    this.padding = EdgeInsets.zero,
    this.neverAnimate = true,
  }) : assert((userId == null) != (emoji == null),
              'Only one of the userId or emoji should be provided.');

  final int? userId;
  final StatusEmoji? emoji;
  final double size;
  final EdgeInsetsGeometry padding;
  final bool neverAnimate;

  static const double _spanPadding = 4;

  /// Creates a [WidgetSpan] with a [UserStatusEmoji], for use in rich text;
  /// before or after a text span.
  ///
  /// Use [position] to tell the emoji span where it is located relative to
  /// another span, so that it can adjust the necessary padding from it.
  static InlineSpan asWidgetSpan({
    int? userId,
    StatusEmoji? emoji,
    required double fontSize,
    required TextScaler textScaler,
    StatusEmojiPosition position = StatusEmojiPosition.after,
    bool neverAnimate = true,
  }) {
    final (double paddingStart, double paddingEnd) = switch (position) {
      StatusEmojiPosition.before => (0,            _spanPadding),
      StatusEmojiPosition.after  => (_spanPadding, 0),
    };
    final size = textScaler.scale(fontSize);
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: UserStatusEmoji(userId: userId, emoji: emoji, size: size,
        padding: EdgeInsetsDirectional.only(start: paddingStart, end: paddingEnd),
        neverAnimate: neverAnimate));
  }

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final effectiveEmoji = emoji ?? store.getUserStatus(userId!).emoji;

    final placeholder = SizedBox.shrink();
    if (effectiveEmoji == null) return placeholder;

    final emojiDisplay = store.emojiDisplayFor(
      emojiType: effectiveEmoji.reactionType,
      emojiCode: effectiveEmoji.emojiCode,
      emojiName: effectiveEmoji.emojiName)
        // Web doesn't seem to respect the emojiset user settings for user status.
        // .resolve(store.userSettings)
    ;
    return switch (emojiDisplay) {
      UnicodeEmojiDisplay() => Padding(
        padding: padding,
        child: UnicodeEmojiWidget(size: size, emojiDisplay: emojiDisplay)),
      ImageEmojiDisplay() => Padding(
        padding: padding,
        child: ImageEmojiWidget(
          size: size,
          emojiDisplay: emojiDisplay,
          neverAnimate: neverAnimate,
          // If image emoji fails to load, show nothing.
          errorBuilder: (_, _, _) => placeholder)),
      // The user-status feature doesn't support a :text_emoji:-style display.
      // Also, if an image emoji's URL string doesn't parse, it'll fall back to
      // a :text_emoji:-style display. We show nothing for this case.
      TextEmojiDisplay() => placeholder,
    };
  }
}

/// The position of the status emoji span relative to another text span.
enum StatusEmojiPosition { before, after }
