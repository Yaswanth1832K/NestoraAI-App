import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
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

  XFile? _pickedFile;         // Platform-agnostic picked file
  Uint8List? _webImageBytes;  // For web preview + upload
  File? _nativeImageFile;     // For native preview + upload
  String? _currentPhotoUrl;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).value;
    _nameController  = TextEditingController(text: user?.displayName ?? '');
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

  // ── Image picking ─────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    if (kIsWeb) {
      // Web: read bytes directly — File() does not work on web
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _pickedFile     = pickedFile;
        _webImageBytes  = bytes;
        _nativeImageFile = null;
      });
    } else {
      setState(() {
        _pickedFile      = pickedFile;
        _nativeImageFile = File(pickedFile.path);
        _webImageBytes   = null;
      });
    }
  }

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: const Text('Choose from Gallery',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded,
                    color: AppColors.primary),
                title: const Text('Take a Photo',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  if (kIsWeb) {
                    _pickImage(ImageSource.camera);
                  } else {
                    var status = await Permission.camera.status;
                    if (!status.isGranted) {
                      status = await Permission.camera.request();
                    }
                    if (status.isGranted) {
                      _pickImage(ImageSource.camera);
                    } else if (status.isPermanentlyDenied && mounted) {
                      showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Camera Permission Required'),
                          content: const Text(
                              'Please enable camera access in settings.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(c),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(c);
                                  openAppSettings();
                                },
                                child: const Text('Settings')),
                          ],
                        ),
                      );
                    }
                  }
                },
              ),
              if (_currentPhotoUrl != null || _pickedFile != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent),
                  title: const Text('Remove Photo',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: Colors.redAccent)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() {
                      _pickedFile      = null;
                      _webImageBytes   = null;
                      _nativeImageFile = null;
                      _currentPhotoUrl = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Upload ────────────────────────────────────────────────────

  Future<String?> _uploadImage(String userId) async {
    // No new image selected — return existing URL (could be null if removed)
    if (_pickedFile == null) return _currentPhotoUrl;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_profiles')
          .child('$userId.jpg');

      UploadTask uploadTask;

      if (kIsWeb && _webImageBytes != null) {
        // Web upload via bytes
        uploadTask = storageRef.putData(
          _webImageBytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else if (_nativeImageFile != null) {
        // Native upload via File
        uploadTask = storageRef.putFile(_nativeImageFile!);
      } else {
        return _currentPhotoUrl;
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
      return null;
    }
  }

  // ── Email update ──────────────────────────────────────────────

  Future<void> _updateEmail(User user, String newEmail) async {
    if (user.email == newEmail) return;
    try {
      await user.verifyBeforeUpdateEmail(newEmail);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Verify Email',
                style: TextStyle(fontWeight: FontWeight.w900)),
            content: Text(
                'A verification email has been sent to $newEmail. Please verify it to complete the update.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update email: $e')),
        );
      }
    }
  }

  // ── Save ──────────────────────────────────────────────────────

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    // 1. Upload image (returns new URL, existing URL, or null if removed)
    final String? photoURL = await _uploadImage(user.uid);

    // 2. Update email
    await _updateEmail(user, _emailController.text.trim());

    // 3. Update display name + photo in Auth + Firestore
    final result = await ref.read(updateProfileUseCaseProvider).call(
          displayName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          photoURL: photoURL,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to update profile: ${failure.message}')),
      ),
      (_) {
        // Push notification
        const uuid = Uuid();
        ref.read(addNotificationUseCaseProvider)(
          user.uid,
          NotificationEntity(
            id: uuid.v4(),
            title: 'Profile Updated',
            body: 'Your profile information has been successfully updated.',
            timestamp: DateTime.now(),
            type: 'system',
            isRead: false,
          ),
        );

        // Evict old avatar from Flutter's image cache so profile page
        // immediately shows the newly uploaded photo, not the cached stale one.
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully ✓'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      },
    );
  }

  // ── Avatar preview ────────────────────────────────────────────

  ImageProvider? _previewImage() {
    if (kIsWeb && _webImageBytes != null) {
      return MemoryImage(_webImageBytes!);
    }
    if (!kIsWeb && _nativeImageFile != null) {
      return FileImage(_nativeImageFile!);
    }
    if (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty) {
      return NetworkImage(_currentPhotoUrl!);
    }
    return null;
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preview = _previewImage();
    final hasImage = preview != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Avatar ───────────────────────────────────────
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _showImagePickerOptions,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary
                                .withOpacity(hasImage ? 0.6 : 0.2),
                            width: 3,
                          ),
                          boxShadow: hasImage
                              ? [
                                  BoxShadow(
                                      color: AppColors.primary
                                          .withOpacity(0.25),
                                      blurRadius: 16,
                                      spreadRadius: 2)
                                ]
                              : [],
                        ),
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: isDark
                              ? Colors.white10
                              : Colors.black.withOpacity(0.05),
                          backgroundImage: preview,
                          child: !hasImage
                              ? Icon(Icons.person_rounded,
                                  size: 56,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black26)
                              : null,
                        ),
                      ),
                    ),
                    // Camera badge
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Pick photo hint
              Text(
                'Tap to change photo',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 32),

              // ── Name ─────────────────────────────────────────
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Name cannot be empty' : null,
              ),
              const SizedBox(height: 16),

              // ── Email ─────────────────────────────────────────
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (v) => v == null || !v.contains('@')
                    ? 'Invalid email'
                    : null,
              ),
              const SizedBox(height: 16),

              // ── Phone ─────────────────────────────────────────
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number (optional)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 36),

              // ── Save button ───────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _updateProfile,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Save Changes',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
