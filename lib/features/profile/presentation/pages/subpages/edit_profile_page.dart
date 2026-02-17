import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/core/theme/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:house_rental/features/notifications/domain/entities/notification_entity.dart';
import 'package:house_rental/features/notifications/presentation/providers/notification_providers.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  // late TextEditingController _photoController; // No longer needed as we use file
  
  File? _imageFile;
  String? _currentPhotoUrl;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).value;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? ''); 
    _emailController = TextEditingController(text: user?.email ?? '');
    _currentPhotoUrl = user?.photoURL;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.of(context).pop();
                
                // Request camera permission
                var status = await Permission.camera.status;
                if (!status.isGranted) {
                  status = await Permission.camera.request();
                }

                if (status.isGranted) {
                  _pickImage(ImageSource.camera);
                } else if (status.isPermanentlyDenied) {
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Camera Permission Required"),
                        content: const Text("Please enable camera access in settings to take a photo."),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              openAppSettings();
                            },
                            child: const Text("Settings"),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImage(String userId) async {
    if (_imageFile == null) return _currentPhotoUrl;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_profiles')
          .child('$userId.jpg');
      
      await storageRef.putFile(_imageFile!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image: $e")),
      );
      return null;
    }
  }

  Future<void> _updateEmail(User user, String newEmail) async {
    if (user.email == newEmail) return;

    try {
      await user.verifyBeforeUpdateEmail(newEmail);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Verify Email"),
            content: Text("A verification email has been sent to $newEmail. Please verify it to complete the update."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
            ],
          ),
        );
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update email: $e")),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Upload Image if changed
    String? photoURL = await _uploadImage(user.uid);

    // 2. Update Email if changed
    await _updateEmail(user, _emailController.text.trim());
    
    // 3. Update Profile Data
    final result = await ref.read(updateProfileUseCaseProvider).call(
      displayName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      photoURL: photoURL,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update profile: ${failure.message}")),
        );
      },
      (_) {
        // Send Notification
        final uuid = const Uuid();
        ref.read(addNotificationUseCaseProvider)(
          user.uid,
          NotificationEntity(
            id: uuid.v4(),
            title: "Profile Updated",
            body: "Your profile information has been successfully updated.",
            timestamp: DateTime.now(),
            type: 'system',
            isRead: false,
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // We can assume user is logged in if they reached here, or handle null nicely
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _showImagePickerOptions,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (_currentPhotoUrl != null ? NetworkImage(_currentPhotoUrl!) : null) as ImageProvider?,
                        child: (_imageFile == null && _currentPhotoUrl == null)
                            ? const Icon(Icons.person, size: 50, color: Colors.grey)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Display Name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (v) => v == null || v.isEmpty ? "Name cannot be empty" : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email Address",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (v) => v == null || !v.contains('@') ? "Invalid email" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _updateProfile,
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
