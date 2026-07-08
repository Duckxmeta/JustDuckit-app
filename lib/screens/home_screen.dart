// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bird.dart';
import 'new_incubation_screen.dart';
import 'lineage_tree_screen.dart';
import 'flock_directory_screen.dart';
import 'daily_tasks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name' or 'age'
  bool _isLoadingAuth = false;

  @override
  void initState() {
    super.initState();
    _ensureUserAuthenticated();
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

  Future<void> _ensureUserAuthenticated() async {
    if (FirebaseAuth.instance.currentUser == null) {
      setState(() {
        _isLoadingAuth = true;
      });
      try {
        await FirebaseAuth.instance.signInAnonymously();
      } catch (e) {
        debugPrint("Error signing in anonymously: $e");
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingAuth = false;
          });
        }
      }
    }
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

  Future<void> _bootstrapDummyBird() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final names = ['Donald', 'Daffy', 'Webby', 'Launchpad', 'Scrooge', 'Dewey'];
    final breeds = ['Pekin Duck', 'Khaki Campbell', 'Runner Duck', 'Muscovy Duck'];
    final sexes = ['Male', 'Female', 'Unknown'];
    
    final count = names.length;
    final index = DateTime.now().millisecondsSinceEpoch % count;
    
    final starterBird = {
      'name': '${names[index]} (Starter)',
      'breed': breeds[index % breeds.length],
      'age_or_hatch_date': Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: (index + 1) * 45)),
      ),
      'sex': sexes[index % sexes.length],
      'origin_type': 'Hatched',
      'uid': user.uid,
    };

    try {
      await FirebaseFirestore.instance.collection('birds').add(starterBird);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to bootstrap bird: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: _isLoadingAuth
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.teal),
                    SizedBox(height: 16),
                    Text('Connecting to avian registry...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : CustomScrollView(
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
                                    'JUST DUCKIT',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontWeight: FontWeight.w900,
                                      fontSize: 24,
                                      letterSpacing: 1.2,
                                      color: Colors.teal.shade800,
                                    ),
                                  ),
                                  Text(
                                    'Avian Inventory & Pedigree Collector',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh, color: Colors.teal),
                                onPressed: () => setState(() {}),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Search field
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
                                      hintText: 'Search collection by name or breed...',
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

                  // Dashboard quick navigation links
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Tools',
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
                                  title: 'Flock',
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

                  // Avian Card collection grid header
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Avian Trading Cards',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _bootstrapDummyBird,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Dummy Card', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.teal.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Card Grid listing
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('birds')
                          .where('uid', isEqualTo: user?.uid ?? 'anonymous')
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
                                      'No Avian Cards Found',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Click "Add Dummy Card" or navigate to the Flock Directory to start compiling your collection.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _bootstrapDummyBird,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('Add Starter Card'),
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

                        // Sort list
                        if (_sortBy == 'name') {
                          birdsList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                        } else if (_sortBy == 'age') {
                          birdsList.sort((a, b) => b.ageOrHatchDate.compareTo(a.ageOrHatchDate)); // older first
                        }

                        if (birdsList.isEmpty) {
                          return const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 32.0),
                              child: Center(
                                child: Text('No cards match your search criteria.', style: TextStyle(color: Colors.grey)),
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
                              return _buildAvianTradingCard(context, bird);
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
    // Generate an HSL color based on breed string to keep tags looking structured
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
              builder: (context) => LineageTreeScreen(startBirdId: bird.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              // Left Image Canvas
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
                    // Breed tag pill
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
