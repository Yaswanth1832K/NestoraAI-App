import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:house_rental/core/router/app_router.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/core/services/notification_service.dart';
import 'package:house_rental/features/auth/domain/entities/user_entity.dart';
import 'package:uuid/uuid.dart';
import 'package:house_rental/features/notifications/domain/entities/notification_entity.dart';
import 'package:house_rental/features/notifications/presentation/providers/notification_providers.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupNameController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedRole = 'renter';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupNameController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ref.read(signInUseCaseProvider).call(
      email: _loginEmailController.text.trim(),
      password: _loginPasswordController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      result.fold(
        (failure) => setState(() => _errorMessage = failure.message),
        (user) {
          // Send Login Notification
          if (user != null) {
            final uuid = const Uuid();
            ref.read(addNotificationUseCaseProvider)(
              user.uid,
              NotificationEntity(
                id: uuid.v4(),
                title: "New Login",
                body: "A new login was detected on your account.",
                timestamp: DateTime.now(),
                type: 'alert',
                isRead: false,
              ),
            );
          }
          context.go(AppRouter.home);
        },
      );
    }
  }

  Future<void> _handleSignup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ref.read(signUpUseCaseProvider).call(
      email: _signupEmailController.text.trim(),
      password: _signupPasswordController.text.trim(),
      role: _selectedRole,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      result.fold(
        (failure) => setState(() => _errorMessage = failure.message),
        (user) {
          // Send Welcome Notification
          if (user != null) {
             final uuid = const Uuid();
             ref.read(addNotificationUseCaseProvider)(
              user.uid,
              NotificationEntity(
                id: uuid.v4(),
                title: "Welcome to Nestora!",
                body: "We're excited to have you on board. Explore properties or list your own today!",
                timestamp: DateTime.now(),
                type: 'system',
                isRead: false,
              ),
            );
          }
          context.go(AppRouter.home);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Center(
                child: Icon(Icons.home_work_rounded, size: 80, color: Colors.blueAccent),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  "Nestora",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const Center(
                child: Text(
                  "Your dream home is just a click away",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
              const SizedBox(height: 48),
              
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.blueAccent,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: "Sign In"),
                    Tab(text: "Sign Up"),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),

              SizedBox(
                height: 400,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Login Tab
                    _buildLoginForm(),
                    // Signup Tab
                    _buildSignupForm(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        _buildTextField(_loginEmailController, "Email", Icons.email_outlined),
        const SizedBox(height: 16),
        _buildTextField(_loginPasswordController, "Password", Icons.lock_outline, isPassword: true),
        const SizedBox(height: 32),
        _buildActionButton("Sign In", _handleLogin),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.go(AppRouter.home),
          child: const Text("Continue as Guest", style: TextStyle(color: Colors.blueAccent)),
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Column(
      children: [
        _buildTextField(_signupNameController, "Full Name", Icons.person_outline),
        const SizedBox(height: 16),
        _buildTextField(_signupEmailController, "Email", Icons.email_outlined),
        const SizedBox(height: 16),
        _buildTextField(_signupPasswordController, "Password", Icons.lock_outline, isPassword: true),
        const SizedBox(height: 24),
        const Text("I am a:", style: TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRoleButton("Renter", 'renter', Icons.person_outline),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildRoleButton("Owner", 'owner', Icons.home_work_outlined),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildActionButton("Create Account", _handleSignup),
      ],
    );
  }

  Widget _buildRoleButton(String label, String role, IconData icon) {
    bool isSelected = _selectedRole == role;
    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent.withOpacity(0.1) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.blueAccent : Colors.grey),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blueAccent : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        onPressed: _isLoading ? null : onPressed,
        child: _isLoading 
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
