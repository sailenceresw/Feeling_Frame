import 'package:flutter/material.dart';

import 'color.dart';

/// Builds the application theme. When [highContrast] is true the palette
/// switches to pure black/white with bolder text for improved accessibility
/// (WCAG-oriented), as outlined in the project's accessibility goals.
ThemeData buildAppTheme({bool highContrast = false}) {
  final Color background =
      highContrast ? Colors.black : AppColor.kPrimaryMain;
  final Color surface =
      highContrast ? const Color(0xFF000000) : const Color(0xFF101A2E);
  final Color accent = highContrast ? Colors.yellowAccent : Colors.yellow;
  const Color onSurface = Colors.white;

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Quicksand',
    brightness: Brightness.dark,
    primaryColor: AppColor.kPrimaryMain,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.yellow,
      brightness: Brightness.dark,
    ).copyWith(
      primary: accent,
      secondary: highContrast ? Colors.white : Colors.orangeAccent,
      surface: surface,
      onSurface: onSurface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        fontFamily: 'Quicksand',
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: onSurface,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.black,
        disabledBackgroundColor: accent.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: const TextStyle(
          fontFamily: 'Quicksand',
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: BorderSide(color: accent, width: highContrast ? 1.5 : 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: accent),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: highContrast ? const Color(0xFF111111) : const Color(0xFF1C2C43),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titleTextStyle: const TextStyle(
        fontFamily: 'Quicksand',
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: onSurface,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: accent,
      thumbColor: accent,
      inactiveTrackColor: Colors.white24,
      valueIndicatorColor: accent,
      valueIndicatorTextStyle: const TextStyle(
        color: Colors.black,
        fontFamily: 'Quicksand',
        fontWeight: FontWeight.bold,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    listTileTheme: ListTileThemeData(iconColor: accent),
    dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: highContrast ? 0.3 : 0.12)),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF1C2C43),
      contentTextStyle: TextStyle(
        fontFamily: 'Quicksand',
        color: Colors.white,
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
