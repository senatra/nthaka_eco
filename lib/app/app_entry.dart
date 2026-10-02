import 'package:flutter/material.dart';
import 'package:nthaka_eco/database/database_helper.dart';
import 'package:nthaka_eco/global/widgets/main_shell.dart';
import 'package:nthaka_eco/screens/authentication/welcome_screen.dart';

/// Chooses welcome vs main app based on stored guest / welcome state.
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool? _welcomeCompleted;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final done = await DatabaseHelper.instance.isWelcomeCompleted();
    if (!mounted) {
      return;
    }
    setState(() => _welcomeCompleted = done);
  }

  @override
  Widget build(BuildContext context) {
    if (_welcomeCompleted == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_welcomeCompleted!) {
      return const MainShell();
    }
    return WelcomeScreen(
      onContinueAsGuest: () async {
        if (!mounted) return;
        setState(() => _welcomeCompleted = true);
      },
    );
  }
}
