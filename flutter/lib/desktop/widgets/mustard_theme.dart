import 'package:flutter/material.dart';

import '../../common.dart';
import 'mustard_branding.dart';
import 'tabbar_widget.dart';

const kMustardFont = 'Inter';
const kMustardPhone = '07 855 6424';
const kMustardSite = 'https://mustard.co.nz';

const double kMustardRadius = 6;
const double kMustardCardRadius = 8;
const double kMustardInputRadius = 5;
const double kMustardButtonHeight = 36;
const double kMustardLargeButtonHeight = 44;

class MustardColors {
  final Color bg;
  final Color bar;
  final Color panel;
  final Color card;
  final Color line;
  final Color edge;
  final Color input;
  final Color hover;
  final Color text;
  final Color dim;
  final Color accent;
  final Color accentHover;
  final Color onAccent;
  final Color gold;
  final Color onGold;
  final Color danger;
  final Color ok;
  final Color offline;

  const MustardColors({
    required this.bg,
    required this.bar,
    required this.panel,
    required this.card,
    required this.line,
    required this.edge,
    required this.input,
    required this.hover,
    required this.text,
    required this.dim,
    required this.accent,
    required this.accentHover,
    required this.onAccent,
    required this.gold,
    required this.onGold,
    required this.danger,
    required this.ok,
    required this.offline,
  });

  // Mustard website palette: cream, olive and gold.
  static const light = MustardColors(
    bg: Color(0xFFF4EFD7),
    bar: Color(0xFFEAE3C4),
    panel: Color(0xFFF4EFD7),
    card: Color(0xFFFBF8EA),
    line: Color(0xFFDDD5B4),
    edge: Color(0xFFC9BF98),
    input: Color(0xFFFFFFFF),
    hover: Color(0xFFEFE8CB),
    text: Color(0xFF181C16),
    dim: Color(0xFF535B4D),
    accent: Color(0xFF896018),
    accentHover: Color(0xFF6E4C10),
    onAccent: Color(0xFFFFFFFF),
    gold: Color(0xFFDDAC5B),
    onGold: Color(0xFF181C16),
    danger: Color(0xFFA32D22),
    ok: Color(0xFF2F6B36),
    offline: Color(0xFF8A8672),
  );

  // Gatehouse palette (mustardtech/gatehouse, Theme.axaml).
  static const dark = MustardColors(
    bg: Color(0xFF1A1A1C),
    bar: Color(0xFF141415),
    panel: Color(0xFF18181A),
    card: Color(0xFF1F1F21),
    line: Color(0xFF2C2C2E),
    edge: Color(0xFF3A3A3D),
    input: Color(0xFF262628),
    hover: Color(0xFF242426),
    text: Color(0xFFE9E6DF),
    dim: Color(0xFF9A968C),
    accent: Color(0xFFDDAC5B),
    accentHover: Color(0xFFE9BE73),
    onAccent: Color(0xFF1C1C1E),
    gold: Color(0xFFDDAC5B),
    onGold: Color(0xFF1C1C1E),
    danger: Color(0xFFC0392B),
    ok: Color(0xFF6FBF73),
    offline: Color(0xFF5A564E),
  );

  static MustardColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

ButtonStyle mustardPrimaryButton(MustardColors c,
        {double height = kMustardButtonHeight}) =>
    ElevatedButton.styleFrom(
      backgroundColor: c.accent,
      foregroundColor: c.onAccent,
      disabledBackgroundColor: c.accent.withOpacity(0.4),
      disabledForegroundColor: c.onAccent.withOpacity(0.7),
      elevation: 0,
      minimumSize: Size(64, height),
      textStyle: const TextStyle(
          fontFamily: kMustardFont, fontSize: 14, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kMustardRadius)),
    );

ButtonStyle mustardSubtleButton(MustardColors c,
        {double height = kMustardButtonHeight}) =>
    OutlinedButton.styleFrom(
      backgroundColor: c.card,
      foregroundColor: c.text,
      disabledForegroundColor: c.dim,
      minimumSize: Size(64, height),
      side: BorderSide(color: c.edge),
      textStyle: const TextStyle(
          fontFamily: kMustardFont, fontSize: 14, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kMustardRadius)),
    );

ButtonStyle mustardDangerButton(MustardColors c,
        {double height = kMustardButtonHeight}) =>
    mustardPrimaryButton(c, height: height).copyWith(
      backgroundColor: MaterialStatePropertyAll(c.danger),
      foregroundColor: const MaterialStatePropertyAll(Colors.white),
    );

