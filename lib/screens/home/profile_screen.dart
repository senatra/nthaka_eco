import 'package:flutter/material.dart';
import 'package:nthaka_eco/app/app_theme.dart';
import 'package:nthaka_eco/app/app_preferences.dart';
import 'package:nthaka_eco/database/database_helper.dart';
import 'package:nthaka_eco/models/device_profile.dart';
import 'package:nthaka_eco/models/disease_report.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<DeviceProfile> _profileFuture;
  late Future<DiseaseAnalytics> _analyticsFuture;
  late Future<String> _businessNameFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _profileFuture = DatabaseHelper.instance.getDeviceProfile();
    _analyticsFuture = DatabaseHelper.instance.getDiseaseAnalytics();
    _businessNameFuture = DatabaseHelper.instance.getBusinessName();
  }

  Future<void> _editBusinessName(String businessName) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _BusinessNameDialog(initial: businessName),
    );
    if (name != null && name.isNotEmpty) {
      await DatabaseHelper.instance.updateBusinessName(name);
      if (mounted) setState(() => _reload());
    }
  }

  Future<void> _editProfile(DeviceProfile profile) async {
    final result = await showDialog<_ProfileResult>(
      context: context,
      builder: (_) => _DeviceProfileDialog(profile: profile),
    );
    if (result != null) {
      await DatabaseHelper.instance.updateDeviceProfile(
        DeviceProfile(
          firstName: result.firstName,
          lastName: result.lastName,
          updatedAt: DateTime.now(),
        ),
      );
      if (mounted) setState(() => _reload());
    }
  }

  Future<void> _editSalesSettings() async {
    final result = await showModalBottomSheet<_SalesSettingsResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _SalesSettingsSheet(),
    );
    if (result != null) {
      final tax = result.tax;
      await AppPreferences.saveSalesSettings(
        paymentMethod: result.payment,
        footer: result.footer.isEmpty
            ? 'Thank you for your business.'
            : result.footer,
        feedback: result.feedback,
        tax: tax == null || tax < 0 ? 17.5 : tax,
      );
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Edit device profile',
            onPressed: () async {
              final profile = await _profileFuture;
              if (mounted) {
                await _editProfile(profile);
              }
            },
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        children: [
          FutureBuilder<String>(
            future: _businessNameFuture,
            builder: (context, snapshot) => ListTile(
              leading:
                  const CircleAvatar(child: Icon(Icons.storefront_outlined)),
              title: Text(snapshot.data ?? 'Your business name'),
              subtitle: const Text('Business name on shared receipts'),
              trailing: const Icon(Icons.chevron_right),
              onTap: snapshot.hasData
                  ? () => _editBusinessName(snapshot.data!)
                  : null,
            ),
          ),
          const Divider(),
          Text('App settings', style: Theme.of(context).textTheme.titleMedium),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppPreferences.themeMode,
            builder: (context, mode, _) => ListTile(
              leading: const Icon(Icons.brightness_6_outlined),
              title: const Text('Appearance'),
              subtitle: Text(
                  mode.name == 'system' ? 'Use device setting' : mode.name),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: ThemeMode.values
                      .map((value) => ListTile(
                            title: Text(value.name[0].toUpperCase() +
                                value.name.substring(1)),
                            trailing:
                                value == mode ? const Icon(Icons.check) : null,
                            onTap: () async {
                              await AppPreferences.setThemeMode(value);
                              if (context.mounted) Navigator.pop(context);
                            },
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
          ValueListenableBuilder<String>(
            valueListenable: AppPreferences.currency,
            builder: (context, currency, _) => ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Currency'),
              subtitle: Text(currency),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: ['MWK', 'USD', 'ZAR']
                      .map((value) => ListTile(
                            title: Text(value),
                            trailing: value == currency
                                ? const Icon(Icons.check)
                                : null,
                            onTap: () async {
                              await AppPreferences.setCurrency(value);
                              if (context.mounted) Navigator.pop(context);
                            },
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Sales preferences'),
            subtitle: const Text(
                'Tax, receipt footer, payment default, and feedback'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _editSalesSettings,
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.shield_outlined),
            title: Text('Your data stays on this device'),
            subtitle: Text(
              'Sales, inventory, crop scans, and settings are stored locally. '
              'They are only shared when you choose to export a file.',
            ),
          ),
          const Divider(),
          FutureBuilder<DeviceProfile>(
            future: _profileFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const LinearProgressIndicator();
              }
              final profile = snapshot.data!;
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(profile.displayName),
                subtitle: const Text('Stored on this device only'),
              );
            },
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text('Scan insights', style: Theme.of(context).textTheme.titleMedium),
          FutureBuilder<DiseaseAnalytics>(
            future: _analyticsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }
              final analytics = snapshot.data!;
              return Column(
                children: [
                  ListTile(
                    title: const Text('Total reports'),
                    trailing: Text('${analytics.totalReports}'),
                  ),
                  ListTile(
                    title: const Text('Most common disease'),
                    trailing: Text(analytics.mostCommonDisease),
                  ),
                  ListTile(
                    title: const Text('Most common crop'),
                    trailing: Text(analytics.mostCommonCrop),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppTheme.spacing24),
          Text(
            'Powered by Nexa Circuit',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _BusinessNameDialog extends StatefulWidget {
  const _BusinessNameDialog({required this.initial});

  final String initial;

  @override
  State<_BusinessNameDialog> createState() => _BusinessNameDialogState();
}

class _BusinessNameDialogState extends State<_BusinessNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Business details'),
      content: TextField(
        controller: _controller,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Business name',
          helperText: 'Shown at the top of shared PDF receipts.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ProfileResult {
  const _ProfileResult(this.firstName, this.lastName);

  final String firstName;
  final String lastName;
}

class _DeviceProfileDialog extends StatefulWidget {
  const _DeviceProfileDialog({required this.profile});

  final DeviceProfile profile;

  @override
  State<_DeviceProfileDialog> createState() => _DeviceProfileDialogState();
}

class _DeviceProfileDialogState extends State<_DeviceProfileDialog> {
  late final TextEditingController _first =
      TextEditingController(text: widget.profile.firstName);
  late final TextEditingController _last =
      TextEditingController(text: widget.profile.lastName);

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Device profile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _first,
            decoration: const InputDecoration(
              labelText: 'First name',
              helperText: 'Used only to identify this device.',
            ),
          ),
          TextField(
            controller: _last,
            decoration: const InputDecoration(labelText: 'Last name'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _ProfileResult(_first.text.trim(), _last.text.trim()),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _SalesSettingsResult {
  const _SalesSettingsResult({
    required this.payment,
    required this.footer,
    required this.tax,
    required this.feedback,
  });

  final String payment;
  final String footer;
  final double? tax;
  final bool feedback;
}

class _SalesSettingsSheet extends StatefulWidget {
  const _SalesSettingsSheet();

  @override
  State<_SalesSettingsSheet> createState() => _SalesSettingsSheetState();
}

class _SalesSettingsSheetState extends State<_SalesSettingsSheet> {
  late final TextEditingController _footer =
      TextEditingController(text: AppPreferences.receiptFooter.value);
  late final TextEditingController _tax = TextEditingController(
      text: AppPreferences.taxRate.value.toStringAsFixed(1));
  late String _payment = AppPreferences.defaultPaymentMethod.value;
  late bool _feedback = AppPreferences.saleFeedback.value;

  @override
  void dispose() {
    _footer.dispose();
    _tax.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spacing16,
        AppTheme.spacing8,
        AppTheme.spacing16,
        MediaQuery.viewInsetsOf(context).bottom + AppTheme.spacing16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Sales preferences',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppTheme.spacing12),
          DropdownButtonFormField<String>(
            initialValue: _payment,
            decoration:
                const InputDecoration(labelText: 'Default payment method'),
            items: const ['Cash', 'Mobile money', 'Card']
                .map((value) =>
                    DropdownMenuItem(value: value, child: Text(value)))
                .toList(),
            onChanged: (value) => setState(() => _payment = value!),
          ),
          const SizedBox(height: AppTheme.spacing12),
          TextField(
            controller: _tax,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Default tax rate (%)',
              helperText: 'Applied to new sales only. Default is 17.5%.',
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          TextField(
            controller: _footer,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Receipt footer'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Sale confirmation feedback'),
            subtitle:
                const Text('Play a short sound after each completed sale.'),
            value: _feedback,
            onChanged: (value) => setState(() => _feedback = value),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              _SalesSettingsResult(
                payment: _payment,
                footer: _footer.text.trim(),
                tax: double.tryParse(_tax.text.trim()),
                feedback: _feedback,
              ),
            ),
            child: const Text('Save preferences'),
          ),
        ],
      ),
    );
  }
}
