import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  /// Securely deletes a specific animal card document from Supabase.
  static Future<void> deleteAnimalCard(String animalId) async {
    await Supabase.instance.client
        .from('animals')
        .delete()
        .eq('id', animalId);
  }
}
