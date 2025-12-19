import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/records_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Conditional import for web database initialization (legacy sqflite fallback)
import 'database_init_stub.dart'
    if (dart.library.html) 'database_init_web.dart' as db_init;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (required for Firestore)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Legacy web init (not used with Firestore, but kept to avoid crashes)
  if (kIsWeb) {
    await db_init.initDatabase();
  }
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFFDF6F9),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..initialize(),
      child: MaterialApp(
        title: 'Container Beverages',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE891B0),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFFDF6F9),
          fontFamily: 'Roboto',
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return _buildSplashScreen();
        }

        if (provider.error != null) {
          return _buildErrorScreen(provider);
        }

        final screens = [
          HomeScreen(
            onScanTap: () => setState(() => _currentIndex = 1),
            onAnalyticsTap: () => setState(() => _currentIndex = 2),
            onRecordsTap: () => setState(() => _currentIndex = 3),
          ),
          const CameraScreen(),
          const AnalyticsScreen(),
          const RecordsScreen(),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: _buildBottomNavBar(),
        );
      },
    );
  }

  Widget _buildSplashScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F9),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Logo
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFE891B0), Color(0xFFD4A5FF)],
                        ),
                        borderRadius: BorderRadius.circular(36),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE891B0).withOpacity(0.4),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_drink_rounded,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: const Column(
                      children: [
                        Text(
                          'Container',
                          style: TextStyle(
                            color: Color(0xFF2D2D3A),
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          'BEVERAGES',
                          style: TextStyle(
                            color: Color(0xFFE891B0),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 50),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          valueColor: const AlwaysStoppedAnimation(Color(0xFFE891B0)),
                          strokeWidth: 3,
                          backgroundColor: const Color(0xFFE891B0).withOpacity(0.2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Loading AI Model...',
                        style: TextStyle(
                          color: const Color(0xFF2D2D3A).withOpacity(0.5),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(AppProvider provider) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F9),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 56,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  color: Color(0xFF2D2D3A),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF2D2D3A).withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 36),
              ElevatedButton.icon(
                onPressed: () => provider.initialize(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  'Try Again',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE891B0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                color: const Color(0xFFE891B0),
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.document_scanner_outlined,
                activeIcon: Icons.document_scanner_rounded,
                label: 'Scan',
                color: const Color(0xFFD4A5FF),
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.insights_outlined,
                activeIcon: Icons.insights_rounded,
                label: 'Analytics',
                color: const Color(0xFFFFB5BA),
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.history_outlined,
                activeIcon: Icons.history_rounded,
                label: 'Records',
                color: const Color(0xFF7DD3C0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color color,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? color : const Color(0xFF9CA3AF),
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