ThemeData mustardTheme(ThemeData base, MustardColors c) {
  final dark = base.brightness == Brightness.dark;
  final scheme = (dark ? const ColorScheme.dark() : const ColorScheme.light())
      .copyWith(
    primary: c.accent,
    onPrimary: c.onAccent,
    secondary: c.accent,
    onSecondary: c.onAccent,
    background: c.bg,
    onBackground: c.text,
    surface: c.card,
    onSurface: c.text,
    error: c.danger,
  );
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(kMustardInputRadius),
    borderSide: BorderSide(color: c.edge),
  );
  final toggle = MaterialStateProperty.resolveWith<Color?>((states) =>
      states.contains(MaterialState.selected) &&
              !states.contains(MaterialState.disabled)
          ? c.accent
          : null);
  return base.copyWith(
    colorScheme: scheme,
    primaryColor: c.accent,
    scaffoldBackgroundColor: c.bg,
    dialogBackgroundColor: c.card,
    cardColor: c.card,
    canvasColor: c.card,
    hoverColor: c.hover,
    dividerColor: c.line,
    hintColor: c.dim,
    indicatorColor: c.accent,
    textTheme: base.textTheme
        .apply(fontFamily: kMustardFont, bodyColor: c.text, displayColor: c.text)
        .copyWith(
            labelLarge: base.textTheme.labelLarge
                ?.copyWith(fontFamily: kMustardFont, color: c.accent)),
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: kMustardFont),
    iconTheme: base.iconTheme.copyWith(color: c.dim),
    dialogTheme: base.dialogTheme.copyWith(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kMustardCardRadius),
        side: BorderSide(color: c.edge),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: c.input,
      filled: true,
      isDense: true,
      hintStyle: TextStyle(color: c.dim),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder:
          inputBorder.copyWith(borderSide: BorderSide(color: c.accent)),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.accent,
      selectionColor: c.gold.withOpacity(0.45),
      selectionHandleColor: c.accent,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent),
    elevatedButtonTheme:
        ElevatedButtonThemeData(style: mustardPrimaryButton(c)),
    outlinedButtonTheme: OutlinedButtonThemeData(style: mustardSubtleButton(c)),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.text,
        splashFactory: NoSplash.splashFactory,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kMustardRadius)),
      ),
    ),
    checkboxTheme: base.checkboxTheme.copyWith(fillColor: toggle),
    radioTheme: base.radioTheme.copyWith(fillColor: toggle),
    switchTheme: base.switchTheme.copyWith(
      thumbColor: toggle,
      trackColor: MaterialStateProperty.resolveWith<Color?>((states) =>
          states.contains(MaterialState.selected)
              ? c.accent.withOpacity(0.5)
              : null),
    ),
    tabBarTheme: base.tabBarTheme
        .copyWith(labelColor: c.text, unselectedLabelColor: c.dim),
    popupMenuTheme: PopupMenuThemeData(
      color: c.card,
      elevation: 2,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: c.edge),
        borderRadius: BorderRadius.circular(kMustardRadius),
      ),
    ),
    menuBarTheme: MenuBarThemeData(
        style: MenuStyle(backgroundColor: MaterialStatePropertyAll(c.card))),
    extensions: <ThemeExtension<dynamic>>[
      (dark ? ColorThemeExtension.dark : ColorThemeExtension.light).copyWith(
        border: c.edge,
        border2: c.edge,
        border3: c.line,
        highlight: c.hover,
        divider: c.line,
      ),
      TabbarTheme(
        selectedTabIconColor: c.accent,
        unSelectedTabIconColor: c.dim,
        selectedTextColor: c.text,
        unSelectedTextColor: c.dim,
        selectedIconColor: c.text,
        unSelectedIconColor: c.dim,
        dividerColor: c.line,
        hoverColor: c.hover,
        closeHoverColor: c.danger,
        selectedTabBackgroundColor: c.bg,
      ),
    ],
  );
}

/// Each edition has one look: Support is light, Remote is dark. The Rust side
/// fixes the `theme` option to match, so both slots get the same theme.
void applyMustardTheme() {
  if (!isMustardClient) return;
  final theme = appName == 'MustardSupport'
      ? mustardTheme(MyTheme.lightTheme, MustardColors.light)
      : mustardTheme(MyTheme.darkTheme, MustardColors.dark);
  MyTheme.lightTheme = theme;
  MyTheme.darkTheme = theme;
}
