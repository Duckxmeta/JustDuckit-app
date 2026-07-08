import 'package:cloud_firestore/cloud_firestore.dart';

class Bird {
  final String id;
  final String name;
  final String breed;
  final DateTime ageOrHatchDate;
  final String sex;
  final String originType;
  final String? sireId;
  final String? damId;
  final String? photoUrl;
  final String uid;

  Bird({
    required this.id,
    required this.name,
    required this.breed,
    required this.ageOrHatchDate,
    required this.sex,
    required this.originType,
    this.sireId,
    this.damId,
    this.photoUrl,
    required this.uid,
  });

  factory Bird.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Bird(
      id: doc.id,
      name: data['name'] as String? ?? '',
      breed: data['breed'] as String? ?? '',
      ageOrHatchDate: data['age_or_hatch_date'] is Timestamp
          ? (data['age_or_hatch_date'] as Timestamp).toDate()
          : DateTime.now(),
      sex: data['sex'] as String? ?? '',
      originType: data['origin_type'] as String? ?? '',
      sireId: data['sire_id'] as String?,
      damId: data['dam_id'] as String?,
      photoUrl: data['photo_url'] as String?,
      uid: data['uid'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'breed': breed,
      'age_or_hatch_date': Timestamp.fromDate(ageOrHatchDate),
      'sex': sex,
      'origin_type': originType,
      if (sireId != null) 'sire_id': sireId,
      if (damId != null) 'dam_id': damId,
      if (photoUrl != null) 'photo_url': photoUrl,
      'uid': uid,
    };
  }

  Bird copyWith({
    String? id,
    String? name,
    String? breed,
    DateTime? ageOrHatchDate,
    String? sex,
    String? originType,
    String? sireId,
    String? damId,
    String? photoUrl,
    String? uid,
  }) {
    return Bird(
      id: id ?? this.id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      ageOrHatchDate: ageOrHatchDate ?? this.ageOrHatchDate,
      sex: sex ?? this.sex,
      originType: originType ?? this.originType,
      sireId: sireId ?? this.sireId,
      damId: damId ?? this.damId,
      photoUrl: photoUrl ?? this.photoUrl,
      uid: uid ?? this.uid,
    );
  }
}
