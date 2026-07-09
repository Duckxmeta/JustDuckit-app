import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bird.dart';
import 'add_bird_screen.dart';
import 'lineage_tree_screen.dart';
import '../widgets/storage_image.dart';

class FlockDirectoryScreen extends StatefulWidget {
  const FlockDirectoryScreen({super.key});

  @override
  State<FlockDirectoryScreen> createState() => _FlockDirectoryScreenState();
}

class _FlockDirectoryScreenState extends State<FlockDirectoryScreen> {
  String? _selectedBreedFilter;
  String? _selectedSexFilter;

  String _calculateAge(DateTime hatchDate) {
    final difference = DateTime.now().difference(hatchDate);
    final days = difference.inDays;
    
    if (days < 0) {
      return 'Not hatched';
    } else if (days < 30) {
      return '$days day${days != 1 ? 's' : ''}';
    } else if (days < 365) {
      final months = (days / 30).floor();
      return '$months month${months != 1 ? 's' : ''}';
    } else {
      final years = (days / 365).floor();
      final remainingMonths = ((days % 365) / 30).floor();
      if (remainingMonths > 0) {
        return '$years yr${years != 1 ? 's' : ''} $remainingMonths mo';
      }
      return '$years yr${years != 1 ? 's' : ''}';
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedBreedFilter = null;
      _selectedSexFilter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Flock Directory'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedBreedFilter != null || _selectedSexFilter != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'Clear Filters',
              onPressed: _clearFilters,
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('animals')
            .where('uid', isEqualTo: user?.uid ?? 'anonymous')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading flock data: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allBirds = snapshot.data!.docs.map((doc) => Bird.fromFirestore(doc)).toList();

          if (allBirds.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pets, size: 64, color: Colors.teal.shade200),
                    const SizedBox(height: 16),
                    const Text(
                      'No birds in your flock yet!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the "+" button below to add your first duckling.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }

          // Gather unique breeds for filter options
          final breeds = allBirds.map((b) => b.breed).toSet().toList()..sort();
          final sexes = ['Male', 'Female', 'Unknown'];

          // Filter logic
          var filteredBirds = allBirds;
          if (_selectedBreedFilter != null) {
            filteredBirds = filteredBirds.where((b) => b.breed == _selectedBreedFilter).toList();
          }
          if (_selectedSexFilter != null) {
            filteredBirds = filteredBirds.where((b) => b.sex == _selectedSexFilter).toList();
          }

          return Column(
            children: [
              // Filter chip row
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Breed filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              'Breed:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade900,
                              ),
                            ),
                          ),
                          ...breeds.map((breed) {
                            final isSelected = _selectedBreedFilter == breed;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: FilterChip(
                                label: Text(breed, style: const TextStyle(fontSize: 12)),
                                selected: isSelected,
                                selectedColor: Colors.teal.shade100,
                                checkmarkColor: Colors.teal.shade800,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.teal.shade900 : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedBreedFilter = selected ? breed : null;
                                  });
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Sex filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              'Sex:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade900,
                              ),
                            ),
                          ),
                          ...sexes.map((sex) {
                            final isSelected = _selectedSexFilter == sex;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: FilterChip(
                                label: Text(sex, style: const TextStyle(fontSize: 12)),
                                selected: isSelected,
                                selectedColor: Colors.teal.shade100,
                                checkmarkColor: Colors.teal.shade800,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.teal.shade900 : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedSexFilter = selected ? sex : null;
                                  });
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Birds Grid
              Expanded(
                child: filteredBirds.isEmpty
                    ? Center(
                        child: Text(
                          'No birds match the selected filters.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12.0),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: filteredBirds.length,
                        itemBuilder: (context, index) {
                          final bird = filteredBirds[index];
                          final ageText = _calculateAge(bird.ageOrHatchDate);
                          final isMale = bird.sex == 'Male';
                          final isFemale = bird.sex == 'Female';

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => LineageTreeScreen(startBirdId: bird.id),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Profile Image / Icon
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.teal.shade50,
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(12),
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: bird.photoUrl != null
                                          ? StorageImage(
                                              photoUrl: bird.photoUrl!,
                                              fit: BoxFit.cover,
                                              errorWidget: Icon(Icons.pets, size: 40, color: Colors.teal.shade300),
                                            )
                                          : Icon(Icons.pets, size: 40, color: Colors.teal.shade300),
                                    ),
                                  ),

                                  // Details Section
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Name and Sex Icon
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                bird.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isMale)
                                              const Icon(Icons.male, color: Colors.blue, size: 16)
                                            else if (isFemale)
                                              const Icon(Icons.female, color: Colors.pink, size: 16),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        // Breed
                                        Text(
                                          bird.breed,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        // Age
                                        Text(
                                          'Age: $ageText',
                                          style: TextStyle(
                                            color: Colors.teal.shade800,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddBirdScreen(),
            ),
          );
        },
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
