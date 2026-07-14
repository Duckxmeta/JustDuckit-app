// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bird.dart';
import '../services/grading_engine.dart';
import 'new_incubation_screen.dart';
import 'flock_directory_screen.dart';
import 'daily_tasks_screen.dart';
import 'animal_profile_screen.dart';
import 'add_bird_screen.dart';
import '../services/database_service.dart';
import '../widgets/storage_image.dart';
import 'global_registry_screen.dart';
import 'encounter_scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
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
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: _currentIndex == 0
              ? StreamBuilder<List<Map<String, dynamic>>>(
                  stream: Supabase.instance.client
                      .from('animals')
                      .stream(primaryKey: ['id'])
                      .eq('user_id', user?.id ?? 'anonymous'),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      debugPrint("Database fetch error details: ${snapshot.error}");
                      return const Center(child: Text("Error loading flock inventory."));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SafeArea(
                        child: Center(child: CircularProgressIndicator(color: Colors.teal)),
                      );
                    }

                    final rows = snapshot.data ?? [];
                    if (rows.isEmpty) {
                      return const Center(
                        child: Text("Your Binder is empty! Tap the action button to scan your first animal."),
                      );
                    }

                    List<Bird> birdsList = rows.map((row) => Bird.fromMap(row)).toList();

                    // Calculate Portfolio Metrics
                    final totalBirds = birdsList.length;
                    final avgGrade = totalBirds > 0
                        ? birdsList.map((b) => b.flockGrade).reduce((a, b) => a + b) / totalBirds
                        : 0.0;
                    final estimatedValue = birdsList.fold<double>(
                      0.0,
                      (accumulated, b) => accumulated + GradingEngine.calculateValue(b.rarityTier, b.flockGrade),
                    );

                    // Apply filters for inventory view
                    List<Bird> filteredBirds = List.from(birdsList);
                    if (_searchQuery.isNotEmpty) {
                      filteredBirds = filteredBirds.where((bird) {
                        return bird.name.toLowerCase().contains(_searchQuery) ||
                            bird.breed.toLowerCase().contains(_searchQuery);
                      }).toList();
                    }

                    if (_selectedDeck != 'All') {
                      filteredBirds = filteredBirds.where((bird) {
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

                    if (_sortBy == 'name') {
                      filteredBirds.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                    } else if (_sortBy == 'age') {
                      filteredBirds.sort((a, b) => b.ageOrHatchDate.compareTo(a.ageOrHatchDate));
                    }

                    return SafeArea(
                      child: CustomScrollView(
                        slivers: [
                          // App bar and search panel
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
                                                await Supabase.instance.client.auth.signOut();
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

                          // Top Portfolio Header Card
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.teal.shade900.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'FLOCK PORTFOLIO VALUE',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${estimatedValue.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Color(0xFFFFD700), // Gold
                                        fontSize: 28,
                                        fontFamily: 'Outfit',
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildPortfolioStat('Flock Count', '$totalBirds Birds', Icons.pets_outlined),
                                        _buildPortfolioStat('Avg PSA Grade', totalBirds > 0 ? avgGrade.toStringAsFixed(1) : '0.0', Icons.star_border),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Horizontal scrolling Custom Decks Tab Selector
                          SliverToBoxAdapter(
                            child: Container(
                              height: 48,
                              margin: const EdgeInsets.only(top: 4.0),
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
                            sliver: filteredBirds.isEmpty
                                ? SliverToBoxAdapter(
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
                                  )
                                : SliverGrid(
                                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 220.0,
                                      mainAxisSpacing: 12.0,
                                      crossAxisSpacing: 12.0,
                                      childAspectRatio: 0.78,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final bird = filteredBirds[index];
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
                                          child: _buildVerticalTradingCard(context, bird),
                                        );
                                      },
                                      childCount: filteredBirds.length,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : const GlobalRegistryScreen(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.teal.shade800,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.style),
            label: 'My Binder',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.public),
            label: 'Global Registry',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const EncounterScannerScreen(),
            ),
          );
        },
        backgroundColor: Colors.teal.shade700,
        tooltip: 'Scan Encounter',
        child: const Icon(Icons.explore, color: Colors.white),
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

  Widget _buildPortfolioStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal.shade200, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold),
            ),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerticalTradingCard(BuildContext context, Bird bird) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Image half
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: bird.photoUrl != null && bird.photoUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: StorageImage(
                              photoUrl: bird.photoUrl!,
                              fit: BoxFit.cover,
                              errorWidget: const Center(
                                child: Icon(Icons.pets, color: Colors.teal, size: 36),
                              ),
                            ),
                          )
                        : const Center(
                            child: Text(
                              '🐣',
                              style: TextStyle(fontSize: 48),
                            ),
                          ),
                  ),
                  // Grade Badge overlay
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black87, width: 1.2),
                        borderRadius: BorderRadius.circular(4),
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
                  // Card variant badge overlay (e.g. Holo)
                  if (bird.cardVariant != 'Standard')
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          bird.cardVariant.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Bottom details half
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          bird.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        bird.sex == 'Male'
                            ? Icons.male
                            : bird.sex == 'Female'
                                ? Icons.female
                                : Icons.question_mark,
                        size: 12,
                        color: sexColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: tagBgColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      bird.geneticTraits.isNotEmpty ? bird.geneticTraits[0] : bird.breed,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tagTextColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Age: ${_calculateAgeText(bird.ageOrHatchDate)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
