// alaif_theme.dart
//
// Material ThemeData built from design_tokens.dart, so the Flutter shell
// (main menu, settings, pause/game-over/how-to overlays) picks up consistent
// styling with minimal per-widget overrides. Wrap MaterialApp:
//
//   MaterialApp(theme: buildAlaifTheme(), home: ...);
//
// Suggested path in repo: app/lib/ui/alaif_theme.dart

import 'package:flutter/material.dart';

import 'package:alaif/ui/design_tokens.dart';

ThemeData buildAlaifTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AlaifColors.ink,
    onPrimary: AlaifColors.onInk,
    secondary: AlaifColors.seal,
    onSecondary: AlaifColors.onInk,
    surface: AlaifColors.surface,
    onSurface: AlaifColors.inkSoft,
    error: AlaifColors.seal,
    onError: AlaifColors.onInk,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AlaifColors.paper,
    canvasColor: AlaifColors.paper,
    fontFamily: AlaifFonts.ui,
    splashColor: AlaifColors.hairline,
    highlightColor: AlaifColors.hairline,

    textTheme: const TextTheme(
      displayLarge: AlaifType.titleDisplay,
      headlineMedium: AlaifType.heading,
      titleMedium: AlaifType.subheading,
      bodyLarge: AlaifType.body,
      bodyMedium: AlaifType.bodyMuted,
      labelLarge: AlaifType.button,
      labelMedium: AlaifType.label,
      bodySmall: AlaifType.caption,
    ),

    // Primary action = ink-filled, near-square.
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AlaifColors.ink,
        foregroundColor: AlaifColors.onInk,
        elevation: 0,
        minimumSize: const Size.fromHeight(58),
        padding: const EdgeInsets.symmetric(vertical: AlaifSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AlaifRadii.sm),
        ),
        textStyle: AlaifType.button,
      ),
    ),

    // Secondary action = ghost, hairline border.
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AlaifColors.ink,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AlaifColors.hairline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AlaifRadii.sm),
        ),
        textStyle: AlaifType.buttonGhost,
      ),
    ),

    // Tertiary = underlined text link (How to play / Sound / Quit to menu).
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AlaifColors.inkMuted,
        textStyle: AlaifType.buttonGhost,
      ),
    ),

    // Settings switches read as ink pills.
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AlaifColors.paper : AlaifColors.inkMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AlaifColors.ink : Colors.transparent,
      ),
      trackOutlineColor: WidgetStateProperty.all(AlaifColors.hairline),
    ),

    dividerTheme: const DividerThemeData(
      color: AlaifColors.hairline, thickness: 1, space: 1,
    ),

    iconTheme: const IconThemeData(color: AlaifColors.ink, size: 24),
  );
}
