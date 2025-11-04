import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/auth_provider.dart';
import 'providers/sales_provider.dart';
import 'providers/services_provider.dart';
import 'providers/expenses_provider.dart';
import 'providers/customers_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'utils/responsive.dart'; // ← ARQUIVO NOVO
import 'screens/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hbrgkczyddmphadzpqsk.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhicmdrY3p5ZGRtcGhhZHpwcXNrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEyODExMzIsImV4cCI6MjA3Njg1NzEzMn0.3XofGOjXjI3VeWKO_JpNfdnfObbP0wntkpcIWNgfcRY',
  );

  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDark') ?? false;

  runApp(MyApp(isDark: isDark));
}

class MyApp extends StatelessWidget {
  final bool isDark;
  const MyApp({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
        ChangeNotifierProvider(create: (_) => ServicesProvider()),
        ChangeNotifierProvider(create: (_) => ExpensesProvider()),
        ChangeNotifierProvider(create: (_) => CustomersProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..setInitialTheme(isDark)),
      ],
      child: const AppView(),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) => MaterialApp(
        title: 'NextLynx Print',
        debugShowCheckedModeBanner: false,
        theme: themeProvider.lightTheme,
        darkTheme: themeProvider.darkTheme,
        themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
        home: const ResponsiveHome(), // ← RESPONSIVO AQUI
        builder: (context, child) {
          // GARANTE TEXTO ESCALÁVEL
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: MediaQuery.of(context).size.width > 600 ? 1.2 : 1.0,
            ),
            child: child!,
          );
        },
      ),
    );
  }
}

// TELA INICIAL RESPONSIVA
class ResponsiveHome extends StatelessWidget {
  const ResponsiveHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return auth.user == null ? const LoginScreen() : const ResponsiveDashboard();
      },
    );
  }
}

// DASHBOARD RESPONSIVO (EXEMPLO)
class ResponsiveDashboard extends StatelessWidget {
  const ResponsiveDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Responsive(
      mobile: const DashboardScreen(),     // ← SUA TELA EXISTENTE
      tablet: const DashboardScreen(),     // ← MESMA TELA
      desktop: const DashboardScreen(),    // ← MESMA TELA
    );
  }
}