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
    final controller = TextEditingController(text: businessName);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Business details'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Business name',
            helperText: 'Shown at the top of shared PDF receipts.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true && controller.text.trim().isNotEmpty) {
      await DatabaseHelper.instance.updateBusinessName(controller.text);
      if (mounted) setState(() => _reload());
    }
    controller.dispose();
  }

  Future<void> _editProfile(DeviceProfile profile) async {
    final firstNameController = TextEditingController(text: profile.firstName);
    final lastNameController = TextEditingController(text: profile.lastName);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Device profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(
                labelText: 'First name',
                helperText: 'Used only to identify this device.',
              ),
            ),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: 'Last name'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      await DatabaseHelper.instance.updateDeviceProfile(
        DeviceProfile(
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          updatedAt: DateTime.now(),
        ),
      );
      if (mounted) setState(() => _reload());
    }

    firstNameController.dispose();
    lastNameController.dispose();
  }

  Future<void> _editSalesSettings() async {
    final footerController = TextEditingController(
      text: AppPreferences.receiptFooter.value,
    );
    var payment = AppPreferences.defaultPaymentMethod.value;
    var feedback = AppPreferences.saleFeedback.value;
    final taxController = TextEditingController(
      text: AppPreferences.taxRate.value.toStringAsFixed(1),
    );
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SingleChildScrollView(
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
                value: payment,
                decoration:
                    const InputDecoration(labelText: 'Default payment method'),
                items: const ['Cash', 'Mobile money', 'Card']
                    .map((value) =>
                        DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                onChanged: (value) => setSheetState(() => payment = value!),
              ),
              const SizedBox(height: AppTheme.spacing12),
              TextField(
                controller: taxController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Default tax rate (%)',
                  helperText: 'Applied to new sales only. Default is 17.5%.',
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              TextField(
                controller: footerController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Receipt footer'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sale confirmation feedback'),
                subtitle:
                    const Text('Play a short sound after each completed sale.'),
                value: feedback,
                onChanged: (value) => setSheetState(() => feedback = value),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save preferences'),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true) {
      final enteredTax = double.tryParse(taxController.text.trim());
      await AppPreferences.saveSalesSettings(
        paymentMethod: payment,
        footer: footerController.text.trim().isEmpty
            ? 'Thank you for your business.'
            : footerController.text.trim(),
        feedback: feedback,
        tax: enteredTax == null || enteredTax < 0 ? 17.5 : enteredTax,
      );
    }
    footerController.dispose();
    taxController.dispose();
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
