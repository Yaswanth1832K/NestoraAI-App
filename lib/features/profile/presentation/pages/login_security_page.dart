import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/notifications/domain/entities/notification_entity.dart';
import 'package:house_rental/features/notifications/presentation/providers/notification_providers.dart';
import 'package:uuid/uuid.dart';
import 'package:house_rental/core/theme/theme_provider.dart';

class LoginSecurityPage extends ConsumerStatefulWidget {
  const LoginSecurityPage({super.key});

  @override
  ConsumerState<LoginSecurityPage> createState() => _LoginSecurityPageState();
}

class _LoginSecurityPageState extends ConsumerState<LoginSecurityPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final result = await ref.read(updatePasswordUseCaseProvider).call(_passwordController.text);

    setState(() {
      _isLoading = false;
    });

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update password: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (_) {
        if (mounted) {
          // Send Security Notification
          final user = ref.read(authStateProvider).value;
          if (user != null) {
            final uuid = const Uuid();
            ref.read(addNotificationUseCaseProvider)(
              user.uid,
              NotificationEntity(
                id: uuid.v4(),
                title: "Security Alert: Password Changed",
                body: "Your account password was recently updated. If you didn't do this, please contact support.",
                timestamp: DateTime.now(),
                type: 'alert',
                isRead: false,
              ),
            );
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _passwordController.clear();
          _confirmPasswordController.clear();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Login & Security",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Change Password",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Create a new password that is at least 6 characters long.",
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: "New Password",
                  labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: "Confirm New Password",
                  labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF385C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: const Color(0xFFFF385C).withOpacity(0.5),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "Update Password",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
