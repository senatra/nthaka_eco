class DeviceProfile {
  final String? firstName;
  final String? lastName;
  final DateTime? updatedAt;

  DeviceProfile({
    this.firstName,
    this.lastName,
    this.updatedAt,
  });

  factory DeviceProfile.fromMap(Map<String, dynamic> map) {
    return DeviceProfile(
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'first_name': firstName,
      'last_name': lastName,
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  String get displayName {
    final parts = [firstName, lastName]
        .where((part) => part != null && part.trim().isNotEmpty)
        .cast<String>()
        .toList();
    if (parts.isEmpty) {
      return 'Local User';
    }
    return parts.join(' ');
  }
}
