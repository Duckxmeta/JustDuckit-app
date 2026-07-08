// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bird.dart';
import '../services/grading_engine.dart';
import '../utils/trait_styles.dart';
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
  String _selectedDeck = 'All'; // 'All', 'Ducks', 'Chickens', 'Geese', 'Turkeys'

  final List<String> _decks = ['All', 'Ducks', 'Chickens', 'Geese', 'Turkeys'];

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

  Future<void> _bootstrapDummyBird() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final names = ['Donald', 'Daffy', 'Webby', 'Launchpad', 'Scrooge', 'Dewey'];
    final breeds = ['Pekin Duck', 'Khaki Campbell', 'Runner Duck', 'Muscovy Duck'];
    final sexes = ['Male', 'Female', 'Unknown'];
    final traitPool = [
      ['Crested', 'Dual-Lobe Bill'],
      ['Silver Appleyard', 'High Production'],
      ['Swedish Blue', 'Show Quality'],
      ['High Production', 'Crested'],
    ];
    final variants = ['Standard', 'Holo', 'Full-Art'];
    
    final count = names.length;
    final index = DateTime.now().millisecondsSinceEpoch % count;
    final grade = ((index * 0.45 + 7.8).clamp(1.0, 10.0) * 10).round() / 10;
    
    final starterBird = {
      'name': '${names[index]} (Starter)',
      'breed': breeds[index % breeds.length],
      'age_or_hatch_date': Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: (index + 1) * 45)),
      ),
      'sex': sexes[index % sexes.length],
      'origin_type': 'Hatched',
      'uid': user.uid,
      'owner_id': user.uid,
      'serial_number': 'Batch #${(index + 101).toString().padLeft(3, '0')}',
      'flock_grade': grade,
      'genetic_traits': traitPool[index % traitPool.length],
      'card_variant': variants[index % variants.length],
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

  void _showShareOverlay(BuildContext context, Bird bird) {
    final int hash = bird.breed.hashCode;
    final double hue = (hash.abs() % 360).toDouble();
    final Color cardAccentColor = HSLColor.fromAHSL(1.0, hue, 0.75, 0.35).toColor();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Graphic Card Mockup
              Container(
                width: 320,
                height: 480,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: bird.cardVariant == 'Holo' ? Colors.cyanAccent.shade200 : cardAccentColor,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (bird.cardVariant == 'Holo' ? Colors.cyan : cardAccentColor).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Background Graphic canvas
                      if (bird.cardVariant == 'Full-Art' && bird.photoUrl != null && bird.photoUrl!.isNotEmpty)
                        Image.network(
                          bird.photoUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.teal.shade900,
                                Colors.teal.shade600,
                                Colors.blueGrey.shade800,
                              ],
                            ),
                          ),
                        ),

                      // Holographic Sheen Overlay
                      if (bird.cardVariant == 'Holo')
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.cyanAccent.withOpacity(0.08),
                                Colors.purpleAccent.withOpacity(0.08),
                                Colors.white.withOpacity(0.0),
                              ],
                              stops: const [0.0, 0.35, 0.70, 1.0],
                            ),
                          ),
                        ),

                      // Card details overlay
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bird.name.toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          letterSpacing: 1.0,
                                          shadows: [Shadow(color: Colors.black50, blurRadius: 4, offset: Offset(1, 1))],
                                        ),
                                      ),
                                      Text(
                                        bird.serialNumber,
                                        style: TextStyle(
                                          color: Colors.teal.shade200,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          shadows: const [Shadow(color: Colors.black87, blurRadius: 2)],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: Colors.black87, width: 2),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2)),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'FLOCK',
                                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey),
                                      ),
                                      Text(
                                        GradingEngine.calculateGrade(bird).toStringAsFixed(1),
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (bird.cardVariant != 'Full-Art')
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black12,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white24, width: 1.5),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: bird.photoUrl != null && bird.photoUrl!.isNotEmpty
                                      ? Image.network(bird.photoUrl!, fit: BoxFit.cover)
                                      : const Center(
                                          child: Text('🐣', style: TextStyle(fontSize: 80)),
                                        ),
                                ),
                              )
                            else
                              const Spacer(),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white12, width: 1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        bird.breed,
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        bird.cardVariant.toUpperCase(),
                                        style: TextStyle(
                                          color: bird.cardVariant == 'Holo'
                                              ? Colors.cyanAccent
                                              : bird.cardVariant == 'Full-Art'
                                                  ? Colors.amberAccent
                                                  : Colors.white70,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(color: Colors.white24, height: 16),
                                  Text(
                                    'AGE: ${_calculateAgeText(bird.ageOrHatchDate).toUpperCase()}  |  SEX: ${bird.sex.toUpperCase()}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                  if (bird.geneticTraits.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'GENETICS: ${bird.geneticTraits.join(", ").toUpperCase()}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.teal.shade200, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Avian Trading Card saved to device!'),
                          backgroundColor: Colors.teal,
                        ),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Save Card'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Card link copied to clipboard! Share on social media.'),
                          backgroundColor: Colors.teal,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Link'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close Preview', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBirdProfilePreview(BuildContext context, Bird bird) {
    final int hash = bird.breed.hashCode;
    final double hue = (hash.abs() % 360).toDouble();
    final Color cardAccentColor = HSLColor.fromAHSL(1.0, hue, 0.75, 0.35).toColor();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200, width: 2),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: bird.photoUrl != null && bird.photoUrl!.isNotEmpty
                                    ? Image.network(bird.photoUrl!, fit: BoxFit.cover)
                                    : const Center(child: Text('🐣', style: TextStyle(fontSize: 36))),
                              ),
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: Colors.black87, width: 1.5),
                                    borderRadius: BorderRadius.circular(3),
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
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bird.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: cardAccentColor.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        bird.breed,
                                        style: TextStyle(color: cardAccentColor, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        bird.cardVariant,
                                        style: const TextStyle(color: Colors.teal, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Serial: ${bird.serialNumber}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Age: ${_calculateAgeText(bird.ageOrHatchDate)}  |  Sex: ${bird.sex}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Collectible Details',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.style, color: Colors.teal),
                    title: const Text('Card Rarity Variant'),
                    subtitle: Text(bird.cardVariant),
                    trailing: Text(
                      bird.cardVariant == 'Standard'
                          ? 'Common'
                          : bird.cardVariant == 'Holo'
                              ? 'Rare'
                              : 'Legendary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: bird.cardVariant == 'Standard'
                            ? Colors.grey
                            : bird.cardVariant == 'Holo'
                                ? Colors.teal
                                : Colors.deepOrange,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.qr_code, color: Colors.teal),
                    title: const Text('Serial Production ID'),
                    subtitle: Text(bird.serialNumber),
                  ),
                  ListTile(
                    leading: const Icon(Icons.verified_user, color: Colors.teal),
                    title: const Text('Dynamic Quality Grade'),
                    subtitle: const Text('Calculated dynamically from flock wellness journals'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${GradingEngine.calculateGrade(bird)} / 10.0 (${GradingEngine.getTierLabel(GradingEngine.calculateGrade(bird))})',
                        style: TextStyle(color: Colors.teal.shade900, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Genetic Trait Pool',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 8),
                  if (bird.geneticTraits.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('No genetic traits documented for this card yet.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: bird.geneticTraits.map((trait) {
                        return Chip(
                          label: Text(trait, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          avatar: const Icon(Icons.dna, size: 14, color: Colors.teal),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showShareOverlay(context, bird);
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share Graphic Card'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => LineageTreeScreen(startBirdId: bird.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.account_tree),
                    label: const Text('View Lineage Pedigree Tree'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      side: const BorderSide(color: Colors.teal),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

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
                              'MY MASTER BINDER',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                                letterSpacing: 1.2,
                                color: Colors.teal.shade800,
                              ),
                            ),
                            Text(
                              'Avian Card Collection Registry',
                              style: TextStyle(
                                color: Colors.grey[600],
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
                          onPressed: () {},
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDeck == 'All' ? 'Binder Inventory' : '$_selectedDeck Deck Inventory',
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

                  // Filter by selected Deck category
                  if (_selectedDeck != 'All') {
                    birdsList = birdsList.where((bird) {
                      final breedLower = bird.breed.toLowerCase();
                      if (_selectedDeck == 'Ducks') {
                        return breedLower.contains('duck');
                      } else if (_selectedDeck == 'Chickens') {
                        return breedLower.contains('chicken');
                      } else if (_selectedDeck == 'Geese') {
                        return breedLower.contains('goose') || breedLower.contains('geese');
                      } else if (_selectedDeck == 'Turkeys') {
                        return breedLower.contains('turkey');
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
        onTap: () => _showBirdProfilePreview(context, bird),
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
