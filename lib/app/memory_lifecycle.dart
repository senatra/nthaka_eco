import 'package:flutter/widgets.dart';
import 'package:nthaka_eco/services/image_processing_service.dart';
import 'package:nthaka_eco/services/plant_disease_cv_service.dart';

/// Drops CV + preview bitmap caches when the app is backgrounded.
class MemoryLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        PlantDiseaseCvService.instance.releaseModel();
        ImageProcessingService.clearPreviewCache();
      case AppLifecycleState.resumed:
      case AppLifecycleState.inactive:
        break;
    }
  }
}
