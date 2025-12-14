import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hospital_microgrid/pages/establishments_list_page.dart';
import 'package:hospital_microgrid/pages/ai_prediction.dart';
import 'package:hospital_microgrid/pages/auto_learning.dart';
import 'package:hospital_microgrid/pages/welcome_page.dart';
import 'package:hospital_microgrid/providers/theme_provider.dart';
import 'package:hospital_microgrid/theme/medical_solar_colors.dart';

void main() async {
 WidgetsFlutterBinding.ensureInitialized();
 runApp(const MyApp());
}

class MyApp extends StatefulWidget {
 const MyApp({super.key});

 @override
 State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
 final ThemeProvider _themeProvider = ThemeProvider();

 @override
 void dispose() {
 _themeProvider.dispose();
 super.dispose();
 }

 @override
 Widget build(BuildContext context) {
 return ListenableBuilder(
 listenable: _themeProvider,
 builder: (context, child) {
 return MaterialApp(
 title: 'Hospital Microgrid',
 debugShowCheckedModeBanner: false,
 themeMode: _themeProvider.themeMode,
 theme: ThemeData(
 useMaterial3: true,
 brightness: Brightness.light,
 colorScheme: const ColorScheme.light(
 // Palette "Medical Solar" - Clair, lumineux, respirant, naturel
 primary: MedicalSolarColors.medicalBlue,
 secondary: MedicalSolarColors.solarGreen,
 tertiary: MedicalSolarColors.solarYellow,
 surface: MedicalSolarColors.offWhite,
 onPrimary: Colors.white,
 onSecondary: Colors.white,
 onTertiary: MedicalSolarColors.softGrey,
 onSurface: MedicalSolarColors.softGrey,
 error: Color(0xFFE74C3C), // Rouge doux
 onError: Colors.white,
 ),
 textTheme: GoogleFonts.interTextTheme().copyWith(
 bodyLarge: GoogleFonts.inter().copyWith(
 fontFamily: 'Inter',
 color: MedicalSolarColors.softGrey,
 ),
 ),
 scaffoldBackgroundColor: MedicalSolarColors.offWhite,
 appBarTheme: const AppBarTheme(
 backgroundColor: MedicalSolarColors.offWhite,
 foregroundColor: MedicalSolarColors.softGrey,
 elevation: 0,
 centerTitle: false,
 titleTextStyle: TextStyle(
 fontSize: 22,
 fontWeight: FontWeight.w600,
 fontFamily: 'Inter',
 color: MedicalSolarColors.softGrey,
 ),
 ),
 cardTheme: CardThemeData(
 color: Colors.white,
 elevation: 0,
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(20),
 side: BorderSide(
 color: MedicalSolarColors.medicalBlue.withOpacity(0.1),
 width: 1,
 ),
 ),
 ),
 elevatedButtonTheme: ElevatedButtonThemeData(
 style: ElevatedButton.styleFrom(
 backgroundColor: MedicalSolarColors.medicalBlue,
 foregroundColor: Colors.white,
 elevation: 0,
 padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(12),
 ),
 ),
 ),
 ),
 darkTheme: ThemeData(
 useMaterial3: true,
 brightness: Brightness.dark,
 colorScheme: const ColorScheme.dark(
 // Palette "Medical Solar" Dark - Variantes plus claires
 primary: MedicalSolarColors.medicalBlueDark,
 secondary: MedicalSolarColors.solarGreenDark,
 tertiary: MedicalSolarColors.solarYellowDark,
 surface: MedicalSolarColors.darkSurface,
 onPrimary: Colors.white,
 onSecondary: Colors.white,
 onTertiary: MedicalSolarColors.darkBackground,
 onSurface: Color(0xFFE8E9EA),
 error: Color(0xFFFF6B6B), // Rouge plus clair
 onError: Colors.white,
 ),
 textTheme: GoogleFonts.interTextTheme().copyWith(
 bodyLarge: GoogleFonts.inter().copyWith(
 fontFamily: 'Inter',
 color: const Color(0xFFE8E9EA),
 ),
 ),
 scaffoldBackgroundColor: MedicalSolarColors.darkBackground,
 appBarTheme: const AppBarTheme(
 backgroundColor: MedicalSolarColors.darkBackground,
 foregroundColor: Color(0xFFE8E9EA),
 elevation: 0,
 centerTitle: false,
 titleTextStyle: TextStyle(
 fontSize: 22,
 fontWeight: FontWeight.w600,
 fontFamily: 'Inter',
 color: Color(0xFFE8E9EA),
 ),
 ),
 cardTheme: CardThemeData(
 color: MedicalSolarColors.darkSurface,
 elevation: 0,
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(20),
 side: BorderSide(
 color: MedicalSolarColors.medicalBlueDark.withOpacity(0.2),
 width: 1,
 ),
 ),
 ),
 elevatedButtonTheme: ElevatedButtonThemeData(
 style: ElevatedButton.styleFrom(
 backgroundColor: MedicalSolarColors.medicalBlueDark,
 foregroundColor: Colors.white,
 elevation: 0,
 padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(12),
 ),
 ),
 ),
 ),
 home: const WelcomePage(),
 );
 },
 );
 }
}

class HomePage extends StatefulWidget {
 final ThemeProvider themeProvider;
 final int? initialIndex; // Index de la page à afficher au dmarrage (0=Dashboard, 1=AI, etc.)
 
 const HomePage({super.key, required this.themeProvider, this.initialIndex});

 @override
 State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
 late int _selectedIndex;
 late AnimationController _animationController;
 late Animation<double> _fadeAnimation;

