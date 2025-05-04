import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Define the color palette based on requirements (approximating Tailwind colors)
class AppColors {
  static const Color primaryBlue = Color(0xFF2563EB); // blue-600
  static const Color primaryBlueHover = Color(0xFF1D4ED8); // blue-700

  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6); // Secondary button bg
  static const Color gray200 = Color(0xFFE5E7EB); // Subtle borders, Secondary button hover bg
  static const Color gray500 = Color(0xFF6B7280); // Labels
  static const Color gray700 = Color(0xFF374151); // Body text, Secondary button text
  static const Color gray800 = Color(0xFF1F2937); // Screen titles
  static const Color gray900 = Color(0xFF111827); // List item titles

  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // Status colors (can be refined)
  static const Color successGreen = Colors.green;
  static const Color errorRed = Colors.red;
  static const Color warningYellow = Colors.amber;
}

// Define the AppTheme
class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primaryBlue,
    scaffoldBackgroundColor: AppColors.white, // Use white or a very light gray like gray50
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryBlue,
      secondary: AppColors.primaryBlue, // Can define a different secondary if needed
      surface: AppColors.white,
      background: AppColors.white,
      error: AppColors.errorRed,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onSurface: AppColors.gray900,
      onBackground: AppColors.gray900,
      onError: AppColors.white,
      brightness: Brightness.light,
      // Define other colors based on usage
      outline: AppColors.gray200, // For subtle borders
    ),
    textTheme: GoogleFonts.interTextTheme(
      ThemeData.light().textTheme.copyWith(
            // Screen Titles (approximating text-lg font-semibold)
            headlineSmall: TextStyle(
              fontSize: 20, // text-lg approx
              fontWeight: FontWeight.w600, // font-semibold
              color: AppColors.gray800,
            ),
            // List Item Titles (approximating text-base font-medium)
            titleMedium: TextStyle(
              fontSize: 16, // text-base approx
              fontWeight: FontWeight.w500, // font-medium
              color: AppColors.gray900,
            ),
            // Body Text (approximating text-sm)
            bodyMedium: TextStyle(
              fontSize: 14, // text-sm approx
              fontWeight: FontWeight.normal,
              color: AppColors.gray700,
            ),
            // Labels (approximating text-xs font-medium)
            labelSmall: TextStyle(
              fontSize: 12, // text-xs approx
              fontWeight: FontWeight.w500, // font-medium
              color: AppColors.gray500,
            ),
            // Default button text style
            labelLarge: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.gray800, // Back button, title color
      elevation: 0, // Minimalist
      titleTextStyle: GoogleFonts.inter( // Ensure AppBar title uses Inter
        fontSize: 20, 
        fontWeight: FontWeight.w600, 
        color: AppColors.gray800,
      ),
      iconTheme: IconThemeData(
        color: AppColors.gray800, // Ensure back icon uses correct color
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // px-4 py-2 approx
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0), // rounded-lg
        ),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        elevation: 1, // Subtle shadow
      ).copyWith(
        // Define hover state if possible, though ButtonStyle doesn't directly support hover color easily
        // Might need custom handling or rely on default elevation changes for visual feedback
      ),
    ),
    textButtonTheme: TextButtonThemeData(
       style: TextButton.styleFrom(
        backgroundColor: AppColors.gray100, // Secondary Action Style 1
        foregroundColor: AppColors.gray700,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0), // rounded-lg
        borderSide: BorderSide(color: AppColors.gray200, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: AppColors.gray200, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.0), // focus:ring-1 focus:ring-blue-500
      ),
      labelStyle: GoogleFonts.inter(color: AppColors.gray500, fontSize: 14),
      hintStyle: GoogleFonts.inter(color: AppColors.gray500, fontSize: 14),
    ),
    cardTheme: CardTheme(
      elevation: 1, // shadow-sm approx
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0), // rounded-lg
        side: BorderSide(color: AppColors.gray200, width: 1.0), // Subtle border
      ),
      color: AppColors.white,
      margin: EdgeInsets.zero, // Control margin where card is used
    ),
    dividerTheme: DividerThemeData(
      color: AppColors.gray200,
      thickness: 1.0,
      space: 1, // Minimal space
    ),
    // Define other component themes as needed (e.g., BottomNavigationBarTheme)
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.primaryBlue,
      unselectedItemColor: AppColors.gray500,
      selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
      type: BottomNavigationBarType.fixed, // Ensure labels are always visible
      elevation: 2, // Slight elevation to separate from content
    ),
  );
}

