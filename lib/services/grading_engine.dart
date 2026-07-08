// lib/services/grading_engine.dart

import '../models/bird.dart';

class GradingEngine {
  /// Calculates a dynamic collector grade between 1.0 and 10.0 based on data metrics.
  static double calculateGrade(Bird bird) {
    // 1. Production Consistency (35% -> max 3.5 points)
    double prodScore = 2.0; // Baseline
    
    // Standard layers/productive breeds get a bonus
    final breedLower = bird.breed.toLowerCase();
    if (breedLower.contains('pekin') || 
        breedLower.contains('chicken') || 
        breedLower.contains('campbell') || 
        breedLower.contains('standard')) {
      prodScore += 1.0;
    }
    
    // Mature age implies stable records/production history
    final ageInDays = DateTime.now().difference(bird.ageOrHatchDate).inDays;
    if (ageInDays > 180) {
      prodScore += 0.5; // Mature layer/breeder
    } else if (ageInDays > 60) {
      prodScore += 0.2; // Intermediate
    }
    prodScore = prodScore.clamp(0.0, 3.5);

    // 2. Proof of Work / Data Depth (25% -> max 2.5 points)
    double depthScore = 0.5; // Baseline
    
    if (bird.photoUrl != null && bird.photoUrl!.isNotEmpty) {
      depthScore += 1.0; // Physical photo verification
    }
    if (bird.geneticTraits.isNotEmpty) {
      depthScore += 0.5; // Genetic records present
    }
    if (bird.serialNumber != 'N/A') {
      depthScore += 0.5; // Validated registry tag
    }
    depthScore = depthScore.clamp(0.0, 2.5);

    // 3. Lineage Depth (20% -> max 2.0 points)
    double lineageScore = 0.0;
    if (bird.sireId != null && bird.sireId!.isNotEmpty) {
      lineageScore += 1.0; // Father tracked
    }
    if (bird.damId != null && bird.damId!.isNotEmpty) {
      lineageScore += 1.0; // Mother tracked
    }
    lineageScore = lineageScore.clamp(0.0, 2.0);

    // 4. Health Stability (20% -> max 2.0 points)
    double healthScore = 2.0; // Default pristine health
    
    if (bird.originType == 'Rehomed') {
      healthScore -= 0.5; // Historical recovery penalty
    }
    final nameLower = bird.name.toLowerCase();
    if (nameLower.contains('rescue') || nameLower.contains('sick') || nameLower.contains('injured')) {
      healthScore -= 1.0; // Active medical notes
    }
    healthScore = healthScore.clamp(0.0, 2.0);

    // Combine parameters
    final double rawTotal = prodScore + depthScore + lineageScore + healthScore;
    
    // Round cleanly to 1 decimal place (clamp between 1.0 and 10.0)
    return (rawTotal.clamp(1.0, 10.0) * 10).round() / 10;
  }

  /// Maps the double grade value back to the corresponding TCG grade tier label.
  static String getTierLabel(double grade) {
    if (grade >= 9.0) {
      return 'Pristine Mint';
    } else if (grade >= 8.0) {
      return 'Near Mint';
    } else if (grade >= 7.0) {
      return 'Excellent';
    } else {
      return 'Good';
    }
  }
}
