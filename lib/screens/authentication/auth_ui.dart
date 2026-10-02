import 'package:flutter/material.dart';
import 'package:nthaka_eco/app/app_theme.dart';

/// Phone + OTP sign-in is planned; show this until it ships.
void showPhoneSignInComingSoon(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(
        Icons.phonelink_lock_outlined,
        size: 36,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('Phone sign-in is being worked on'),
      content: const Text(
        'Registration and sign-in using a phone number and one-time code '
        'are still in development. You can continue as a guest for now; '
        'your data stays on this device.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Disabled-style control that explains phone registration is not available yet.
class PhoneSignInUnavailableButton extends StatelessWidget {
  const PhoneSignInUnavailableButton({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (compact) {
      return ListTile(
        leading: const Icon(Icons.phone_android_outlined),
        title: const Text('Phone + OTP registration'),
        subtitle: const Text('Being worked on'),
        trailing: const Icon(Icons.lock_outline),
        onTap: () => showPhoneSignInComingSoon(context),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () => showPhoneSignInComingSoon(context),
          icon: const Icon(Icons.phone_outlined),
          label: const Text('Phone + OTP registration'),
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          'Being worked on · optional when available',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
