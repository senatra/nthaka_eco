import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
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

  final List<DiseaseReport> _history = [];
  int _historyOffset = 0;
  bool _historyHasMore = true;
  bool _loadingHistory = false;

  @override
  void initState() {
    super.initState();
    _loadCrops();
    _loadHistory(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _previewBytes = null;
    ImageProcessingService.clearPreviewCache();
    super.dispose();
  }

  void _onScroll() {
    if (!_historyHasMore || _loadingHistory) {
      return;
    }
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadHistory();
    }
  }

  Future<void> _loadCrops() async {
    final crops = await DatabaseHelper.instance.getCropNames();
    if (!mounted) {
      return;
    }
    setState(() {
      _crops = crops;
      _selectedCrop = crops.isNotEmpty ? crops.first : null;
    });
  }

  Future<void> _loadHistory({bool reset = false}) async {
    if (_loadingHistory) {
      return;
    }
    setState(() => _loadingHistory = true);

    if (reset) {
      _historyOffset = 0;
      _history.clear();
      _historyHasMore = true;
    }

    final page = await DatabaseHelper.instance.getDiseaseReportsPaged(
      limit: _pageSize,
      offset: _historyOffset,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _history.addAll(page.items);
      _historyOffset += page.items.length;
      _historyHasMore = page.hasMore;
      _loadingHistory = false;
    });
  }

  Future<void> _captureAndAnalyze() async {
    if (_selectedCrop == null || _busy) {
      return;
    }

    setState(() {
      _busy = true;
      _result = null;
      _previewBytes = null;
    });

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) {
        return;
      }

      final sourceFile = File(picked.path);
      final preview = await ImageProcessingService.previewBytes(sourceFile);
      final result = await PlantDiseaseCvService.instance.analyzeCapture(
        sourceImage: sourceFile,
        crop: _selectedCrop!,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _previewBytes = preview;
        _result = result;
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _saveResult() async {
    final result = _result;
    if (result == null) {
      return;
    }

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
    await FollowUpNotificationService.schedule(
      reportId: savedReport.id,
      crop: savedReport.crop,
      disease: savedReport.disease,
      dueAt: details.followUpAt,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _result = null;
      _previewBytes = null;
    });
    ImageProcessingService.clearPreviewCache();
    await _loadHistory(reset: true);
  }

  @override
  Widget build(BuildContext context) {
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
            value: _selectedCrop,
            decoration: const InputDecoration(
              labelText: 'Crop',
              helperText: 'Choose the crop shown in the photo before scanning.',
            ),
            items: _crops
                .map(
                  (crop) => DropdownMenuItem<String>(
                    value: crop,
                    child: Text(crop),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedCrop = value),
          ),
          const SizedBox(height: AppTheme.spacing16),
          FilledButton.icon(
            onPressed: _busy ? null : _captureAndAnalyze,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.photo_camera),
            label: Text(_busy ? 'Analyzing…' : 'Take photo'),
          ),
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
              onPressed: _saveResult,
              child: const Text('Save report'),
            ),
          ],
          const SizedBox(height: AppTheme.spacing24),
          Text('History', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacing8),
          if (_history.isEmpty && !_loadingHistory)
            const Text(
                'No scans saved yet. Take a photo, review the result, then save it here.')
          else
            ..._history.map(
              (report) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${report.crop} · ${report.disease}'),
                subtitle: Text(
                  [
                    if (report.severity != null) '${report.severity} severity',
                    if (report.location?.isNotEmpty ?? false) report.location!,
                    if (report.followUpAt != null)
                      'Follow up: ${report.followUpAt!.toLocal().toString().split(' ').first}',
                  ].join(' · '),
                ),
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
              ),
            ),
          if (_loadingHistory)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppTheme.spacing16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
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
            value: _severity,
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