 List<Widget> get _pages => [
 EstablishmentsListPage(themeProvider: widget.themeProvider),
 const AIPredictionPage(),
 const AutoLearningPage(),
 ];

 List<String> get _pageTitles => [
 'Mes Établissements',
 'Prdictions IA',
 'Apprentissage ML',
 ];

 @override
 void initState() {
 super.initState();
 _selectedIndex = widget.initialIndex ?? 0; // Utiliser initialIndex si fourni, sinon 0 (Dashboard)
 _animationController = AnimationController(
 duration: const Duration(milliseconds: 300),
 vsync: this,
 );
 _fadeAnimation = CurvedAnimation(
 parent: _animationController,
 curve: Curves.easeInOut,
 );
 _animationController.forward();
 }

 @override
 void dispose() {
 _animationController.dispose();
 super.dispose();
 }

 void _onItemTapped(int index) {
 if (index != _selectedIndex) {
 // Smooth animation for tab switching
 setState(() {
 _selectedIndex = index;
 _animationController.reset();
 _animationController.forward();
 });
 }
 }

 Color _getBackgroundColor(BuildContext context) {
 return Theme.of(context).brightness == Brightness.dark
 ? MedicalSolarColors.darkSurface
 : MedicalSolarColors.offWhite;
 }

 Color _getTextColor(BuildContext context) {
 return Theme.of(context).brightness == Brightness.dark
 ? const Color(0xFFE8E9EA)
 : MedicalSolarColors.softGrey;
 }

 @override
 Widget build(BuildContext context) {
 final isDark = Theme.of(context).brightness == Brightness.dark;
 
 return Scaffold(
 appBar: AppBar(
 title: Row(
 children: [
 Container(
 width: 40,
 height: 40,
 decoration: BoxDecoration(
 borderRadius: BorderRadius.circular(10),
 gradient: const LinearGradient(
 begin: Alignment.topLeft,
 end: Alignment.bottomRight,
 colors: [
 MedicalSolarColors.medicalBlue,
 MedicalSolarColors.solarGreen,
 ],
 ),
 boxShadow: [
 BoxShadow(
 color: MedicalSolarColors.medicalBlue.withOpacity(0.3),
 blurRadius: 8,
 offset: const Offset(0, 4),
 ),
 ],
 ),
 child: const Icon(
 Icons.wb_sunny_rounded,
 color: Colors.white,
 size: 24,
 ),
 ),
 const SizedBox(width: 12),
 Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'SOLAR MEDICAL',
 style: TextStyle(
 fontSize: 18,
 fontWeight: FontWeight.w700,
 letterSpacing: 1,
 color: _getTextColor(context),
 ),
 ),
 Text(
 _pageTitles[_selectedIndex],
 style: TextStyle(
 fontSize: 12,
 color: isDark 
 ? Colors.white.withOpacity(0.6)
 : MedicalSolarColors.softGrey.withOpacity(0.6),
 fontWeight: FontWeight.normal,
 ),
 ),
 ],
 ),
 ],
 ),
 actions: [
 IconButton(
 icon: Icon(
 isDark ? Icons.light_mode : Icons.dark_mode,
 color: _getTextColor(context),
 ),
 onPressed: () {
 widget.themeProvider.toggleTheme();
 },
 tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
 ),
 ],
 ),
 body: FadeTransition(
 opacity: _fadeAnimation,
 child: AnimatedSwitcher(
 duration: const Duration(milliseconds: 300),
 transitionBuilder: (Widget child, Animation<double> animation) {
 return FadeTransition(
 opacity: animation,
 child: SlideTransition(
 position: Tween<Offset>(
 begin: const Offset(0.02, 0.0),
 end: Offset.zero,
 ).animate(CurvedAnimation(
 parent: animation,
 curve: Curves.easeOutCubic,
 )),
 child: child,
 ),
 );
 },
 child: IndexedStack(
 key: ValueKey<int>(_selectedIndex),
 index: _selectedIndex,
 children: _pages,
 ),
 ),
 ),
 bottomNavigationBar: Container(
 decoration: BoxDecoration(
 color: _getBackgroundColor(context),
 boxShadow: [
 BoxShadow(
 color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
 blurRadius: 10,
 offset: const Offset(0, -2),
 ),
 ],
 ),
 child: BottomNavigationBar(
 backgroundColor: Colors.transparent,
 selectedItemColor: MedicalSolarColors.medicalBlue,
 unselectedItemColor: isDark 
 ? Colors.white.withOpacity(0.5)
 : MedicalSolarColors.softGrey.withOpacity(0.5),
 currentIndex: _selectedIndex,
 onTap: _onItemTapped,
 type: BottomNavigationBarType.fixed,
 elevation: 0,
 selectedLabelStyle: const TextStyle(
 fontWeight: FontWeight.w600,
 fontSize: 12,
 ),
 unselectedLabelStyle: const TextStyle(
 fontWeight: FontWeight.normal,
 fontSize: 12,
 ),
 items: const [
 BottomNavigationBarItem(
 icon: Icon(Icons.dashboard_rounded),
 activeIcon: Icon(Icons.dashboard_rounded),
 label: 'Dashboard',
 ),
 BottomNavigationBarItem(
 icon: Icon(Icons.psychology_outlined),
 activeIcon: Icon(Icons.psychology),
 label: 'AI',
 ),
 BottomNavigationBarItem(
 icon: Icon(Icons.auto_awesome_outlined),
 activeIcon: Icon(Icons.auto_awesome),
 label: 'Learning',
 ),
 ],
 ),
 ),
 );
 }
}

