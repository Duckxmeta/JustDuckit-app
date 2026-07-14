import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bird.dart';
import '../services/grading_engine.dart';
import '../services/ai_appraiser_service.dart';

class EncounterScannerScreen extends StatefulWidget {
  const EncounterScannerScreen({super.key});

  @override
  State<EncounterScannerScreen> createState() => _EncounterScannerScreenState();
}

class _EncounterScannerScreenState extends State<EncounterScannerScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Camera initialization error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<Position?> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
    } catch (e) {
      print('GPS Fetch Error: $e');
      return null;
    }
  }

  Future<void> _captureEncounter() async {
    if (_isCapturing) return;
    setState(() {
      _isCapturing = true;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      // Capture coordinates
      Position? position = await _determinePosition();

      List<int>? imageBytes;
      XFile? imageFile;

      if (_isInitialized && _cameraController != null) {
        imageFile = await _cameraController!.takePicture();
        imageBytes = await imageFile.readAsBytes();
      } else {
        // Fallback mockup simulated image bytes (a simple 1x1 grey PNG byte matrix)
        imageBytes = [
          137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 200, 137, 0, 0, 0, 13, 73, 68, 65, 84, 120, 156, 99, 96, 64, 8, 0, 0, 2, 0, 1, 25, 47, 221, 18, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130
        ];
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('You must be logged in to register an encounter.');
      }

      // 1. Analyze animal image using AIAppraiserService
      final appraiser = AIAppraiserService();
      final appraisal = await appraiser.analyzeAnimalImage(imageBytes);

      final String detectedBreed = appraisal['detectedBreed'] ?? 'Avian';
      final String suggestedArchetype = appraisal['suggestedArchetype'] ?? 'Wild Scout';
      final int estimatedAge = appraisal['estimatedAge'] ?? 3;
      final List<String> notableTraits = List<String>.from(appraisal['notableTraits'] ?? []);

      // 2. Grade traits using dynamic GradingEngine
      final isCrested = notableTraits.contains('Crested');
      final isShowQuality = notableTraits.contains('Show Quality');
      final isHighProduction = notableTraits.contains('High Production');

      final grading = await GradingEngine.gradeAnimal(
        breed: detectedBreed,
        crossBreedDetails: '',
        birthDate: DateTime.now().subtract(Duration(days: estimatedAge * 30)),
        isCrested: isCrested,
        isShowQuality: isShowQuality,
        isHighProduction: isHighProduction,
        originType: 'Encounter',
      );

      final String birdId = 'encounter_${DateTime.now().microsecondsSinceEpoch}';
      String? photoUrl;

      // 3. Upload raw capture to Supabase Storage under encounter-photos/
      if (imageFile != null) {
        final String path = 'users/${user.id}/$birdId.jpg';
        await Supabase.instance.client.storage
            .from('encounter-photos')
            .uploadBinary(path, Uint8List.fromList(imageBytes));
        photoUrl = Supabase.instance.client.storage
            .from('encounter-photos')
            .getPublicUrl(path);
      }

      // 4. Instantiate Bird model and push to Firestore
      final newBird = Bird(
        id: birdId,
        name: suggestedArchetype,
        breed: detectedBreed,
        category: 'Avian',
        ageOrHatchDate: DateTime.now().subtract(Duration(days: estimatedAge * 30)),
        sex: 'Unknown',
        originType: 'Encounter',
        photoUrl: photoUrl,
        uid: user.id,
        ownerId: user.id,
        serialNumber: 'ENC #${(DateTime.now().millisecondsSinceEpoch % 1000).toString().padLeft(3, '0')}',
        flockGrade: (grading['psa_grade'] as num?)?.toDouble() ?? 8.5,
        geneticTraits: notableTraits.isEmpty ? const ['Wild Encounter'] : notableTraits,
        cardVariant: 'Standard',
        hardiness: grading['hardiness'] as int?,
        eggProduction: grading['egg_production'] as int?,
        rarityTier: grading['rarity_tier'] as String?,
        gradeNotes: grading['grade_notes'] as String?,
        level: 1,
        xp: 0,
        discoveryType: 'Encounter', // Forced metadata property
      );

      final docData = newBird.toMap();
      if (position != null) {
        docData['latitude'] = position.latitude;
        docData['longitude'] = position.longitude;
      }

      await Supabase.instance.client.from('animals').insert(docData);

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Wild encounter registered: ${newBird.name}!'),
            backgroundColor: Colors.teal,
          ),
        );
        navigator.pop();
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Encounter register failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Encounter Scanner', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Stack(
            children: [
              // Camera Preview or Fallback Simulator
              Positioned.fill(
                child: _isInitialized && _cameraController != null
                    ? CameraPreview(_cameraController!)
                    : Container(
                        color: Colors.grey[900],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam_off_outlined, color: Colors.teal.shade300, size: 64),
                            const SizedBox(height: 16),
                            const Text(
                              'Simulator Scanner Active',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap scanner trigger below to simulate wild capture',
                              style: TextStyle(color: Colors.grey[500], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
              ),

              // Sci-fi Target Reticle Overlay
              Positioned.fill(
                child: CustomPaint(
                  painter: ReticlePainter(),
                ),
              ),

              // Top instructions overlay
              Positioned(
                top: 24,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.teal.shade800.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.explore, color: Colors.teal, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'ALIGN WILD ANIMAL IN TARGET RETICLE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Floating Capture Trigger Button
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: FloatingActionButton.large(
                    onPressed: _isCapturing ? null : _captureEncounter,
                    backgroundColor: Colors.teal.shade600,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(
                      side: BorderSide(color: Colors.white, width: 3),
                    ),
                    child: _isCapturing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(Icons.center_focus_strong, size: 36),
                  ),
                ),
              ),

              // Fullscreen capture loading blocker
              if (_isCapturing)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.75),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.teal.shade300),
                        const SizedBox(height: 24),
                        const Text(
                          'SCANNING ANIMAL...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Capturing coordinates & analyzing attributes via AI',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.teal.shade300
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final double width = size.width;
    final double height = size.height;
    final double sizeBox = width * 0.7;
    final double left = (width - sizeBox) / 2;
    final double top = (height - sizeBox) / 2;
    final double right = left + sizeBox;
    final double bottom = top + sizeBox;

    final double cornerSize = 24.0;

    // Top-Left corner
    canvas.drawLine(Offset(left, top), Offset(left + cornerSize, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerSize), paint);

    // Top-Right corner
    canvas.drawLine(Offset(right, top), Offset(right - cornerSize, top), paint);
    canvas.drawLine(Offset(right, top), Offset(right, top + cornerSize), paint);

    // Bottom-Left corner
    canvas.drawLine(Offset(left, bottom), Offset(left + cornerSize, bottom), paint);
    canvas.drawLine(Offset(left, bottom), Offset(left, bottom - cornerSize), paint);

    // Bottom-Right corner
    canvas.drawLine(Offset(right, bottom), Offset(right - cornerSize, bottom), paint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - cornerSize), paint);

    // Center crosshairs
    final double crossSize = 12.0;
    final double centerX = width / 2;
    final double centerY = height / 2;
    canvas.drawLine(Offset(centerX - crossSize, centerY), Offset(centerX + crossSize, centerY), paint);
    canvas.drawLine(Offset(centerX, centerY - crossSize), Offset(centerX, centerY + crossSize), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
