import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'core/database/database_helper.dart';
import 'presentation/providers/console_provider.dart';
import 'presentation/providers/transaction_provider.dart';
import 'presentation/providers/member_snack_provider.dart';
import 'presentation/providers/overtime_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'data/repositories/transaction_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init locale untuk intl (wajib untuk DateFormat dengan locale id_ID)
  await initializeDateFormatting('id_ID', null);

  // Lock portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0F172A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Init database
  await DatabaseHelper.instance.database;

  // Fix bug: sinkronkan transaksi aktif yang konsolnya sudah available
  await TransactionRepository().syncOrphanSessions();

  runApp(const GamingZoneApp());
}

class GamingZoneApp extends StatelessWidget {
  const GamingZoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ConsoleProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => MemberProvider()),
        ChangeNotifierProvider(create: (_) => SnackProvider()),
        ChangeNotifierProvider(create: (_) => OvertimeProvider()),
      ],
      child: MaterialApp(
        title: 'Gaming Zone',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
