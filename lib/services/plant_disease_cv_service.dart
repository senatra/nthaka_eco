import 'dart:io';

import 'package:flutter/services.dart';
import 'package:nthaka_eco/services/image_processing_service.dart';

class CvInferenceResult {
  final String crop;
  final String disease;
  final double confidence;
  final String processedImagePath;

  const CvInferenceResult({
    required this.crop,
    required this.disease,
    required this.confidence,
    required this.processedImagePath,
  });
}

/// On-device CV entry point. Loads labels only; TFLite model can be wired later.
/// Interpreter memory is released when [releaseModel] / [dispose] is called.
class PlantDiseaseCvService {
  PlantDiseaseCvService._();

  static final PlantDiseaseCvService instance = PlantDiseaseCvService._();

  bool _labelsLoaded = false;
  final Map<String, List<String>> _labelsByCrop = {};

  Future<void> ensureReady(String crop) async {
    if (_labelsLoaded && _labelsByCrop.containsKey(crop)) {
      return;
    }
    final assetPath = 'assets/model/${crop}labels.txt';
    final raw = await rootBundle.loadString(assetPath);
    _labelsByCrop[crop] = raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    _labelsLoaded = true;
  }

  void releaseModel() {
    _labelsLoaded = false;
    _labelsByCrop.clear();
    ImageProcessingService.clearPreviewCache();
  }

  void dispose() {
    releaseModel();
  }

  Future<CvInferenceResult> analyzeCapture({
    required File sourceImage,
    required String crop,
  }) async {
    await ensureReady(crop);
    final processed =
        await ImageProcessingService.prepareForInference(sourceImage);

    final labels = _labelsByCrop[crop] ?? const ['Unknown'];
    final disease = labels.first;

    return CvInferenceResult(
      crop: crop,
      disease: disease,
      confidence: 0.0,
      processedImagePath: processed.path,
    );
  }
}
