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
import 'package:house_rental/core/widgets/glass_container.dart';

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
    final user = ref.read(currentUserProvider).value;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _currentPhotoUrl = user?.photoUrl;
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
        debugPrint("UploadImage: Starting putData upload (Web)...");
        uploadTask = storageRef.putData(
          _webImageBytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else if (_nativeImageFile != null) {
        // Native upload via File
        debugPrint("UploadImage: Starting putFile upload (Native)...");
        uploadTask = storageRef.putFile(_nativeImageFile!);
      } else {
        debugPrint("UploadImage: No new image data found.");
        return _currentPhotoUrl;
      }

      // Listen to progress
      uploadTask.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          final progress = 100 * (snapshot.bytesTransferred / snapshot.totalBytes);
          debugPrint("UploadImage: Progress ${progress.toStringAsFixed(2)}% (${snapshot.state})");
        },
        onError: (e) => debugPrint("UploadImage: Snapshot error: $e"),
      );

      // Wait for completion with timeout
      debugPrint("UploadImage: Waiting for snapshot...");
      final snapshot = await uploadTask.timeout(const Duration(seconds: 30));
      debugPrint("UploadImage: Snapshot received. Getting URL...");
      
      final url = await snapshot.ref.getDownloadURL().timeout(const Duration(seconds: 15));
      debugPrint("UploadImage: URL successfully retrieved.");
      return url;
    } catch (e) {
      debugPrint("UploadImage: EXCEPTION: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
      return null; // Safety: return null so we don't proceed with broken URL
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
    debugPrint("ProfileUpdate: Starting update process...");

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint("ProfileUpdate: No user found! Aborting.");
        setState(() => _isLoading = false);
        return;
      }

      // 1. Upload image (returns new URL, existing URL, or null if removed)
      debugPrint("ProfileUpdate: Uploading image...");
      final String? photoURL = await _uploadImage(user.uid);
      debugPrint("ProfileUpdate: Image upload result: ${photoURL != null ? 'URL received' : 'Null'}");

      // 2. Update email
      debugPrint("ProfileUpdate: Checking email update...");
      await _updateEmail(user, _emailController.text.trim());

      // 3. Update display name + photo in Auth + Firestore
      debugPrint("ProfileUpdate: Calling updateProfileUseCase...");
      final result = await ref.read(updateProfileUseCaseProvider).call(
            displayName: _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            photoURL: photoURL,
          );

      if (!mounted) return;

      result.fold(
        (failure) {
          debugPrint("ProfileUpdate: UseCase failed: ${failure.message}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: ${failure.message}')),
          );
        },
        (_) {
          debugPrint("ProfileUpdate: Success! Finalizing...");
          // Evict old avatar from cache
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully ✓'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Wait a tiny bit for the provider to update via Firestore stream
          // before popping, to avoid stale data flicker
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) context.pop();
          });
        },
      );
    } catch (e, stack) {
      debugPrint("ProfileUpdate: UNEXPECTED ERROR: $e");
      debugPrint(stack.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint("ProfileUpdate: Loading state reset.");
      }
    }
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
    final user = ref.watch(currentUserProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final preview = _previewImage();
    final hasImage = preview != null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Personal Information',
            style: TextStyle(fontWeight: FontWeight.w900, color: textColor, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
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
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: isDark
                                    ? Colors.white10
                                    : Colors.black.withOpacity(0.05),
                                backgroundImage: preview,
                                child: !hasImage
                                    ? Icon(Icons.person_rounded,
                                        size: 60,
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.black26)
                                    : null,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: GlassContainer.standard(
                              context: context,
                              borderRadius: 20,
                              padding: const EdgeInsets.all(8),
                              child: const Icon(Icons.camera_alt_rounded,
                                  color: AppColors.primary, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    Text(
                      'Change profile photo',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 40),

                    GlassContainer.standard(
                      context: context,
                      padding: const EdgeInsets.all(24),
                      borderRadius: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldHeader('FULL NAME', isDark),
                          TextFormField(
                            controller: _nameController,
                            style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
                            decoration: _inputDecoration('Enter your name', Icons.person_outline_rounded, isDark),
                            validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
                          ),
                          const SizedBox(height: 24),
                          _buildFieldHeader('EMAIL ADDRESS', isDark),
                          TextFormField(
                            controller: _emailController,
                            style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
                            decoration: _inputDecoration('Enter email', Icons.email_outlined, isDark),
                            validator: (v) => v == null || !v.contains('@') ? 'Invalid email' : null,
                          ),
                          const SizedBox(height: 24),
                          _buildFieldHeader('PHONE NUMBER', isDark),
                          TextFormField(
                            controller: _phoneController,
                            style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
                            decoration: _inputDecoration('Optional', Icons.phone_outlined, isDark),
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── Save button ───────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                          shadowColor: AppColors.primary.withOpacity(0.5),
                        ),
                        onPressed: _isLoading ? null : _updateProfile,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 3),
                              )
                            : const Text('Save Changes',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldHeader(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white38 : Colors.black38,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
      prefixIcon: Icon(icon, color: isDark ? Colors.white54 : Colors.black54, size: 20),
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5), width: 1.5),
      ),
    );
  }
}
