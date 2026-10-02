class DiseaseReport {
  final int id;
  final String crop;
  final String disease;
  final double? confidence;
  final String? imagePath;
  final String? boundingBoxJson;
  final DateTime detectedAt;
  final String? notes;
  final String? severity;
  final String? location;
  final DateTime? followUpAt;
  final bool followUpDone;

  DiseaseReport({
    required this.id,
    required this.crop,
    required this.disease,
    this.confidence,
    this.imagePath,
    this.boundingBoxJson,
    required this.detectedAt,
    this.notes,
    this.severity,
    this.location,
    this.followUpAt,
    this.followUpDone = false,
  });

  factory DiseaseReport.fromMap(Map<String, dynamic> map) {
    return DiseaseReport(
      id: map['id'] as int,
      crop: map['crop'] as String,
      disease: map['disease'] as String,
      confidence: map['confidence'] != null
          ? (map['confidence'] as num).toDouble()
          : null,
      imagePath: map['image_path'] as String?,
      boundingBoxJson: map['bounding_box_json'] as String?,
      detectedAt: DateTime.parse(map['detected_at'] as String),
      notes: map['notes'] as String?,
      severity: map['severity'] as String?,
      location: map['location'] as String?,
      followUpAt: map['follow_up_at'] == null
          ? null
          : DateTime.parse(map['follow_up_at'] as String),
      followUpDone: (map['follow_up_done'] as num?)?.toInt() == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'crop': crop,
      'disease': disease,
      'confidence': confidence,
      'image_path': imagePath,
      'bounding_box_json': boundingBoxJson,
      'detected_at': detectedAt.toIso8601String(),
      'notes': notes,
      'severity': severity,
      'location': location,
      'follow_up_at': followUpAt?.toIso8601String(),
      'follow_up_done': followUpDone ? 1 : 0,
    };
  }
}

class DiseaseAnalytics {
  final int totalReports;
  final String mostCommonDisease;
  final String mostCommonCrop;

  DiseaseAnalytics({
    required this.totalReports,
    required this.mostCommonDisease,
    required this.mostCommonCrop,
  });
}
