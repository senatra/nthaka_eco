import 'package:flutter/material.dart';
import 'package:nthaka_eco/app/app_theme.dart';
import 'package:nthaka_eco/app/app_preferences.dart';
import 'package:nthaka_eco/app/memory_lifecycle.dart';
import 'package:nthaka_eco/database/database_helper.dart';
import 'package:nthaka_eco/app/app_entry.dart';
import 'package:nthaka_eco/services/plant_disease_cv_service.dart';
import 'package:nthaka_eco/services/follow_up_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  await AppPreferences.load();
  await FollowUpNotificationService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _memoryObserver = MemoryLifecycleObserver();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_memoryObserver);
    AppPreferences.themeMode.addListener(_onPreferencesChanged);
    AppPreferences.currency.addListener(_onPreferencesChanged);
  }

  void _onPreferencesChanged() => setState(() {});

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_memoryObserver);
    AppPreferences.themeMode.removeListener(_onPreferencesChanged);
    AppPreferences.currency.removeListener(_onPreferencesChanged);
    PlantDiseaseCvService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nthaka.Eco',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: AppPreferences.themeMode.value,
      home: const AppEntry(),
    );
  }
}
