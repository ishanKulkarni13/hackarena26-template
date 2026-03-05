import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/split_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/welcome/welcome_screen.dart';
import 'screens/home/main_nav_screen.dart';
import 'theme/app_theme.dart';

bool _isFirebaseInitialized = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env FIRST so GeminiReceiptService can read GEMINI_API_KEY
  await dotenv.load(fileName: '.env');

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _isFirebaseInitialized = true;
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(SnapBudgetApp(isInitialized: _isFirebaseInitialized));
}

class SnapBudgetApp extends StatelessWidget {
  final bool isInitialized;
  const SnapBudgetApp({super.key, required this.isInitialized});

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: FirebaseConfigMissingScreen(),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => SplitProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'SnapBudget',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme.copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            // Wait for auth to initialize
            if (authProvider.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            // Navigate based on auth state
            return authProvider.isAuthenticated
                ? const MainNavScreen()
                : const WelcomeScreen();
          },
        ),
      ),
    );
  }
}

class FirebaseConfigMissingScreen extends StatelessWidget {
  const FirebaseConfigMissingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 80, color: AppTheme.primaryPurple),
              const SizedBox(height: 32),
              Text(
                'Firebase Not Configured',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'To use the app\'s live features, you must link it to a Firebase project.',
                style:
                    GoogleFonts.inter(fontSize: 15, color: AppTheme.textMedium),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _buildStep(
                '1',
                'Install FlutterFire CLI',
                'dart pub global activate flutterfire_cli',
              ),
              const SizedBox(height: 24),
              _buildStep(
                '2',
                'Configure Project',
                'flutterfire configure',
              ),
              const SizedBox(height: 48),
              Text(
                'After running these commands, restart the app to enable cloud sync.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.textLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String title, String command) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppTheme.primaryPurple,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            command,
            style: GoogleFonts.firaCode(fontSize: 12, color: AppTheme.textDark),
          ),
        ),
      ],
    );
  }
}
