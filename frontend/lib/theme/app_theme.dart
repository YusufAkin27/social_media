import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeType {
  dark,
  light,
  vaporwave,
  midnight,
  nature,
  cream,
  sunset, // Yeni tema: günbatımı
  ocean, // Yeni tema: okyanus
  minimal, // Yeni tema: minimalist
  rose, // Yeni tema: rose gold
}

class AppColors {
  // Standart Dark Theme Colors - Modern ve canlı
  static const Color background = Color(0xFF121212);
  static const Color cardBackground = Color(0xFF1E1E1E);
  static const Color surfaceColor = Color(0xFF252525);
  static const Color accent = Color(0xFF8E24AA); // Mor
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFFB0B0B0);
  static const Color buttonBackground = Color(0xFF8E24AA);
  static const Color buttonText = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFF44336); // Kırmızı
  static const Color divider = Color(0xFF3A3A3A);
  static const Color inputBackground = Color(0xFF2A2A2A);
  static const Color success = Color(0xFF43A047); // Yeşil
  static const Color warning = Color(0xFFFF9800); // Turuncu
  static const Color link = Color(0xFF64B5F6); // Mavi

  // Light Theme Colors - Modern ve ferah
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color lightSurfaceColor = Color(0xFFF9FAFC);
  static const Color lightPrimaryText = Color(0xFF2B2D42);
  static const Color lightSecondaryText = Color(0xFF6C757D);
  static const Color lightAccent = Color(0xFF6A1B9A); // Koyu mor
  static const Color lightButtonBackground = Color(0xFF6A1B9A);
  static const Color lightButtonText = Color(0xFFFFFFFF);
  static const Color lightLink = Color(0xFF1976D2); // Koyu mavi
  static const Color lightError = Color(0xFFD32F2F);
  static const Color lightSuccess = Color(0xFF2E7D32);
  static const Color lightWarning = Color(0xFFEF6C00);

  // Vaporwave Theme - Retro 80s stili
  static const Color vaporwaveBackground = Color(0xFF0D0221);
  static const Color vaporwaveCardBackground = Color(0xFF1A1040);
  static const Color vaporwaveSurfaceColor = Color(0xFF2A1B70);
  static const Color vaporwaveAccent = Color(0xFFFF00FF); // Parlak pembe
  static const Color vaporwavePrimaryText = Color(0xFFFFFFFF);
  static const Color vaporwaveSecondaryText = Color(0xFFCBB6FC);
  static const Color vaporwaveButtonBackground = Color(0xFF00FFFF); // Cyan
  static const Color vaporwaveButtonText = Color(0xFF000000);
  static const Color vaporwaveError = Color(0xFFFF5252);
  static const Color vaporwaveDivider = Color(0xFF494297);
  static const Color vaporwaveInputBackground = Color(0xFF2C2056);
  static const Color vaporwaveSuccess = Color(0xFF00FFAA);
  static const Color vaporwaveWarning = Color(0xFFFFD200);
  static const Color vaporwaveLink = Color(0xFF00FFFF);

  // Midnight Blue Theme - Koyu mavi tonları
  static const Color midnightBackground = Color(0xFF0F1729);
  static const Color midnightCardBackground = Color(0xFF182039);
  static const Color midnightSurfaceColor = Color(0xFF222E4D);
  static const Color midnightAccent = Color(0xFF00B8D4); // Turkuaz
  static const Color midnightPrimaryText = Color(0xFFFFFFFF);
  static const Color midnightSecondaryText = Color(0xFFB0C7E0);
  static const Color midnightButtonBackground = Color(0xFF00B8D4);
  static const Color midnightButtonText = Color(0xFF0F1729);
  static const Color midnightError = Color(0xFFFF6B6B);
  static const Color midnightDivider = Color(0xFF304269);
  static const Color midnightInputBackground = Color(0xFF263455);
  static const Color midnightSuccess = Color(0xFF4CAF50);
  static const Color midnightWarning = Color(0xFFFFBB33);
  static const Color midnightLink = Color(0xFF00E5FF);

  // Nature Theme - Doğa yeşili ve organik tonlar
  static const Color natureBackground = Color(0xFF1C2B27);
  static const Color natureCardBackground = Color(0xFF2A3C34);
  static const Color natureSurfaceColor = Color(0xFF344940);
  static const Color natureAccent = Color(0xFF4CAF50); // Yeşil
  static const Color naturePrimaryText = Color(0xFFE5F2E5);
  static const Color natureSecondaryText = Color(0xFFB3D0B3);
  static const Color natureButtonBackground = Color(0xFF4CAF50);
  static const Color natureButtonText = Color(0xFFFFFFFF);
  static const Color natureError = Color(0xFFE57373);
  static const Color natureDivider = Color(0xFF42614A);
  static const Color natureInputBackground = Color(0xFF3A5344);
  static const Color natureSuccess = Color(0xFF81C784);
  static const Color natureWarning = Color(0xFFFFD54F);
  static const Color natureLink = Color(0xFF80CBC4);

  // Cream Theme - Sıcak ve sakin tonlar
  static const Color creamBackground = Color(0xFFFFF8E1);
  static const Color creamCardBackground = Color(0xFFFFFDE7);
  static const Color creamSurfaceColor = Color(0xFFFFF9C4);
  static const Color creamAccent = Color(0xFFFF9800); // Turuncu
  static const Color creamPrimaryText = Color(0xFF5D4037);
  static const Color creamSecondaryText = Color(0xFF8D6E63);
  static const Color creamButtonBackground = Color(0xFFFF9800);
  static const Color creamButtonText = Color(0xFFFFFFFF);
  static const Color creamError = Color(0xFFE53935);
  static const Color creamDivider = Color(0xFFE6D4A8);
  static const Color creamInputBackground = Color(0xFFF5E9C0);
  static const Color creamSuccess = Color(0xFF8BC34A);
  static const Color creamWarning = Color(0xFFFFA000);
  static const Color creamLink = Color(0xFFFF5722);

  // Sunset Theme - Sıcak ve kontrastlı tonlar
  static const Color sunsetBackground = Color(0xFF2B2024);
  static const Color sunsetCardBackground = Color(0xFF3B2C30);
  static const Color sunsetSurfaceColor = Color(0xFF4B3640);
  static const Color sunsetAccent = Color(0xFFFF5722); // Turuncu-kırmızı
  static const Color sunsetPrimaryText = Color(0xFFFFF8E1);
  static const Color sunsetSecondaryText = Color(0xFFFFCCBC);
  static const Color sunsetButtonBackground = Color(0xFFFF5722);
  static const Color sunsetButtonText = Color(0xFFFFF8E1);
  static const Color sunsetError = Color(0xFFE57373);
  static const Color sunsetDivider = Color(0xFF5D4037);
  static const Color sunsetInputBackground = Color(0xFF4E342E);
  static const Color sunsetSuccess = Color(0xFF66BB6A);
  static const Color sunsetWarning = Color(0xFFFFCA28);
  static const Color sunsetLink = Color(0xFFFFB74D);

  // Ocean Theme - Derin deniz mavileri
  static const Color oceanBackground = Color(0xFF01579B);
  static const Color oceanCardBackground = Color(0xFF0277BD);
  static const Color oceanSurfaceColor = Color(0xFF0288D1);
  static const Color oceanAccent = Color(0xFF00BCD4); // Açık mavi
  static const Color oceanPrimaryText = Color(0xFFE1F5FE);
  static const Color oceanSecondaryText = Color(0xFFB3E5FC);
  static const Color oceanButtonBackground = Color(0xFF00BCD4);
  static const Color oceanButtonText = Color(0xFF01579B);
  static const Color oceanError = Color(0xFFFF8A80);
  static const Color oceanDivider = Color(0xFF039BE5);
  static const Color oceanInputBackground = Color(0xFF0288D1);
  static const Color oceanSuccess = Color(0xFF64FFDA);
  static const Color oceanWarning = Color(0xFFFFD740);
  static const Color oceanLink = Color(0xFF84FFFF);

  // Minimal Theme - Sade ve elegant
  static const Color minimalBackground = Color(0xFFFAFAFA);
  static const Color minimalCardBackground = Color(0xFFFFFFFF);
  static const Color minimalSurfaceColor = Color(0xFFF5F5F5);
  static const Color minimalAccent = Color(0xFF212121); // Siyah
  static const Color minimalPrimaryText = Color(0xFF212121);
  static const Color minimalSecondaryText = Color(0xFF757575);
  static const Color minimalButtonBackground = Color(0xFF212121);
  static const Color minimalButtonText = Color(0xFFFFFFFF);
  static const Color minimalError = Color(0xFFF44336);
  static const Color minimalDivider = Color(0xFFEEEEEE);
  static const Color minimalInputBackground = Color(0xFFF5F5F5);
  static const Color minimalSuccess = Color(0xFF4CAF50);
  static const Color minimalWarning = Color(0xFFFFC107);
  static const Color minimalLink = Color(0xFF2196F3);

  // Rose Theme - Rose gold ve pembe tonlar
  static const Color roseBackground = Color(0xFFFFF0F5);
  static const Color roseCardBackground = Color(0xFFFFF5F8);
  static const Color roseSurfaceColor = Color(0xFFFFEBEE);
  static const Color roseAccent = Color(0xFFEC407A); // Pembe
  static const Color rosePrimaryText = Color(0xFF4E342E);
  static const Color roseSecondaryText = Color(0xFF795548);
  static const Color roseButtonBackground = Color(0xFFEC407A);
  static const Color roseButtonText = Color(0xFFFFFFFF);
  static const Color roseError = Color(0xFFE53935);
  static const Color roseDivider = Color(0xFFFFCDD2);
  static const Color roseInputBackground = Color(0xFFFCE4EC);
  static const Color roseSuccess = Color(0xFF66BB6A);
  static const Color roseWarning = Color(0xFFFFB74D);
  static const Color roseLink = Color(0xFFAD1457);

  // Base colors
  static const Color primary = Color(0xFF6A1B9A); // Ana renk (koyu mor)
  static const Color secondary = Color(0xFF26A69A); // İkincil renk (turkuaz)
  static const Color lightPrimary = Color(0xFF7B1FA2); // Açık tema ana renk
  static const Color lightSecondary =
      Color(0xFF00897B); // Açık tema ikincil renk
}

