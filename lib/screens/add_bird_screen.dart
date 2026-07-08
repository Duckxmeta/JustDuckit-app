import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bird.dart';

class AddBirdScreen extends StatefulWidget {
  const AddBirdScreen({super.key});

  @override
  State<AddBirdScreen> createState() => _AddBirdScreenState();
}

class _AddBirdScreenState extends State<AddBirdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  String _selectedBreed = 'Pekin Duck';
  String _selectedSex = 'Unknown';
  String _selectedOrigin = 'Hatched';
  DateTime _hatchDate = DateTime.now();
  
  XFile? _pickedFile;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  final List<String> _breeds = [
    'Pekin Duck',
    'Muscovy Duck',
    'Runner Duck',
    'Khaki Campbell',
    'Cayuga Duck',
    'Call Duck',
    'Swedish Blue',
    'Other'
  ];

  final List<String> _sexes = ['Male', 'Female', 'Unknown'];
  final List<String> _origins = ['Purchased', 'Rehomed', 'Hatched'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _hatchDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 15)), // Birds can live up to 15 years
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.teal),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _hatchDate) {
      setState(() {
        _hatchDate = picked;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _pickedFile = image;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveBird() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be signed in to add birds to your flock.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final birdDocRef = FirebaseFirestore.instance.collection('birds').doc();
      final birdId = birdDocRef.id;
      String? photoUrl;

      // Upload image if selected
      if (_imageBytes != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('users/${user.uid}/birds/$birdId.jpg');
        
        final uploadTask = storageRef.putData(
          _imageBytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        
        final snapshot = await uploadTask;
        photoUrl = await snapshot.ref.getDownloadURL();
      }

      final newBird = Bird(
        id: birdId,
        name: _nameController.text.trim(),
        breed: _selectedBreed,
        ageOrHatchDate: _hatchDate,
        sex: _selectedSex,
        originType: _selectedOrigin,
        photoUrl: photoUrl,
        uid: user.uid,
        serialNumber: 'Batch #${(DateTime.now().millisecondsSinceEpoch % 1000).toString().padLeft(3, '0')}',
        flockGrade: 9.0,
        geneticTraits: const ['Flock Pioneer'],
        cardVariant: photoUrl != null ? 'Holo' : 'Standard',
      );

      await birdDocRef.set(newBird.toFirestore());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${newBird.name} to your flock!'),
            backgroundColor: Colors.teal,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving bird: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Bird'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker UI
              Center(
                child: GestureDetector(
                  onTap: _showImageSourceBottomSheet,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 64,
                        backgroundColor: Colors.teal.shade50,
                        backgroundImage: _imageBytes != null ? MemoryImage(_imageBytes!) : null,
                        child: _imageBytes == null
                            ? Icon(Icons.add_a_photo, size: 36, color: Colors.teal.shade700)
                            : null,
                      ),
                      if (_imageBytes != null)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.teal,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _imageBytes == null ? 'Upload Profile Photo' : 'Change Profile Photo',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
              const SizedBox(height: 24),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Quackers',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.drive_file_rename_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name for this bird';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Breed Dropdown
              DropdownButtonFormField<String>(
                value: _selectedBreed,
                decoration: const InputDecoration(
                  labelText: 'Breed',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pets),
                ),
                items: _breeds.map((breed) {
                  return DropdownMenuItem(
                    value: breed,
                    child: Text(breed),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedBreed = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Sex Dropdown
              DropdownButtonFormField<String>(
                value: _selectedSex,
                decoration: const InputDecoration(
                  labelText: 'Sex',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wc),
                ),
                items: _sexes.map((sex) {
                  return DropdownMenuItem(
                    value: sex,
                    child: Text(sex),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedSex = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Hatch Date / Age Picker
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Hatch Date / Birth Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.cake),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(_hatchDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.calendar_month, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Origin Dropdown
              DropdownButtonFormField<String>(
                value: _selectedOrigin,
                decoration: const InputDecoration(
                  labelText: 'Origin Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.source),
                ),
                items: _origins.map((origin) {
                  return DropdownMenuItem(
                    value: origin,
                    child: Text(origin),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedOrigin = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveBird,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Bird',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
