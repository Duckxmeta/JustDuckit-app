import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/new_incubation_screen.dart';
import 'screens/lineage_tree_screen.dart';
import 'screens/flock_directory_screen.dart';
import 'screens/daily_tasks_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization info/error: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Just Duckit',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Just Duckit'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Just Duckit!\nFlutter & Firebase Setup Complete.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NewIncubationScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.egg),
              label: const Text('Start New Incubation Batch'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FlockDirectoryScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.folder_shared),
              label: const Text('View Flock Directory'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DailyTasksScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('View Daily Care Tasks'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                try {
                  final birdsQuery = await FirebaseFirestore.instance.collection('birds').limit(1).get();
                  if (birdsQuery.docs.isNotEmpty) {
                    final firstBirdId = birdsQuery.docs.first.id;
                    navigator.push(
                      MaterialPageRoute(
                        builder: (context) => LineageTreeScreen(startBirdId: firstBirdId),
                      ),
                    );
                  } else {
                    // Create a starter dummy bird to bootstrap the screen
                    final newBirdRef = FirebaseFirestore.instance.collection('birds').doc();
                    final user = FirebaseAuth.instance.currentUser;
                    
                    final starterBird = {
                      'name': 'Donald (Starter Bird)',
                      'breed': 'Pekin Duck',
                      'age_or_hatch_date': Timestamp.now(),
                      'sex': 'Male',
                      'origin_type': 'Hatched',
                      'uid': user?.uid ?? 'anonymous',
                    };
                    
                    await newBirdRef.set(starterBird);
                    
                    navigator.push(
                      MaterialPageRoute(
                        builder: (context) => LineageTreeScreen(startBirdId: newBirdRef.id),
                      ),
                    );
                  }
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error loading or bootstrapping lineage tree: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.account_tree),
              label: const Text('View Lineage Pedigree Tree'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
