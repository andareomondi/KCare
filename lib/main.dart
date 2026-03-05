import 'package:flutter/material.dart';
import 'package:kcare/services/internet_connection/connectivity_service.dart';
import 'package:kcare/services/router/router.dart';
import 'package:kcare/themes/theme_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  await connectivityService.initialize();
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'KCare',
      routerConfig: router,
      theme: Provider.of<ThemeProvider>(context).themeMode,
    );
  }
}
