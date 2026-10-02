import 'package:flutter/material.dart';
import 'package:nthaka_eco/app/app_theme.dart';
import 'package:nthaka_eco/database/database_helper.dart';
import 'package:nthaka_eco/screens/authentication/auth_ui.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onContinueAsGuest});

  final Future<void> Function() onContinueAsGuest;

  Future<void> _continueAsGuest() async {
    await DatabaseHelper.instance.continueAsGuest();
    await onContinueAsGuest();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Icon(Icons.eco, size: 72, color: scheme.primary),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                'Nthaka.Eco',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                'Run sales, manage items, and scan crops on this device.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(flex: 3),
              FilledButton(
                onPressed: _continueAsGuest,
                child: const Text('Continue as guest'),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'No account required. Your data stays safely on this device.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),
              const PhoneSignInUnavailableButton(),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                'Powered by Nexa Circuit',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.outline,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
