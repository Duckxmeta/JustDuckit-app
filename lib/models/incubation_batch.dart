class IncubationBatch {
  final String id;
  final String batchName;
  final String breedTemplateId;
  final DateTime startDate;
  final DateTime projectedHatchDate;
  final DateTime lockdownDate;
  final String uid;

  IncubationBatch({
    required this.id,
    required this.batchName,
    required this.breedTemplateId,
    required this.startDate,
    required this.projectedHatchDate,
    required this.lockdownDate,
    required this.uid,
  });

  factory IncubationBatch.fromMap(Map<String, dynamic> data) {
    DateTime parseDateTime(dynamic value) {
      if (value != null) {
        try {
          return DateTime.parse(value as String);
        } catch (_) {}
      }
      return DateTime.now();
    }

    return IncubationBatch(
      id: data['id']?.toString() ?? '',
      batchName: data['batch_name'] as String? ?? '',
      breedTemplateId: data['breed_template_id'] as String? ?? '',
      startDate: parseDateTime(data['start_date']),
      projectedHatchDate: parseDateTime(data['projected_hatch_date']),
      lockdownDate: parseDateTime(data['lockdown_date']),
      uid: data['uid'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batch_name': batchName,
      'breed_template_id': breedTemplateId,
      'start_date': startDate.toIso8601String(),
      'projected_hatch_date': projectedHatchDate.toIso8601String(),
      'lockdown_date': lockdownDate.toIso8601String(),
      'uid': uid,
    };
  }

  IncubationBatch copyWith({
    String? id,
    String? batchName,
    String? breedTemplateId,
    DateTime? startDate,
    DateTime? projectedHatchDate,
    DateTime? lockdownDate,
    String? uid,
  }) {
    return IncubationBatch(
      id: id ?? this.id,
      batchName: batchName ?? this.batchName,
      breedTemplateId: breedTemplateId ?? this.breedTemplateId,
      startDate: startDate ?? this.startDate,
      projectedHatchDate: projectedHatchDate ?? this.projectedHatchDate,
      lockdownDate: lockdownDate ?? this.lockdownDate,
      uid: uid ?? this.uid,
    );
  }
}
