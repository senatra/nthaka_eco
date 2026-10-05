import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nthaka_eco/app/app_theme.dart';
import 'package:nthaka_eco/database/database_helper.dart';
import 'package:nthaka_eco/models/disease_report.dart';
import 'package:nthaka_eco/services/image_processing_service.dart';
import 'package:nthaka_eco/services/plant_disease_cv_service.dart';
import 'package:nthaka_eco/services/follow_up_notification_service.dart';

typedef ScanDetails = ({
  String location,
  String notes,
  String severity,
  DateTime followUpAt
});

class PlantScanScreen extends StatefulWidget {
  const PlantScanScreen({super.key});

  @override
  State<PlantScanScreen> createState() => _PlantScanScreenState();
}

class _PlantScanScreenState extends State<PlantScanScreen> {
  static const _pageSize = 20;

  final _picker = ImagePicker();
  final _scrollController = ScrollController();

  List<String> _crops = [];
  String? _selectedCrop;
  CvInferenceResult? _result;
  Uint8List? _previewBytes;
  bool _busy = false;
  bool _saving = false;

  final List<DiseaseReport> _history = [];
  int _historyOffset = 0;
  int _historyGeneration = 0;
  bool _historyHasMore = true;
  bool _loadingHistory = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadHistory(reset: true);
    _init();
  }

  Future<void> _init() async {
    await _loadCrops();
    await _recoverLostData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    ImageProcessingService.clearPreviewCache();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onScroll() {
    if (!_historyHasMore || _loadingHistory || !_scrollController.hasClients) {
      return;
    }
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadHistory();
    }
  }

  Future<void> _loadCrops() async {
    try {
      final crops = await DatabaseHelper.instance.getCropNames();
      if (!mounted) return;
      setState(() {
        _crops = crops;
        _selectedCrop = crops.isNotEmpty ? crops.first : null;
      });
    } catch (_) {
      _toast('Could not load the crop list.');
    }
  }

  /// Loads a page of history. A reset always runs (and wins over any load that
  /// is still in flight); a normal "load more" is skipped while one is running.
  Future<void> _loadHistory({bool reset = false}) async {
    if (reset) {
      _historyGeneration++;
      _historyOffset = 0;
      _historyHasMore = true;
    } else if (_loadingHistory || !_historyHasMore) {
      return;
    }

    final generation = _historyGeneration;
    final offset = _historyOffset;
    setState(() => _loadingHistory = true);

    try {
      final page = await DatabaseHelper.instance.getDiseaseReportsPaged(
        limit: _pageSize,
        offset: offset,
      );
      if (!mounted || generation != _historyGeneration) return;
      setState(() {
        if (reset) _history.clear();
        _history.addAll(page.items);
        _historyOffset = offset + page.items.length;
        _historyHasMore = page.hasMore;
      });
    } catch (_) {
      if (mounted && generation == _historyGeneration) {
        _toast('Could not load scan history.');
      }
    } finally {
      if (mounted && generation == _historyGeneration) {
        setState(() => _loadingHistory = false);
      }
    }
  }

  /// On low-memory Android phones the system can kill this screen while the
  /// camera is open. This restores the photo that was just taken.
  Future<void> _recoverLostData() async {
    if (!Platform.isAndroid) return;
    try {
      final response = await _picker.retrieveLostData();
      final lost = response.file;
      final crop = _selectedCrop;
      if (response.isEmpty || lost == null || crop == null || !mounted) return;

      setState(() => _busy = true);
      try {
        await _analyze(File(lost.path), crop);
        _toast('Restored your last photo. Check the crop is correct.');
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    } catch (_) {
      // Nothing to recover, or recovery failed. Safe to ignore.
    }
  }

  Future<void> _scan(ImageSource source) async {
    final crop = _selectedCrop;
    if (crop == null || _busy || _saving) return;

    setState(() => _busy = true);
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return; // User cancelled: keep any previous result.
      await _analyze(File(picked.path), crop);
    } catch (e) {
      _toast(_scanErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _analyze(File sourceFile, String crop) async {
    if (mounted) {
      setState(() {
        _result = null;
        _previewBytes = null;
      });
    }
    final preview = await ImageProcessingService.previewBytes(sourceFile);
    final result = await PlantDiseaseCvService.instance.analyzeCapture(
      sourceImage: sourceFile,
      crop: crop,
    );
    if (!mounted) return;
    setState(() {
      _previewBytes = preview;
      _result = result;
    });
  }

  Future<void> _saveResult() async {
    final result = _result;
    if (result == null || _saving || _busy) return;

    setState(() => _saving = true);
    try {
      final details = await showModalBottomSheet<ScanDetails>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const _SaveScanSheet(),
      );
      if (details == null || !mounted) return;

      final savedReport = await DatabaseHelper.instance.createDiseaseReport(
        DiseaseReport(
          id: 0,
          crop: result.crop,
          disease: result.disease,
          confidence: result.confidence,
          imagePath: result.processedImagePath,
          detectedAt: DateTime.now(),
          location: details.location.isEmpty ? null : details.location,
          notes: details.notes.isEmpty ? null : details.notes,
          severity: details.severity,
          followUpAt: details.followUpAt,
        ),
      );

      // The report is already saved. A reminder failure (for example,
      // notification permission off) must not look like a failed save.
      var reminderFailed = false;
      try {
        await FollowUpNotificationService.schedule(
          reportId: savedReport.id,
          crop: savedReport.crop,
          disease: savedReport.disease,
          dueAt: details.followUpAt,
        );
      } catch (_) {
        reminderFailed = true;
      }

      if (!mounted) return;
      setState(() {
        _result = null;
        _previewBytes = null;
      });
      ImageProcessingService.clearPreviewCache();
      _toast(reminderFailed
          ? 'Report saved, but the reminder could not be scheduled.'
          : 'Report saved.');
      await _loadHistory(reset: true);
    } catch (_) {
      _toast('Could not save the report. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canScan = _selectedCrop != null && !_busy && !_saving;

    return Scaffold(
      appBar: AppBar(title: const Text('Plant scan')),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppTheme.spacing16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'For a clearer scan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  const Text(
                    'Use good light, keep one affected leaf in focus, and avoid a blurry or distant photo.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          DropdownButtonFormField<String>(
            initialValue: _selectedCrop,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Crop',
              helperText: _crops.isEmpty
                  ? 'No crops available yet.'
                  : 'Choose the crop shown in the photo before scanning.',
            ),
            items: _crops
                .map(
                  (crop) => DropdownMenuItem<String>(
                    value: crop,
                    child: Text(crop),
                  ),
                )
                .toList(),
            onChanged: _busy ? null : (v) => setState(() => _selectedCrop = v),
          ),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: canScan ? () => _scan(ImageSource.camera) : null,
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Take photo'),
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canScan ? () => _scan(ImageSource.gallery) : null,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          if (_busy) ...[
            const SizedBox(height: AppTheme.spacing12),
            const LinearProgressIndicator(),
            const SizedBox(height: AppTheme.spacing8),
            const Text('Analyzing…', textAlign: TextAlign.center),
          ],
          if (_previewBytes != null && _result != null) ...[
            const SizedBox(height: AppTheme.spacing16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                _previewBytes!,
                fit: BoxFit.cover,
                height: 180,
                width: double.infinity,
                gaplessPlayback: true,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              '${_result!.crop} · ${_result!.disease}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacing12),
            FilledButton(
              onPressed: (_saving || _busy) ? null : _saveResult,
              child: Text(_saving ? 'Saving…' : 'Save report'),
            ),
          ],
          const SizedBox(height: AppTheme.spacing24),
          Text('History', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacing8),
          if (_history.isEmpty && !_loadingHistory)
            const Text(
                'No scans saved yet. Take a photo or choose one from your gallery, review the result, then save it here.')
          else
            ..._history.map(_buildHistoryTile),
          if (_loadingHistory)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppTheme.spacing16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(DiseaseReport report) {
    final parts = [
      if (report.severity != null) '${report.severity} severity',
      if (report.location?.isNotEmpty ?? false) report.location!,
      if (report.followUpAt != null)
        'Follow up: ${report.followUpAt!.toLocal().toString().split(' ').first}',
    ];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('${report.crop} · ${report.disease}'),
      subtitle: parts.isEmpty ? null : Text(parts.join(' · ')),
      trailing: report.imagePath == null
          ? null
          : SizedBox(
              width: 48,
              height: 48,
              child: Image.file(
                File(report.imagePath!),
                fit: BoxFit.cover,
                cacheWidth: 96,
                cacheHeight: 96,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image_outlined),
              ),
            ),
    );
  }
}

String _scanErrorMessage(Object error) {
  if (error is PlatformException) {
    switch (error.code) {
      case 'camera_access_denied':
        return 'Camera permission is off. Turn it on in Settings, or choose a photo from your gallery.';
      case 'photo_access_denied':
        return 'Photo access is off. Turn it on in Settings.';
    }
  }
  return 'Could not analyze that photo. Please try another one.';
}

/// Owns and disposes its own controllers, so they are only disposed after the
/// sheet route has been fully removed from the tree.
class _SaveScanSheet extends StatefulWidget {
  const _SaveScanSheet();

  @override
  State<_SaveScanSheet> createState() => _SaveScanSheetState();
}

class _SaveScanSheetState extends State<_SaveScanSheet> {
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  String _severity = 'Moderate';
  DateTime _followUpAt = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _followUpAt,
    );
    if (picked != null && mounted) {
      setState(() => _followUpAt = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final date =
        '${_followUpAt.year}-${_followUpAt.month.toString().padLeft(2, '0')}-${_followUpAt.day.toString().padLeft(2, '0')}';

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
          Text('Save scan and follow-up',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppTheme.spacing12),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Field or location',
              helperText: 'Optional: where you found this plant.',
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          DropdownButtonFormField<String>(
            initialValue: _severity,
            decoration: const InputDecoration(labelText: 'Severity'),
            items: const ['Low', 'Moderate', 'High']
                .map((value) =>
                    DropdownMenuItem(value: value, child: Text(value)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _severity = value);
            },
          ),
          const SizedBox(height: AppTheme.spacing12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Follow-up reminder'),
            subtitle: Text(date),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: _pickDate,
          ),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes',
              helperText: 'Optional treatment or observation notes.',
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          FilledButton(
            onPressed: () => Navigator.pop<ScanDetails>(context, (
              location: _locationController.text.trim(),
              notes: _notesController.text.trim(),
              severity: _severity,
              followUpAt: _followUpAt,
            )),
            child: const Text('Save scan'),
          ),
        ],
      ),
    );
  }
}
