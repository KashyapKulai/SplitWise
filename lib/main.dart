import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'providers/app_provider.dart';
import 'pages/app_shell.dart';
import 'pages/auth_page.dart';
import 'pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ClearLedgerApp());
}

class ClearLedgerApp extends StatelessWidget {
  const ClearLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          return MaterialApp(
            title: 'ClearLedger',
            debugShowCheckedModeBanner: false,
            themeMode: appProvider.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                // Still loading auth state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SplashPage();
                }
                // User is signed in → show app
                if (snapshot.hasData) {
                  return const AppShell();
                }
                // Not signed in → show auth
                return const AuthPage();
              },
            ),
          );
        },
      ),
    );
  }
}
