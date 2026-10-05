import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nthaka_eco/app/app_preferences.dart';

/// Shared visual tokens and component themes for the entire application.
abstract final class AppTheme {
  // Apple-inspired semantic colour tokens.
  static const blue = Color(0xFF007AFF);
  static const green = Color(0xFF34C759);
  static const red = Color(0xFFFF3B30);
  static const orange = Color(0xFFFF9500);
  static const backgroundLight = Color(0xFFF2F2F7);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const separatorLight = Color(0xFFC6C6C8);
  static const secondaryTextLight = Color(0xFF8E8E93);
  static const primaryTextLight = Color(0xFF1C1C1E);
  static const backgroundDark = Color(0xFF000000);
  static const surfaceDark = Color(0xFF1C1C1E);
  static const separatorDark = Color(0xFF38383A);
  static const secondaryTextDark = Color(0xFF98989D);
  static const primaryTextDark = Color(0xFFF2F2F7);

  static const spacing4 = 4.0;
  static const spacing8 = 8.0;
  static const spacing12 = 12.0;
  static const spacing16 = 16.0;
  static const spacing20 = 20.0;
  static const spacing24 = 24.0;
  static const spacing32 = 32.0;

  static const controlRadius = 10.0;
  static const cardRadius = 14.0;
  static const sheetRadius = 20.0;
  static const controlHeight = 44.0;

  /// Use this shared style for destructive icon-only actions.
  static final destructiveIconButtonStyle = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
    foregroundColor: const WidgetStatePropertyAll(red),
    overlayColor: WidgetStatePropertyAll(red.withValues(alpha: 0.12)),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(controlRadius),
      ),
    ),
  );

  /// Use this shared style for destructive confirmation actions.
  static final destructiveButtonStyle = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(44, controlHeight)),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing12),
    ),
    backgroundColor: const WidgetStatePropertyAll(red),
    foregroundColor: const WidgetStatePropertyAll(Colors.white),
    overlayColor: const WidgetStatePropertyAll(Color(0x1AFFFFFF)),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(controlRadius),
      ),
    ),
    textStyle: const WidgetStatePropertyAll(
      TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  );

  /// Retained for the POS's dark ticket panel.
  static const posPanelDark = Color(0xFF1C1C1E);
  static const posPanelDarkElevated = Color(0xFF2C2C2E);
  static const posAccent = green;

  static ThemeData light() => _theme(Brightness.light);

  static ThemeData dark() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final surface = isDark ? surfaceDark : surfaceLight;
    final background = isDark ? backgroundDark : backgroundLight;
    final onSurface = isDark ? primaryTextDark : primaryTextLight;
    final secondaryText = isDark ? secondaryTextDark : secondaryTextLight;
    final separator = isDark ? separatorDark : separatorLight;
    final fieldFill = isDark ? const Color(0xFF2C2C2E) : backgroundLight;
    final primaryContainer =
        isDark ? const Color(0xFF003E75) : const Color(0xFFE5F1FF);
    final onPrimaryContainer =
        isDark ? const Color(0xFFD8E9FF) : const Color(0xFF00315E);

    final scheme = ColorScheme.fromSeed(
      seedColor: blue,
      brightness: brightness,
    ).copyWith(
      primary: blue,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: green,
      tertiary: orange,
      error: red,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: secondaryText,
      outline: separator,
      outlineVariant: separator.withValues(alpha: isDark ? 0.7 : 0.65),
    );

    final roundedControl = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(controlRadius),
    );
    final roundedCard = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(cardRadius),
      side: BorderSide(
        color: separator.withValues(alpha: isDark ? 0.72 : 0.55),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'SF Pro Text',
      fontFamilyFallback: const [
        'SF Pro Display',
        'Inter',
        'Segoe UI',
        'Roboto',
        'sans-serif',
      ],
      textTheme: _textTheme(onSurface, secondaryText),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: surface.withValues(alpha: 0.92),
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        backgroundColor: surface.withValues(alpha: 0.96),
        indicatorColor: primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: secondaryText,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: blue,
        unselectedLabelColor: secondaryText,
        indicatorColor: blue,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        surfaceTintColor: Colors.transparent,
        shape: roundedCard,
        color: surface,
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: separator.withValues(alpha: 0.7),
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing4,
        ),
        iconColor: blue,
        textColor: onSurface,
        subtitleTextStyle: TextStyle(fontSize: 13, color: secondaryText),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(44, controlHeight)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing12),
          ),
          shape: WidgetStatePropertyAll(roundedControl),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          overlayColor: const WidgetStatePropertyAll(Color(0x1AFFFFFF)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(44, controlHeight)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing12),
          ),
          backgroundColor: WidgetStatePropertyAll(fieldFill),
          foregroundColor: const WidgetStatePropertyAll(blue),
          side: WidgetStatePropertyAll(
            BorderSide(color: separator.withValues(alpha: 0.7)),
          ),
          shape: WidgetStatePropertyAll(roundedControl),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(44, controlHeight)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: spacing12, vertical: spacing8),
          ),
          foregroundColor: const WidgetStatePropertyAll(blue),
          shape: WidgetStatePropertyAll(roundedControl),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
          foregroundColor: const WidgetStatePropertyAll(blue),
          shape: WidgetStatePropertyAll(roundedControl),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        labelStyle: TextStyle(fontSize: 13, color: secondaryText),
        hintStyle: TextStyle(fontSize: 15, color: secondaryText),
        helperStyle: TextStyle(fontSize: 13, color: secondaryText),
        errorStyle: const TextStyle(
          fontSize: 13,
          color: red,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: secondaryText,
        suffixIconColor: secondaryText,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing12,
          vertical: spacing12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: separator.withValues(alpha: 0.75)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: const BorderSide(color: blue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: const BorderSide(color: red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: const BorderSide(color: red, width: 2),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: separator),
      ),
      radioTheme: const RadioThemeData(fillColor: WidgetStatePropertyAll(blue)),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? green : separator,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(44, 40)),
          side: WidgetStatePropertyAll(BorderSide(color: separator)),
          shape: WidgetStatePropertyAll(roundedControl),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: fieldFill,
        selectedColor: primaryContainer,
        labelStyle: TextStyle(fontSize: 13, color: onSurface),
        side: BorderSide(color: separator.withValues(alpha: 0.75)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(sheetRadius),
        ),
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        contentTextStyle: TextStyle(
          fontSize: 15,
          height: 1.4,
          color: secondaryText,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        modalBackgroundColor: surface,
        modalElevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(sheetRadius)),
        ),
        dragHandleColor: separator,
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : primaryTextLight,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: primaryContainer,
        headerForegroundColor: onPrimaryContainer,
        dayForegroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : onSurface,
        ),
        dayBackgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? blue : null,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(sheetRadius),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) => TextTheme(
        displaySmall: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        titleSmall: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
        bodyLarge: TextStyle(fontSize: 17, height: 1.4, color: primary),
        bodyMedium: TextStyle(fontSize: 15, height: 1.4, color: primary),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        bodySmall: TextStyle(fontSize: 13, height: 1.35, color: secondary),
        labelMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: secondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: secondary,
        ),
      );

  static String formatMoney(double value) =>
      '${AppPreferences.currency.value} ${value.toStringAsFixed(2)}';
}