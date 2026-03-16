import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/login_screen.dart';
import 'home/expert_home_screen.dart';
import 'screens/expert_review_details_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/terms_acceptance_screen.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize theme provider to load saved preference
  final themeProvider = AppThemeProvider();
  await themeProvider.init();

  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
    rethrow;
  }

  runApp(
    ChangeNotifierProvider.value(
      value: themeProvider,
      child: const ExpertApp(),
    ),
  );
}

class ExpertApp extends StatelessWidget {
  const ExpertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SEYA Expert',
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/auth': (context) => const AuthCheck(),
            '/home': (context) => const ExpertHomeScreen(),
            '/login': (context) => const LoginScreen(),
            '/terms': (context) => const TermsAcceptanceScreen(),
            '/reviewDetails': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              if (args == null) {
                return const Scaffold(body: Center(child: Text('No review data provided')));
              }
              return ExpertReviewDetailsScreen(review: args);
            },
          },
        );
      },
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ⏳ Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ❌ Not logged in
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // ✅ Logged in - Always show terms screen after login
        final userId = snapshot.data!.uid;
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('experts').doc(userId).get(),
          builder: (context, expertSnap) {
            if (expertSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!expertSnap.hasData || !expertSnap.data!.exists) {
              return const LoginScreen();
            }

            // Check local storage for terms acceptance for this user
            return FutureBuilder<bool>(
              future: _checkLocalTermsAccepted(userId),
              builder: (context, localSnap) {
                if (localSnap.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                final accepted = localSnap.data == true;
                if (!accepted) {
                  return TermsAcceptanceScreen(
                    onAccepted: () => Navigator.pushReplacementNamed(context, '/home'),
                  );
                }
                return const ExpertHomeScreen();
              },
            );
          },
        );
      },
    );
  }
}

// Helper for AuthCheck
Future<bool> _checkLocalTermsAccepted(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('termsAccepted_' + userId) == true;
}
