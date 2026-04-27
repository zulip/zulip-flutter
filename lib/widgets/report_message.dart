import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../api/model/model.dart';
import '../api/route/messages.dart';
import '../generated/l10n/zulip_localizations.dart';
import 'actions.dart';
import 'button.dart';
import 'dialog.dart';
import 'icons.dart';
import 'input.dart';
import 'inset_shadow.dart';
import 'store.dart';
import 'theme.dart';

/// A dialog for reporting a message to the server's moderation channel.
///
/// Use [show] to display this dialog.
class ReportMessageDialog extends StatefulWidget {
  const ReportMessageDialog({
    super.key,
    required this.message,
  });

  final Message message;

  static void show({
    required BuildContext pageContext,
    required Message message,
  }) {
    final accountId = PerAccountStoreWidget.accountIdOf(pageContext);
    showDialog<void>(
      context: pageContext,
      builder: (context) => PerAccountStoreWidget(accountId: accountId,
        child: ReportMessageDialog(message: message)));
  }

  @override
  State<ReportMessageDialog> createState() => _ReportMessageDialogState();
}

class _ReportMessageDialogState extends State<ReportMessageDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedType;
  final TextEditingController _descriptionController = TextEditingController();
  bool _requestInProgress = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Side effect: shows validation error feedback as applicable
    if (!_formKey.currentState!.validate()) return;

    setState(() => _requestInProgress = true);

    final description = _descriptionController.text.trim();
    final success = await ZulipAction.reportMessage(context,
      messageId: widget.message.id,
      reportType: _selectedType!,
      description: description.isNotEmpty ? description : null);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      setState(() => _requestInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);

    return ZulipDialog(
      title: zulipLocalizations.reportMessageDialogTitle,
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteractionIfError,
        child: InsetShadowBox(
          top: 8, bottom: 8,
          color: designVariables.bgContextMenu,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 16,
              children: [
                Text(zulipLocalizations.reportMessageDescription,
                  style: TextStyle(
                    color: designVariables.labelTime,
                    fontSize: 17,
                    height: 22 / 17)),
                _ReportTypeDropdown(
                  selectedType: _selectedType,
                  requestInProgress: _requestInProgress,
                  onSelected: (value) {
                    setState(() => _selectedType = value);
                  }),
                _ReportDescriptionField(
                  controller: _descriptionController,
                  requestInProgress: _requestInProgress,
                  selectedType: () => _selectedType),
              ])))),
      actions: [
        ZulipWebUiKitButton(
          intent: .info,
          attention: .low,
          label: zulipLocalizations.dialogCancel,
          onPressed: () => Navigator.pop(context)),
        ZulipWebUiKitButton(
          intent: .info,
          attention: .medium,
          label: zulipLocalizations.reportMessageSubmitButton,
          onPressed: _requestInProgress ? null : _submit),
      ]);
  }
}

class _ReportTypeDropdown extends StatelessWidget {
  const _ReportTypeDropdown({
    required this.selectedType,
    required this.requestInProgress,
    required this.onSelected,
  });

  final String? selectedType;
  final bool requestInProgress;
  final ValueChanged<String?> onSelected;

  DropdownMenuEntry<String> _buildEntry(BuildContext context, {
    required String value,
    required String label,
    required bool selected,
  }) {
    final designVariables = DesignVariables.of(context);

    return DropdownMenuEntry<String>(
      value: value,
      label: label,

      // Inspired by the Figma's list-item components for compose autocomplete:
      //   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=3732-28938&m=dev
      // TODO deduplicate some of this with that?
      style: ButtonStyle(
        padding: WidgetStatePropertyAll(EdgeInsetsDirectional.fromSTEB(4, 4, 8, 4)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),
        side: selected
          // TODO should `selected` be handled as a [WidgetState]?
          ? WidgetStatePropertyAll(BorderSide(color: designVariables.borderMenuButtonSelected))
          : null,
        overlayColor: WidgetStatePropertyAll(designVariables.editorButtonPressedBg),
        splashFactory: NoSplash.splashFactory,
      ),
      labelWidget: Text(
        maxLines: 2,
        // (For some reason if we set the style with [ButtonStyle.textStyle],
        // it seems like it defeats inheritance from ZulipTypography.)
        style: TextStyle(
          color: designVariables.contextMenuItemLabel,
          overflow: TextOverflow.ellipsis,
          fontSize: 18,
          height: 20 / 18,
        ),
        label));
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);
    final serverTypes = PerAccountStoreWidget.of(context).serverReportMessageTypes;

