import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'mustard_theme.dart';

const double kMustardSupportPaneWidth = 360;
const double kMustardRemotePaneWidth = 260;

/// The ID and one-time password block on the home page. Support shows it as
/// the whole window; Remote shows it as the side panel.
class MustardHomePanel extends StatelessWidget {
  final bool support;
  final ValueListenable<TextEditingValue> id;
  final ValueListenable<TextEditingValue> password;
  final bool canRefreshPassword;
  final VoidCallback onCopyId;
  final VoidCallback onRefreshPassword;
  final VoidCallback? onChangePassword;
  final VoidCallback? onSettings;

  const MustardHomePanel({
    super.key,
    required this.support,
    required this.id,
    required this.password,
    required this.canRefreshPassword,
    required this.onCopyId,
    required this.onRefreshPassword,
    this.onChangePassword,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final c = MustardColors.of(context);
    final pad = support ? 24.0 : 18.0;
    return DefaultTextStyle.merge(
      style: TextStyle(fontFamily: kMustardFont, color: c.text, fontSize: 13),
      child: Padding(
        padding: EdgeInsets.fromLTRB(pad, 16, pad, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (support) ...[
              const Text(
                'Ready for support',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2),
              ),
              const SizedBox(height: 6),
              Text(
                'Read this ID and password to your Mustard technician.',
                style: TextStyle(fontSize: 13.5, height: 1.5, color: c.dim),
              ),
              const SizedBox(height: 18),
            ] else ...[
              _label(c, 'THIS COMPUTER'),
              const SizedBox(height: 10),
            ],
            Container(
              decoration: BoxDecoration(
                color: c.card,
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(kMustardCardRadius),
              ),
              child: Column(
                children: [
                  _row(
                    c,
                    label: support ? 'YOUR ID' : 'ID',
                    value: id,
                    size: support ? 24 : 18,
                    buttons: [
                      _iconButton(c, Icons.copy_rounded, 'Copy ID', onCopyId),
                      if (onSettings != null)
                        _iconButton(c, Icons.settings_outlined, 'Settings',
                            onSettings!),
                    ],
                  ),
                  Container(height: 1, color: c.line),
                  _row(
                    c,
                    label: support ? 'ONE-TIME PASSWORD' : 'One-time password',
                    value: password,
                    size: support ? 20 : 15,
                    spacing: 1.2,
                    buttons: [
                      if (canRefreshPassword)
                        _iconButton(c, Icons.refresh_rounded, 'New password',
                            onRefreshPassword),
                      if (onChangePassword != null)
                        _iconButton(c, Icons.edit_outlined, 'Change password',
                            onChangePassword!),
                    ],
                  ),
                ],
              ),
            ),
            if (support) ...[
              const SizedBox(height: 18),
              Text.rich(
                TextSpan(
                  text: 'Need a hand? Call ',
                  children: [
                    TextSpan(
                      text: kMustardPhone,
                      style: TextStyle(
                          color: c.text, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                style: TextStyle(fontSize: 12.5, color: c.dim),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _label(MustardColors c, String text) => Text(
        text,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.7,
            color: c.dim),
      );

  Widget _row(
    MustardColors c, {
    required String label,
    required ValueListenable<TextEditingValue> value,
    required double size,
    required List<Widget> buttons,
    double spacing = 0.4,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(support ? 16 : 14, 12, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                support
                    ? _label(c, label)
                    : Text(label,
                        style: TextStyle(fontSize: 11, color: c.dim)),
                const SizedBox(height: 4),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: value,
                  builder: (_, v, __) => FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SelectableText(
                      v.text.isEmpty ? '-' : v.text,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: kMustardFont,
                        fontSize: size,
                        fontWeight: FontWeight.w600,
                        letterSpacing: spacing,
                        color: c.text,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...buttons,
        ],
      ),
    );
  }

  Widget _iconButton(
          MustardColors c, IconData icon, String tooltip, VoidCallback onTap) =>
      IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: c.dim),
        splashRadius: 18,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
      );
}
