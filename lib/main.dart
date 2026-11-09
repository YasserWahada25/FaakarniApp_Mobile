import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/config/api_config.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await ApiConfig.load();
  await AuthProvider.instance.restore();
  runApp(const FakarniApp());
}

class FakarniApp extends StatelessWidget {
  const FakarniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}
