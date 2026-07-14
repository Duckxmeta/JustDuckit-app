class Bird {
  final String id;
  final String name;
  final String breed;
  final String category; // e.g. 'Avian', 'Pets', 'Livestock', 'Aquatic'
  final DateTime ageOrHatchDate;
  final String sex;
  final String originType;
  final String? sireId;
  final String? damId;
  final String? photoUrl;
  final String uid; // backward compatibility key
  final String ownerId; // premium naming convention key

  // Collectible Gamified Features
  final String serialNumber;
  final double flockGrade;
  final List<String> geneticTraits;
  final String cardVariant; // 'Standard', 'Holo', 'Full-Art'
  final int level;
  final int xp;
  final String discoveryType; // 'Resident' or 'Encounter'

  // AI Appraisal Metrics
  final int? hardiness;
  final int? eggProduction;
  final String? rarityTier;
  final String? gradeNotes;

  Bird({
    required this.id,
    required this.name,
    required this.breed,
    this.category = 'Avian',
    required this.ageOrHatchDate,
    required this.sex,
    required this.originType,
    this.sireId,
    this.damId,
    this.photoUrl,
    required this.uid,
    required this.ownerId,
    this.serialNumber = 'N/A',
    this.flockGrade = 8.5,
    this.geneticTraits = const [],
    this.cardVariant = 'Standard',
    this.level = 1,
    this.xp = 0,
    this.discoveryType = 'Resident',
    this.hardiness,
    this.eggProduction,
    this.rarityTier,
    this.gradeNotes,
  });

  factory Bird.fromMap(Map<String, dynamic> data) {
    final String resolvedOwnerId = data['user_id'] as String? ?? data['owner_id'] as String? ?? data['uid'] as String? ?? '';
    final String parsedBreed = data['breed'] as String? ?? '';
    
    DateTime parsedDate;
    if (data['age_or_hatch_date'] != null) {
      try {
        parsedDate = DateTime.parse(data['age_or_hatch_date'] as String);
      } catch (_) {
        parsedDate = DateTime.now();
      }
    } else {
      parsedDate = DateTime.now();
    }

    return Bird(
      id: data['id']?.toString() ?? '',
      name: data['name'] as String? ?? '',
      breed: parsedBreed,
      category: data['category'] as String? ?? 'Avian',
      ageOrHatchDate: parsedDate,
      sex: data['sex'] as String? ?? '',
      originType: data['origin_type'] as String? ?? '',
      sireId: data['sire_id'] as String?,
      damId: data['dam_id'] as String?,
      photoUrl: data['photo_url'] as String? ?? '',
      uid: resolvedOwnerId,
      ownerId: resolvedOwnerId,
      serialNumber: data['serial_number'] as String? ?? 'N/A',
      flockGrade: double.tryParse(data['flock_grade']?.toString() ?? '') ?? 8.5,
      geneticTraits: data['genetic_traits'] is List
          ? List<String>.from((data['genetic_traits'] as List).map((e) => e.toString()))
          : const [],
      cardVariant: data['card_variant'] as String? ?? 'Standard',
      level: int.tryParse(data['level']?.toString() ?? '') ?? 1,
      xp: int.tryParse(data['xp']?.toString() ?? '') ?? 0,
      discoveryType: data['discovery_type'] as String? ?? 'Resident',
      hardiness: data['hardiness'] != null ? (int.tryParse(data['hardiness'].toString()) ?? 50) : null,
      eggProduction: data['egg_production'] != null ? (int.tryParse(data['egg_production'].toString()) ?? 50) : null,
      rarityTier: data['rarity_tier'] as String?,
      gradeNotes: data['grade_notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'category': category,
      'age_or_hatch_date': ageOrHatchDate.toIso8601String(),
      'sex': sex,
      'origin_type': originType,
      'sire_id': sireId,
      'dam_id': damId,
      'photo_url': photoUrl,
      'uid': ownerId,
      'owner_id': ownerId,
      'user_id': ownerId,
      'serial_number': serialNumber,
      'flock_grade': flockGrade,
      'genetic_traits': geneticTraits,
      'card_variant': cardVariant,
      'level': level,
      'xp': xp,
      'discovery_type': discoveryType,
      'hardiness': hardiness,
      'egg_production': eggProduction,
      'rarity_tier': rarityTier,
      'grade_notes': gradeNotes,
    };
  }

  Bird copyWith({
    String? id,
    String? name,
    String? breed,
    String? category,
    DateTime? ageOrHatchDate,
    String? sex,
    String? originType,
    String? sireId,
    String? damId,
    String? photoUrl,
    String? uid,
    String? ownerId,
    String? serialNumber,
    double? flockGrade,
    List<String>? geneticTraits,
    String? cardVariant,
    int? level,
    int? xp,
    String? discoveryType,
    int? hardiness,
    int? eggProduction,
    String? rarityTier,
    String? gradeNotes,
  }) {
    return Bird(
      id: id ?? this.id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      category: category ?? this.category,
      ageOrHatchDate: ageOrHatchDate ?? this.ageOrHatchDate,
      sex: sex ?? this.sex,
      originType: originType ?? this.originType,
      sireId: sireId ?? this.sireId,
      damId: damId ?? this.damId,
      photoUrl: photoUrl ?? this.photoUrl,
      uid: uid ?? this.uid,
      ownerId: ownerId ?? this.ownerId,
      serialNumber: serialNumber ?? this.serialNumber,
      flockGrade: flockGrade ?? this.flockGrade,
      geneticTraits: geneticTraits ?? this.geneticTraits,
      cardVariant: cardVariant ?? this.cardVariant,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      discoveryType: discoveryType ?? this.discoveryType,
      hardiness: hardiness ?? this.hardiness,
      eggProduction: eggProduction ?? this.eggProduction,
      rarityTier: rarityTier ?? this.rarityTier,
      gradeNotes: gradeNotes ?? this.gradeNotes,
    );
  }
}
