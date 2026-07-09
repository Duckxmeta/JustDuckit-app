// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bird.dart';
import '../services/grading_engine.dart';
import '../utils/trait_styles.dart';
import 'new_incubation_screen.dart';
import 'flock_directory_screen.dart';
import 'daily_tasks_screen.dart';
import 'animal_profile_screen.dart';
import 'add_bird_screen.dart';
import '../services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name' or 'age'
  String _selectedDeck = 'All'; // 'All', 'Avian', 'Pets', 'Livestock', 'Aquatic'

  final List<String> _decks = ['All', 'Avian', 'Pets', 'Livestock', 'Aquatic'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _calculateAgeText(DateTime birthDate) {
    final difference = DateTime.now().difference(birthDate);
    final days = difference.inDays;
    if (days < 30) {
      return '$days days';
    }
    final months = (days / 30).floor();
    if (months < 12) {
      return '$months mos';
    }
    final years = (months / 12).floor();
    final remainingMonths = months % 12;
    if (remainingMonths == 0) {
      return '$years yrs';
    }
    return '$years y $remainingMonths m';
  }

  // Detailed animal profiles have been migrated to lib/screens/animal_profile_screen.dart

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App bar and search panel (TCG Binder theme)
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TCG FARMS',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                                letterSpacing: 1.2,
                                color: Colors.teal.shade800,
                              ),
                            ),
                            const Text(
                              'My Master Binder',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        // Action buttons: Sign Out
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.teal),
                              onPressed: () => setState(() {}),
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout_outlined, color: Colors.teal),
                              tooltip: 'Sign Out',
                              onPressed: () async {
                                final scaffoldMessenger = ScaffoldMessenger.of(context);
                                try {
                                  await FirebaseAuth.instance.signOut();
                                  scaffoldMessenger.showSnackBar(
                                    const SnackBar(content: Text('Successfully signed out.'), backgroundColor: Colors.teal),
                                  );
                                } catch (e) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(content: Text('Error signing out: $e'), backgroundColor: Colors.redAccent),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search bar
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search binder by name or breed...',
                                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                            ),
                            child: const Icon(Icons.sort_outlined, size: 20, color: Colors.teal),
                          ),
                          onSelected: (value) {
                            setState(() {
                              _sortBy = value;
                            });
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'name',
                              child: Text('Sort by Name'),
                            ),
                            const PopupMenuItem(
                              value: 'age',
                              child: Text('Sort by Age'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Horizontal scrolling Custom Decks Tab Selector
            SliverToBoxAdapter(
              child: Container(
                height: 48,
                margin: const EdgeInsets.only(top: 12.0),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _decks.length,
                  itemBuilder: (context, index) {
                    final deckName = _decks[index];
                    final isSelected = _selectedDeck == deckName;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(
                          deckName == 'All' ? 'Master Binder' : '$deckName Deck',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.teal.shade900,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Colors.teal.shade800,
                        backgroundColor: Colors.teal.shade50.withOpacity(0.5),
                        checkmarkColor: Colors.white,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedDeck = deckName;
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

            // Dashboard quick tools
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Binder Tools',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDashboardCard(
                            context,
                            title: 'Hatchery',
                            subtitle: 'Start Incubation',
                            icon: Icons.egg_outlined,
                            color: Colors.orange.shade700,
                            destination: const NewIncubationScreen(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDashboardCard(
                            context,
                            title: 'Tasks',
                            subtitle: 'Daily Chores',
                            icon: Icons.assignment_outlined,
                            color: Colors.blue.shade700,
                            destination: const DailyTasksScreen(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDashboardCard(
                            context,
                            title: 'Flock Directory',
                            subtitle: 'Grid Directory',
                            icon: Icons.grid_view_outlined,
                            color: Colors.teal.shade700,
                            destination: const FlockDirectoryScreen(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Binder collection listing header
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text(
                      _selectedDeck == 'All' ? 'Binder Inventory' : '$_selectedDeck Deck Inventory',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Card Grid list
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('birds')
                    .where('owner_id', isEqualTo: user?.uid ?? 'anonymous')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('Error loading flock inventory.')),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator(color: Colors.teal)),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.style_outlined, size: 64, color: Colors.teal.withOpacity(0.3)),
                              const SizedBox(height: 16),
                              const Text(
                                'No Avian Cards in Binder',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Add some real animals to your collection to start compiling your deck binder!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const AddBirdScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Animal'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // Map to models
                  List<Bird> birdsList = docs.map((doc) => Bird.fromFirestore(doc)).toList();

                  // Filter by search query
                  if (_searchQuery.isNotEmpty) {
                    birdsList = birdsList.where((bird) {
                      return bird.name.toLowerCase().contains(_searchQuery) ||
                          bird.breed.toLowerCase().contains(_searchQuery);
                    }).toList();
                  }

                  // Filter by selected Deck category
                  if (_selectedDeck != 'All') {
                    birdsList = birdsList.where((bird) {
                      final breedLower = bird.breed.toLowerCase();
                      if (_selectedDeck == 'Avian') {
                        return breedLower == 'avian' || 
                               breedLower.contains('duck') || 
                               breedLower.contains('chicken') || 
                               breedLower.contains('goose') || 
                               breedLower.contains('geese') || 
                               breedLower.contains('turkey') || 
                               breedLower.contains('quail');
                      } else if (_selectedDeck == 'Pets') {
                        return breedLower == 'pets' || 
                               breedLower == 'pet' || 
                               breedLower.contains('dog') || 
                               breedLower.contains('cat') || 
                               breedLower.contains('rabbit') || 
                               breedLower.contains('reptile');
                      } else if (_selectedDeck == 'Livestock') {
                        return breedLower == 'livestock' || 
                               breedLower.contains('pig') || 
                               breedLower.contains('goat') || 
                               breedLower.contains('cow') || 
                               breedLower.contains('sheep') || 
                               breedLower.contains('donkey');
                      } else if (_selectedDeck == 'Aquatic') {
                        return breedLower == 'aquatic' || 
                               breedLower.contains('fish') || 
                               breedLower.contains('shrimp') || 
                               breedLower.contains('aquaponic');
                      }
                      return true;
                    }).toList();
                  }

                  // Sort list
                  if (_sortBy == 'name') {
                    birdsList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                  } else if (_sortBy == 'age') {
                    birdsList.sort((a, b) => b.ageOrHatchDate.compareTo(a.ageOrHatchDate));
                  }

                  if (birdsList.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0),
                        child: Center(
                          child: Text(
                            _selectedDeck == 'All'
                                ? 'No cards match search criteria.'
                                : 'No cards found in the $_selectedDeck Deck matching criteria.',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400.0,
                      mainAxisSpacing: 12.0,
                      crossAxisSpacing: 12.0,
                      childAspectRatio: 2.7,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final bird = birdsList[index];
                        return Dismissible(
                          key: Key(bird.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20.0),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Card'),
                                content: Text('Are you sure you want to permanently delete ${bird.name} from your binder?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (direction) async {
                            try {
                              await DatabaseService.deleteAnimalCard(bird.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Permanently removed ${bird.name} from collection.'),
                                    backgroundColor: Colors.teal,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to delete card: $e'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          },
                          child: _buildAvianTradingCard(context, bird),
                        );
                      },
                      childCount: birdsList.length,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget destination,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => destination));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvianTradingCard(BuildContext context, Bird bird) {
    final int hash = bird.breed.hashCode;
    final double hue = (hash.abs() % 360).toDouble();
    final Color tagBgColor = HSLColor.fromAHSL(0.08, hue, 0.70, 0.40).toColor();
    final Color tagTextColor = HSLColor.fromAHSL(1.0, hue, 0.85, 0.30).toColor();

    final sexColor = bird.sex == 'Male'
        ? Colors.blue.shade600
        : bird.sex == 'Female'
            ? Colors.pink.shade600
            : Colors.grey.shade600;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AnimalProfileScreen(animal: bird),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              // Left Image Canvas with dynamic flockGrade badge overlay
              Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: bird.photoUrl != null && bird.photoUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              bird.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(child: Icon(Icons.pets, color: Colors.teal, size: 28)),
                            ),
                          )
                        : const Center(
                            child: Text(
                              '🐣',
                              style: TextStyle(fontSize: 28),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 2,
                    left: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black87, width: 1.2),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 1, offset: Offset(1, 1)),
                        ],
                      ),
                      child: Text(
                        GradingEngine.calculateGrade(bird).toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Center Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      bird.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Breed tag pill & scrolling traits row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: tagBgColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              bird.breed,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: tagTextColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (bird.geneticTraits.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            ...bird.geneticTraits.map((trait) {
                              final style = TraitStyles.getStyle(trait);
                              return Padding(
                                padding: const EdgeInsets.only(right: 4.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: style.backgroundColor,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: style.textColor.withOpacity(0.1)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(style.icon, size: 8, color: style.textColor),
                                      const SizedBox(width: 2),
                                      Text(
                                        trait,
                                        style: TextStyle(
                                          color: style.textColor,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Key-value metrics
                    Row(
                      children: [
                        Text(
                          'Age: ${_calculateAgeText(bird.ageOrHatchDate)}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 11),
                        ),
                        const SizedBox(width: 8),
                        Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Icon(
                          bird.sex == 'Male'
                              ? Icons.male
                              : bird.sex == 'Female'
                                  ? Icons.female
                                  : Icons.question_mark,
                          size: 11,
                          color: sexColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          bird.sex,
                          style: TextStyle(color: sexColor, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Right side: modern chevron button
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
