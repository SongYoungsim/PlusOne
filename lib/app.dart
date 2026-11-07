import 'package:flutter/material.dart';

import 'screens/main_screen.dart';
import 'theme/app_theme.dart';

class PlusOneApp extends StatelessWidget {
  const PlusOneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlusOne',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const MainScreen(),
    );
  }
}
