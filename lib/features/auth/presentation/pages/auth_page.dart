import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:house_rental/core/router/app_router.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
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
                  context.go(AppRouter.home);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              const Center(
                child: Icon(Icons.home_work_rounded, size: 72, color: Color(0xFFFF385C)),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  "Welcome to Nestora",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  "Log in or sign up to uncover your perfect place",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDark ? Colors.grey.shade800 : Colors.white,
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: isDark ? Colors.white : Colors.black,
                  unselectedLabelColor: Colors.grey.shade600,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  tabs: const [
                    Tab(text: "Log in"),
                    Tab(text: "Sign up"),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
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
                    _buildSignupForm(isDark),
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
        _buildTextField(_loginEmailController, "Email", Icons.email_outlined, false),
        const SizedBox(height: 16),
        _buildTextField(_loginPasswordController, "Password", Icons.lock_outline, true),
        const SizedBox(height: 32),
        _buildActionButton("Continue", _handleLogin),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.go(AppRouter.home),
          child: Text(
            "Skip to explore",
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm(bool isDark) {
    return Column(
      children: [
        _buildTextField(_signupNameController, "Full Name", Icons.person_outline, false),
        const SizedBox(height: 16),
        _buildTextField(_signupEmailController, "Email", Icons.email_outlined, false),
        const SizedBox(height: 16),
        _buildTextField(_signupPasswordController, "Password", Icons.lock_outline, true),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: Text("How do you want to use Nestora?", style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade800, fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRoleButton("Travelling", 'renter', Icons.luggage_outlined, isDark),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildRoleButton("Hosting", 'owner', Icons.home_outlined, isDark),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildActionButton("Create Account", _handleSignup),
      ],
    );
  }

  Widget _buildRoleButton(String label, String role, IconData icon, bool isDark) {
    bool isSelected = _selectedRole == role;
    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFFFF385C).withOpacity(0.05) 
              : (isDark ? Colors.grey.shade900 : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFFFF385C) 
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFFFF385C) : Colors.grey.shade600, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? const Color(0xFFFF385C) 
                    : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, bool isPassword) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        filled: true,
        fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.transparent : Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.transparent : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.white : Colors.black, width: 2),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF385C),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: _isLoading ? null : onPressed,
        child: _isLoading 
          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
