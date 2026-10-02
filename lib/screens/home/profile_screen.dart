import 'package:flutter/material.dart';
import 'package:nthaka_eco/app/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _profileFuture = DatabaseHelper.instance.getDeviceProfile();
    _analyticsFuture = DatabaseHelper.instance.getDiseaseAnalytics();
  }

  Future<void> _editProfile(DeviceProfile profile) async {
    final firstNameController = TextEditingController(text: profile.firstName);
    final lastNameController = TextEditingController(text: profile.lastName);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(labelText: 'First name'),
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
      setState(_reload);
    }

    firstNameController.dispose();
    lastNameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
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
        ],
      ),
    );
  }
}
