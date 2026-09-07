import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'src/core/network/api_client.dart';
import 'src/core/storage/token_storage.dart';
import 'src/data/repositories/auth_repository.dart';
import 'src/data/repositories/corridor_repository.dart';
import 'src/data/repositories/subscription_admin_repository.dart';
import 'src/data/repositories/notification_repository.dart';
import 'src/data/repositories/driver_admin_repository.dart';
import 'src/data/repositories/fare_config_repository.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/corridor_provider.dart';
import 'src/providers/notifications_providor.dart';
import 'src/providers/subscription_admin_provider.dart';
import 'src/providers/theme_provider.dart';
import 'src/providers/driver_admin_provider.dart';
import 'src/providers/fare_config_provider.dart';
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
  final corridorRepo = CorridorRepository(apiClient: apiClient);
  final notificationRepo = NotificationRepository(apiClient: apiClient);
  final subAdminRepo = SubscriptionAdminRepository(apiClient: apiClient);
  final driverAdminRepo = DriverAdminRepository(apiClient: apiClient);
  final fareConfigRepo = FareConfigRepository(apiClient: apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository: authRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => CorridorProvider(corridorRepository: corridorRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(notificationRepository: notificationRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => SubscriptionAdminProvider(repository: subAdminRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => DriverAdminProvider(repository: driverAdminRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => FareConfigProvider(repository: fareConfigRepo),
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
      title: 'Vamo',
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