    return DropdownMenuFormField<String>(
      selectOnly: true,
      initialSelection: selectedType,
      enabled: !requestInProgress,
      validator: (value) {
        if (value == null) {
          return zulipLocalizations.reportMessageReasonRequired;
        }
        return null;
      },

      menuStyle: PopupMenuList.styleAsMenuStyle(designVariables),
      decorationBuilder: (_, menuController) =>
        baseFilledInputDecoration(designVariables).copyWith(
          label: Text(zulipLocalizations.reportMessageReasonLabel),
          suffixIcon: Transform.rotate(
            angle: menuController.isOpen ? math.pi : 0,
            child: Icon(ZulipIcons.chevron_down, size: 16))),
      textStyle: filledInputTextStyle(designVariables).copyWith(
        // Try to prevent cutting off a long line of text with a hard edge.
        // This doesn't actually work, though:
        // (1) DropdownMenu is backed by a text field. We can mostly be
        //     indifferent to that because we pass `selectOnly: true`.
        // (2) But text fields don't seem to support overflow configuration:
        //       https://github.com/flutter/flutter/issues/61069
        // TODO(upstream) fix
        overflow: TextOverflow.fade,
      ),
      expandedInsets: EdgeInsets.zero,

      onSelected: requestInProgress ? null : onSelected,
      dropdownMenuEntries: serverTypes != null
        ? serverTypes.map((type) =>
            _buildEntry(context,
              value: type.key,
              label: type.name,
              selected: selectedType == type.key))
          .toList()
        : LegacyReportMessageType.values.map((type) =>
            _buildEntry(context,
              value: type.toJson(),
              label: type.label(zulipLocalizations),
              selected: selectedType == type.toJson()))
          .toList());
  }
}

extension _LegacyReportMessageTypeLabel on LegacyReportMessageType {
  String label(ZulipLocalizations zulipLocalizations) {
    return switch (this) {
      .spam          => zulipLocalizations.messageReportTypeSpam,
      .harassment    => zulipLocalizations.messageReportTypeHarassment,
      .inappropriate => zulipLocalizations.messageReportTypeInappropriate,
      .norms         => zulipLocalizations.messageReportTypeNorms,
      .other         => zulipLocalizations.messageReportTypeOther,
    };
  }
}

class _ReportDescriptionField extends StatelessWidget {
  const _ReportDescriptionField({
    required this.controller,
    required this.requestInProgress,
    required this.selectedType,
  });

  final TextEditingController controller;
  final bool requestInProgress;

  /// A getter for the currently selected report type from the sibling
  /// dropdown, rather than a plain [String] value.
  ///
  /// This is a [ValueGetter] so that the [validator] reads the latest value
  /// at call time. When the dropdown value changes, [Form] validates all
  /// fields synchronously via [FormField.didChange] before the parent has
  /// a chance to rebuild this widget with updated props.
  final ValueGetter<String?> selectedType;

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);

    return ZulipCodePointLengthLimit(
      controller: controller,
      maxLengthCodePoints: kMaxMessageReportDescriptionLength,
      builder: (context, counter) => TextFormField(
        controller: controller,
        enabled: !requestInProgress,
        validator: (value) {
          if (selectedType() == kMessageReportTypeOther
              && (value == null || value.trim().isEmpty)) {
            return zulipLocalizations.reportMessageDescriptionRequired;
          }
          return null;
        },
        minLines: 1, maxLines: 8,
        textCapitalization: .sentences,
        style: filledInputTextStyle(designVariables),
        decoration: baseFilledInputDecoration(designVariables).copyWith(
          // Could show this conditionally, just as you approach the limit;
          // I lean toward always showing it in case you want to make an early
          // decision on whether to try pasting in some text, for example.
          counter: counter,
          label: Text(zulipLocalizations.reportMessageDescriptionLabel),
        )));
  }
}