class AppTheme {
  static ThemeData get darkTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      background: AppColors.background,
      cardBackground: AppColors.cardBackground,
      surfaceColor: AppColors.surfaceColor,
      accent: AppColors.accent,
      primaryText: AppColors.primaryText,
      secondaryText: AppColors.secondaryText,
      buttonBackground: AppColors.buttonBackground,
      buttonText: AppColors.buttonText,
      error: AppColors.error,
      divider: AppColors.divider,
      inputBackground: AppColors.inputBackground,
      success: AppColors.success,
      warning: AppColors.warning,
      link: AppColors.link,
    );
  }

  static ThemeData get lightTheme {
    return _buildTheme(
      brightness: Brightness.light,
      background: AppColors.lightBackground,
      cardBackground: AppColors.lightCardBackground,
      surfaceColor: AppColors.lightSurfaceColor,
      accent: AppColors.lightAccent,
      primaryText: AppColors.lightPrimaryText,
      secondaryText: AppColors.lightSecondaryText,
      buttonBackground: AppColors.lightButtonBackground,
      buttonText: AppColors.lightButtonText,
      error: AppColors.lightError,
      divider: AppColors.lightSecondaryText.withOpacity(0.3),
      inputBackground: AppColors.lightBackground.withOpacity(0.5),
      success: AppColors.lightSuccess,
      warning: AppColors.lightWarning,
      link: AppColors.lightLink,
    );
  }

  static ThemeData get vaporwaveTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      background: AppColors.vaporwaveBackground,
      cardBackground: AppColors.vaporwaveCardBackground,
      surfaceColor: AppColors.vaporwaveSurfaceColor,
      accent: AppColors.vaporwaveAccent,
      primaryText: AppColors.vaporwavePrimaryText,
      secondaryText: AppColors.vaporwaveSecondaryText,
      buttonBackground: AppColors.vaporwaveButtonBackground,
      buttonText: AppColors.vaporwaveButtonText,
      error: AppColors.vaporwaveError,
      divider: AppColors.vaporwaveDivider,
      inputBackground: AppColors.vaporwaveInputBackground,
      success: AppColors.vaporwaveSuccess,
      warning: AppColors.vaporwaveWarning,
      link: AppColors.vaporwaveLink,
    );
  }

  static ThemeData get midnightTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      background: AppColors.midnightBackground,
      cardBackground: AppColors.midnightCardBackground,
      surfaceColor: AppColors.midnightSurfaceColor,
      accent: AppColors.midnightAccent,
      primaryText: AppColors.midnightPrimaryText,
      secondaryText: AppColors.midnightSecondaryText,
      buttonBackground: AppColors.midnightButtonBackground,
      buttonText: AppColors.midnightButtonText,
      error: AppColors.midnightError,
      divider: AppColors.midnightDivider,
      inputBackground: AppColors.midnightInputBackground,
      success: AppColors.midnightSuccess,
      warning: AppColors.midnightWarning,
      link: AppColors.midnightLink,
    );
  }

  static ThemeData get natureTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      background: AppColors.natureBackground,
      cardBackground: AppColors.natureCardBackground,
      surfaceColor: AppColors.natureSurfaceColor,
      accent: AppColors.natureAccent,
      primaryText: AppColors.naturePrimaryText,
      secondaryText: AppColors.natureSecondaryText,
      buttonBackground: AppColors.natureButtonBackground,
      buttonText: AppColors.natureButtonText,
      error: AppColors.natureError,
      divider: AppColors.natureDivider,
      inputBackground: AppColors.natureInputBackground,
      success: AppColors.natureSuccess,
      warning: AppColors.natureWarning,
      link: AppColors.natureLink,
    );
  }

  static ThemeData get creamTheme {
    return _buildTheme(
      brightness: Brightness.light,
      background: AppColors.creamBackground,
      cardBackground: AppColors.creamCardBackground,
      surfaceColor: AppColors.creamSurfaceColor,
      accent: AppColors.creamAccent,
      primaryText: AppColors.creamPrimaryText,
      secondaryText: AppColors.creamSecondaryText,
      buttonBackground: AppColors.creamButtonBackground,
      buttonText: AppColors.creamButtonText,
      error: AppColors.creamError,
      divider: AppColors.creamDivider,
      inputBackground: AppColors.creamInputBackground,
      success: AppColors.creamSuccess,
      warning: AppColors.creamWarning,
      link: AppColors.creamLink,
    );
  }

  // Yeni tema: Sunset
  static ThemeData get sunsetTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      background: AppColors.sunsetBackground,
      cardBackground: AppColors.sunsetCardBackground,
      surfaceColor: AppColors.sunsetSurfaceColor,
      accent: AppColors.sunsetAccent,
      primaryText: AppColors.sunsetPrimaryText,
      secondaryText: AppColors.sunsetSecondaryText,
      buttonBackground: AppColors.sunsetButtonBackground,
      buttonText: AppColors.sunsetButtonText,
      error: AppColors.sunsetError,
      divider: AppColors.sunsetDivider,
      inputBackground: AppColors.sunsetInputBackground,
      success: AppColors.sunsetSuccess,
      warning: AppColors.sunsetWarning,
      link: AppColors.sunsetLink,
    );
  }

  // Yeni tema: Ocean
  static ThemeData get oceanTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      background: AppColors.oceanBackground,
      cardBackground: AppColors.oceanCardBackground,
      surfaceColor: AppColors.oceanSurfaceColor,
      accent: AppColors.oceanAccent,
      primaryText: AppColors.oceanPrimaryText,
      secondaryText: AppColors.oceanSecondaryText,
      buttonBackground: AppColors.oceanButtonBackground,
      buttonText: AppColors.oceanButtonText,
      error: AppColors.oceanError,
      divider: AppColors.oceanDivider,
      inputBackground: AppColors.oceanInputBackground,
      success: AppColors.oceanSuccess,
      warning: AppColors.oceanWarning,
      link: AppColors.oceanLink,
    );
  }

  // Yeni tema: Minimal
  static ThemeData get minimalTheme {
    return _buildTheme(
      brightness: Brightness.light,
      background: AppColors.minimalBackground,
      cardBackground: AppColors.minimalCardBackground,
      surfaceColor: AppColors.minimalSurfaceColor,
      accent: AppColors.minimalAccent,
      primaryText: AppColors.minimalPrimaryText,
      secondaryText: AppColors.minimalSecondaryText,
      buttonBackground: AppColors.minimalButtonBackground,
      buttonText: AppColors.minimalButtonText,
      error: AppColors.minimalError,
      divider: AppColors.minimalDivider,
      inputBackground: AppColors.minimalInputBackground,
      success: AppColors.minimalSuccess,
      warning: AppColors.minimalWarning,
      link: AppColors.minimalLink,
    );
  }

  // Yeni tema: Rose
  static ThemeData get roseTheme {
    return _buildTheme(
      brightness: Brightness.light,
      background: AppColors.roseBackground,
      cardBackground: AppColors.roseCardBackground,
      surfaceColor: AppColors.roseSurfaceColor,
      accent: AppColors.roseAccent,
      primaryText: AppColors.rosePrimaryText,
      secondaryText: AppColors.roseSecondaryText,
      buttonBackground: AppColors.roseButtonBackground,
      buttonText: AppColors.roseButtonText,
      error: AppColors.roseError,
      divider: AppColors.roseDivider,
      inputBackground: AppColors.roseInputBackground,
      success: AppColors.roseSuccess,
      warning: AppColors.roseWarning,
      link: AppColors.roseLink,
    );
  }

  // Tema tipine göre ThemeData döndüren yardımcı metod
  static ThemeData getThemeByType(ThemeType themeType) {
    switch (themeType) {
      case ThemeType.dark:
        return darkTheme;
      case ThemeType.light:
        return lightTheme;
      case ThemeType.vaporwave:
        return vaporwaveTheme;
      case ThemeType.midnight:
        return midnightTheme;
      case ThemeType.nature:
        return natureTheme;
      case ThemeType.cream:
        return creamTheme;
      case ThemeType.sunset:
        return sunsetTheme;
      case ThemeType.ocean:
        return oceanTheme;
      case ThemeType.minimal:
        return minimalTheme;
      case ThemeType.rose:
        return roseTheme;
      default:
        return darkTheme;
    }
  }

  // Tüm temaları oluşturan ortak metod
  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color cardBackground,
    required Color surfaceColor,
    required Color accent,
    required Color primaryText,
    required Color secondaryText,
    required Color buttonBackground,
    required Color buttonText,
    required Color error,
    required Color divider,
    required Color inputBackground,
    required Color success,
    required Color warning,
    required Color link,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      primaryColor: accent,
      colorScheme: brightness == Brightness.dark
          ? ColorScheme.dark(
              primary: accent,
              secondary: accent,
              background: background,
              surface: cardBackground,
              error: error,
              onPrimary: buttonText,
              onSecondary: buttonText,
              onBackground: primaryText,
              onSurface: primaryText,
              onError: Colors.white,
            )
          : ColorScheme.light(
              primary: accent,
              secondary: link,
              background: background,
              surface: cardBackground,
              error: error,
              onPrimary: buttonText,
              onSecondary: buttonText,
              onBackground: primaryText,
              onSurface: primaryText,
              onError: Colors.white,
            ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: primaryText,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light,
        ),
      ),
      cardTheme: CardTheme(
        color: cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        shadowColor:
            Colors.black.withOpacity(brightness == Brightness.dark ? 0.2 : 0.1),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonBackground,
          foregroundColor: buttonText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 2,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryText,
          side: BorderSide(color: accent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBackground,
        labelStyle: TextStyle(color: secondaryText),
        hintStyle: TextStyle(color: secondaryText.withOpacity(0.7)),
        prefixIconColor: accent,
        suffixIconColor: accent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: secondaryText.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: error, width: 1.5),
        ),
        errorStyle: TextStyle(color: error),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(TextTheme(
        displayLarge: TextStyle(color: primaryText),
        displayMedium: TextStyle(color: primaryText),
        displaySmall: TextStyle(color: primaryText),
        headlineLarge: TextStyle(color: primaryText),
        headlineMedium: TextStyle(color: primaryText),
        headlineSmall: TextStyle(color: primaryText),
        titleLarge: TextStyle(color: primaryText),
        titleMedium: TextStyle(color: primaryText),
        titleSmall: TextStyle(color: primaryText),
        bodyLarge: TextStyle(color: primaryText),
        bodyMedium: TextStyle(color: primaryText),
        bodySmall: TextStyle(color: secondaryText),
        labelLarge: TextStyle(color: primaryText),
        labelMedium: TextStyle(color: secondaryText),
        labelSmall: TextStyle(color: secondaryText),
      )),
      iconTheme: IconThemeData(
        color: accent,
      ),
      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 1,
        space: 24,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return accent;
          }
          return secondaryText;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return accent;
          }
          return secondaryText;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return accent.withOpacity(0.5);
          }
          return secondaryText.withOpacity(0.3);
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: accent,
        unselectedItemColor: secondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceColor,
        contentTextStyle: TextStyle(color: primaryText),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: buttonText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: accent,
        unselectedLabelColor: secondaryText,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        disabledColor: surfaceColor.withOpacity(0.5),
        selectedColor: accent,
        secondarySelectedColor: accent,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        labelStyle: TextStyle(color: primaryText),
        secondaryLabelStyle: TextStyle(color: buttonText),
        brightness: brightness,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: cardBackground.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: primaryText),
      ),
    );
  }
}
