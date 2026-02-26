import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/add_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/ledger_manage_screen.dart';
import 'services/url_handler_service.dart';

class AccountingApp extends StatefulWidget {
  const AccountingApp({super.key});

  @override
  State<AccountingApp> createState() => _AccountingAppState();
}

class _AccountingAppState extends State<AccountingApp> {
  @override
  void initState() {
    super.initState();
    // 初始化 URL Scheme 监听
    UrlHandlerService.initUrlListener(context);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '自动记账',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/add': (context) => const AddScreen(),
        '/stats': (context) => const StatsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/ledgers': (context) => const LedgerManageScreen(),
      },
    );
  }
}
