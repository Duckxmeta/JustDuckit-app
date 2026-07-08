// lib/services/incubation_calculator.dart

class BreedTemplate {
  final String breedName;
  final int totalDays;
  final int lockdownDay;
  final double standardHumidity;
  final double lockdownHumidity;

  const BreedTemplate({
    required this.breedName,
    required this.totalDays,
    required this.lockdownDay,
    required this.standardHumidity,
    required this.lockdownHumidity,
  });
}

class IncubationCalculator {
  // Pre-loaded templates for rookie bird owners
  static const Map<String, BreedTemplate> duckTemplates = {
    'standard': BreedTemplate(
      breedName: 'Standard Duck (Pekin, Khaki Campbell, Runner, etc.)',
      totalDays: 28,
      lockdownDay: 25,
      standardHumidity: 45.0,
      lockdownHumidity: 70.0,
    ),
    'muscovy': BreedTemplate(
      breedName: 'Muscovy Duck',
      totalDays: 35,
      lockdownDay: 31,
      standardHumidity: 45.0,
      lockdownHumidity: 70.0,
    ),
  };

  /// Calculates the milestone dates for a new incubation batch based on start date and breed type
  static Map<String, DateTime> calculateMilestones(DateTime startDate, String breedKey) {
    final template = duckTemplates[breedKey] ?? duckTemplates['standard']!;
    
    final lockdownDate = startDate.add(Duration(days: template.lockdownDay));
    final hatchDate = startDate.add(Duration(days: template.totalDays));

    return {
      'lockdownDate': lockdownDate,
      'hatchDate': hatchDate,
    };
  }
}
