import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'injection_container.dart' as di;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const SadaqoApp());
}

class SadaqoApp extends StatelessWidget {
  const SadaqoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SADAQO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashPage(),
    );
  }
}
