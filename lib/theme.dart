// lib/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Brand palette (aligned with the eDiscipline logo) ──────────────────────
const kPrimary = Color(0xFF2E7BEF);       // logo blue — main action color
const kPrimaryLight = Color(0xFFE7F0FE);
const kSuccess = Color(0xFF1FAE6A);       // logo emerald green
const kSuccessLight = Color(0xFFE3F6EC);
const kDanger = Color(0xFFE24B4A);
const kDangerLight = Color(0xFFFCEBEB);
const kWarning = Color(0xFFE0930C);        // logo gold
const kWarningLight = Color(0xFFFBEFD6);
const kDark = Color(0xFF0D1B3E);           // logo navy
const kNavy2 = Color(0xFF16294F);          // lighter navy for depth
const kScaffold = Color(0xFFF1F4F9);       // cool app background

// Green→blue accent, echoing the ring in the logo.
const kBrandGradient = LinearGradient(
  colors: [Color(0xFF35C15E), Color(0xFF2E86DE)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

// Deep navy header gradient used across the app.
const kHeaderGradient = LinearGradient(
  colors: [kDark, kNavy2],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Decoration for the app's dark headers: navy gradient + a thin brand accent
/// line at the bottom. Reused by every screen for a cohesive look.
BoxDecoration headerDecoration({double radius = 0}) => BoxDecoration(
      gradient: kHeaderGradient,
      borderRadius: radius > 0
          ? BorderRadius.vertical(bottom: Radius.circular(radius))
          : null,
      boxShadow: [
        BoxShadow(color: kDark.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6)),
      ],
    );

/// Bottom sheet for keyboard-driven forms (add / edit). It rises above the
/// keyboard and stays fully scrollable, so no field is ever hidden or squashed —
/// unlike a centered dialog which the keyboard compresses. Provide the form body
/// via [builder]; a drag handle, padding and keyboard inset are added for you.
Future<T?> showFormSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            builder(ctx),
          ],
        ),
      ),
    ),
  );
}

/// A 3px green→blue accent strip, echoing the logo ring. Sits under an AppBar.
class BrandAccentLine extends StatelessWidget implements PreferredSizeWidget {
  const BrandAccentLine({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(3);

  @override
  Widget build(BuildContext context) =>
      Container(height: 3, decoration: const BoxDecoration(gradient: kBrandGradient));
}

ThemeData appTheme() {
  final base = GoogleFonts.poppinsTextTheme();
  return ThemeData(
    useMaterial3: true,
    textTheme: base,
    colorScheme: ColorScheme.fromSeed(seedColor: kPrimary, primary: kPrimary, secondary: kSuccess),
    scaffoldBackgroundColor: kScaffold,
    appBarTheme: AppBarTheme(
      backgroundColor: kDark,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
    ),
    cardTheme: CardThemeData(
      elevation: 6,
      shadowColor: kDark.withOpacity(0.12),
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF7F8FB),
      labelStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF888780)),
      hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFFBBBBBB)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x22000000))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x1A000000))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kPrimary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary, foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 15), elevation: 0,
        textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kPrimary, side: const BorderSide(color: kPrimary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kPrimary,
        textStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kPrimary,
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white, selectedItemColor: kPrimary,
      unselectedItemColor: const Color(0xFFAAB0BC), elevation: 12,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
    ),
  );
}
