import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'src/core/network/api_client.dart';
import 'src/core/storage/token_storage.dart';
import 'src/data/repositories/auth_repository.dart';
import 'src/data/repositories/driver_repository.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/driver_provider.dart';
import 'src/providers/theme_provider.dart';
import 'src/screens/splash_screen.dart';
import 'src/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise token storage before anything else.
  await TokenStorage.init();

  // Create shared API client.
  final apiClient = ApiClient();

  // Create repositories.
  final authRepo = AuthRepository(apiClient: apiClient);
  final driverRepo = DriverRepository(apiClient: apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository: authRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => DriverProvider(driverRepository: driverRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: const VamoApp(),
    ),
  );
}

class VamoApp extends StatelessWidget {
  const VamoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Vamo Driver',
      theme: VamoTheme.light(),
      darkTheme: VamoTheme.dark(),
      themeMode: themeProvider.themeMode,
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: SplashScreen(),
      ),
    );
  }
}