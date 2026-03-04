import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:house_rental/core/router/app_router.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:uuid/uuid.dart';
import 'package:house_rental/features/notifications/domain/entities/notification_entity.dart';
import 'package:house_rental/features/notifications/presentation/providers/notification_providers.dart';

// ── Brand colors ──────────────────────────────────────────────
const _kPurple     = Color(0xFF7C5CBF);
const _kPurpleGlow = Color(0xFF9B7FD4);
const _kDarkBg     = Color(0xFF0D0D0D);
const _kCard       = Color(0xFF1C1C1C);
const _kCard2      = Color(0xFF252525);

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});
  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Login form
  final _loginEmail    = TextEditingController();
  final _loginPassword = TextEditingController();
  bool _loginPwVisible = false;

  // Signup form
  final _regName     = TextEditingController();
  final _regEmail    = TextEditingController();
  final _regPassword = TextEditingController();
  final _regConfirm  = TextEditingController();
  bool _regPwVisible = false;
  String _role       = 'renter';

  bool   _loading     = false;
  bool   _rememberMe = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _loginEmail.dispose(); _loginPassword.dispose();
    _regName.dispose(); _regEmail.dispose();
    _regPassword.dispose(); _regConfirm.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────
  Future<void> _login() async {
    if (_loginEmail.text.trim().isEmpty || _loginPassword.text.isEmpty) {
      return setState(() => _error = 'Please fill in all fields');
    }
    setState(() { _loading = true; _error = null; });
    final res = await ref.read(signInUseCaseProvider).call(
        email: _loginEmail.text.trim(), password: _loginPassword.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    res.fold(
      (f) => setState(() => _error = f.message),
      (user) {
        ref.read(addNotificationUseCaseProvider)(user.uid,
          NotificationEntity(id: const Uuid().v4(), title: 'New Login',
              body: 'A new login was detected on your account.',
              timestamp: DateTime.now(), type: 'alert', isRead: false));
        context.go(AppRouter.home);
      },
    );
  }

  Future<void> _signup() async {
    if (_regName.text.trim().isEmpty || _regEmail.text.trim().isEmpty ||
        _regPassword.text.isEmpty) {
      return setState(() => _error = 'Please fill in all fields');
    }
    if (_regPassword.text != _regConfirm.text) {
      return setState(() => _error = 'Passwords do not match');
    }
    if (_regPassword.text.length < 6) {
      return setState(() => _error = 'Password must be at least 6 characters');
    }
    setState(() { _loading = true; _error = null; });
    final res = await ref.read(signUpUseCaseProvider).call(
        email: _regEmail.text.trim(), password: _regPassword.text.trim(),
        role: _role);
    if (!mounted) return;
    setState(() => _loading = false);
    res.fold(
      (f) => setState(() => _error = f.message),
      (user) {
        ref.read(addNotificationUseCaseProvider)(user.uid,
          NotificationEntity(id: const Uuid().v4(), title: 'Welcome to Nestora!',
              body: 'Explore properties or list your own today!',
              timestamp: DateTime.now(), type: 'system', isRead: false));
        context.go(AppRouter.home);
      },
    );
  }

  void _forgotPassword() {
    final emailCtrl = TextEditingController(text: _loginEmail.text.trim());
    showDialog(context: context, builder: (_) =>
      AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Reset Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Enter your email to receive a reset link.',
              style: TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 18),
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Email address',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true, fillColor: _kCard2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _kPurple, width: 2)),
              prefixIcon: const Icon(Icons.alternate_email, color: Colors.white38, size: 18),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          GestureDetector(
            onTap: () async {
              if (emailCtrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reset link sent! Check your inbox.'),
                      backgroundColor: _kPurple));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: _kPurple, borderRadius: BorderRadius.circular(10)),
              child: const Text('Send Link', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _kDarkBg,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: SizedBox(
          width: size.width,
          child: Column(children: [
            // ── Top hero half with Background & Glass ────────────────
            _HeroSection(size: size),

            // ── Bottom form card ──
            Transform.translate(
              offset: const Offset(0, -30),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(minHeight: size.height * 0.65),
                decoration: const BoxDecoration(
                  color: _kDarkBg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
                  boxShadow: [
                    BoxShadow(color: Colors.black54, blurRadius: 40, offset: Offset(0, -10))
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 48),
                  child: Column(children: [
                    // Tab selector
                    _TabSelector(controller: _tabCtrl),
                    const SizedBox(height: 32),

                    // Error banner
                    if (_error != null) _ErrorBanner(message: _error!),

                    // Tab forms
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      child: SizedBox(
                        child: IndexedStack(
                          index: _tabCtrl.index,
                          children: [
                            _LoginForm(
                              emailCtrl: _loginEmail,
                              pwCtrl: _loginPassword,
                              pwVisible: _loginPwVisible,
                              onTogglePw: () => setState(() => _loginPwVisible = !_loginPwVisible),
                              onLogin: _loading ? null : _login,
                              onForgot: _forgotPassword,
                              onGuest: () => context.go(AppRouter.home),
                              loading: _loading,
                              rememberMe: _rememberMe,
                              onToggleRemember: () => setState(() => _rememberMe = !_rememberMe),
                            ),
                            _SignupForm(
                              nameCtrl: _regName,
                              emailCtrl: _regEmail,
                              pwCtrl: _regPassword,
                              confirmCtrl: _regConfirm,
                              pwVisible: _regPwVisible,
                              onTogglePw: () => setState(() => _regPwVisible = !_regPwVisible),
                              role: _role,
                              onRoleChange: (r) => setState(() => _role = r),
                              onSignup: _loading ? null : _signup,
                              loading: _loading,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Hero top section ───────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final Size size;
  const _HeroSection({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: size.height * 0.45,
      decoration: const BoxDecoration(
        color: _kDarkBg,
        image: DecorationImage(
          image: AssetImage('assets/images/auth_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(children: [
        // Gradient & Glass Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _kDarkBg.withOpacity(0.3),
                  _kDarkBg.withOpacity(0.7),
                  _kDarkBg,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // Content
        Positioned(
          bottom: 60, left: 32, right: 32,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Glass Box for Logo
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.home_work_rounded, size: 40, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'Nestora',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 48,
                      letterSpacing: -2,
                    ),
                  ),
                  TextSpan(
                    text: '.',
                    style: TextStyle(
                      color: _kPurpleGlow,
                      fontWeight: FontWeight.w900,
                      fontSize: 48,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Elegant Rentals. Smarter Living.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ]),
        ),

        // Status bar
        const Positioned(top: 0, left: 0, right: 0,
          child: SafeArea(child: SizedBox())),
      ]),
    );
  }
}

// ── Tab selector ───────────────────────────────────────────────
class _TabSelector extends StatelessWidget {
  final TabController controller;
  const _TabSelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: _kCard2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kPurple.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(color: _kPurple.withOpacity(0.2), blurRadius: 10)
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.8),
        tabs: const [Tab(text: 'SIGN IN'), Tab(text: 'SIGN UP')],
      ),
    );
  }
}

// ── Error banner ───────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(message,
            style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

// ── Text field helper ──────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboard;

  const _Field({required this.ctrl, required this.hint, required this.icon,
    this.obscure = false, this.suffix, this.keyboard});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboard,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.white30, size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: _kCard,
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.transparent)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _kPurple, width: 2)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }
}

// ── Primary button ─────────────────────────────────────────────
class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const _PrimaryBtn({required this.label, required this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity, height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kPurple, _kPurpleGlow],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: _kPurple.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))
          ],
        ),
        child: loading
            ? const SizedBox(width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
            : Text(label, style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
      ),
    );
  }
}

// ── Social divider ─────────────────────────────────────────────
Widget _orDivider() => const Row(children: [
  Expanded(child: Divider(color: Colors.white10, thickness: 1.5)),
  Padding(padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text('OR CONTINUE WITH', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5))),
  Expanded(child: Divider(color: Colors.white10, thickness: 1.5)),
]);

// ── Social button ──────────────────────────────────────────────
class _SocialBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _SocialBtn({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 24, color: Colors.white),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  LOGIN FORM
// ══════════════════════════════════════════════════════════════
class _LoginForm extends StatelessWidget {
  final TextEditingController emailCtrl, pwCtrl;
  final bool pwVisible, loading, rememberMe;
  final VoidCallback onTogglePw, onForgot, onGuest, onToggleRemember;
  final VoidCallback? onLogin;

  const _LoginForm({
    required this.emailCtrl, required this.pwCtrl,
    required this.pwVisible, required this.onTogglePw,
    required this.onLogin, required this.onForgot,
    required this.onGuest, required this.loading,
    required this.rememberMe, required this.onToggleRemember,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.only(left: 4, bottom: 8),
        child: Text('EMAIL ADDRESS', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
      _Field(ctrl: emailCtrl, hint: 'hello@example.com',
          icon: Icons.alternate_email_rounded, keyboard: TextInputType.emailAddress),

      const SizedBox(height: 20),
      const Padding(
        padding: EdgeInsets.only(left: 4, bottom: 8),
        child: Text('PASSWORD', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
      _Field(
        ctrl: pwCtrl, hint: '••••••••',
        icon: Icons.lock_rounded, obscure: !pwVisible,
        suffix: IconButton(
          icon: Icon(pwVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              size: 20, color: Colors.white30),
          onPressed: onTogglePw,
        ),
      ),

      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SizedBox(
                height: 24, width: 24,
                child: Checkbox(
                  value: rememberMe,
                  onChanged: (v) => onToggleRemember(),
                  fillColor: MaterialStateProperty.resolveWith((states) => 
                    states.contains(MaterialState.selected) ? _kPurple : Colors.white10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Remember Me', style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          TextButton(
            onPressed: onForgot,
            child: const Text('Forgot Password?',
                style: TextStyle(color: _kPurpleGlow, fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ],
      ),

      const SizedBox(height: 24),
      _PrimaryBtn(label: 'SIGN IN', onTap: onLogin, loading: loading),
      const SizedBox(height: 24),
      Center(
        child: TextButton(
          onPressed: onGuest,
          child: const Text('Continue as Guest →',
              style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w700, fontSize: 14)),
        ),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
//  SIGN UP FORM
// ══════════════════════════════════════════════════════════════
class _SignupForm extends StatelessWidget {
  final TextEditingController nameCtrl, emailCtrl, pwCtrl, confirmCtrl;
  final bool pwVisible, loading;
  final String role;
  final VoidCallback onTogglePw;
  final ValueChanged<String> onRoleChange;
  final VoidCallback? onSignup;

  const _SignupForm({
    required this.nameCtrl, required this.emailCtrl,
    required this.pwCtrl, required this.confirmCtrl,
    required this.pwVisible, required this.onTogglePw,
    required this.role, required this.onRoleChange,
    required this.onSignup, required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.only(left: 4, bottom: 8),
        child: Text('FULL NAME', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
      _Field(ctrl: nameCtrl, hint: 'What should we call you?', icon: Icons.person_rounded),

      const SizedBox(height: 20),
      const Padding(
        padding: EdgeInsets.only(left: 4, bottom: 8),
        child: Text('EMAIL ADDRESS', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
      _Field(ctrl: emailCtrl, hint: 'hello@example.com',
          icon: Icons.alternate_email_rounded, keyboard: TextInputType.emailAddress),

      const SizedBox(height: 20),
      const Padding(
        padding: EdgeInsets.only(left: 4, bottom: 8),
        child: Text('PASSWORD', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
      _Field(
        ctrl: pwCtrl, hint: 'Min. 6 characters',
        icon: Icons.lock_rounded, obscure: !pwVisible,
        suffix: IconButton(
          icon: Icon(pwVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              size: 20, color: Colors.white30),
          onPressed: onTogglePw,
        ),
      ),

      const SizedBox(height: 24),
      const Text('JOIN AS', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _RoleChip(selected: role == 'renter', label: 'Tenant',
            icon: Icons.home_rounded, onTap: () => onRoleChange('renter'))),
        const SizedBox(width: 16),
        Expanded(child: _RoleChip(selected: role == 'owner', label: 'Owner',
            icon: Icons.vpn_key_rounded, onTap: () => onRoleChange('owner'))),
      ]),

      const SizedBox(height: 32),
      _PrimaryBtn(label: 'CREATE ACCOUNT', onTap: onSignup, loading: loading),
      const SizedBox(height: 24),

      const Center(
        child: Text('By creating an account you agree to our Terms & Privacy Policy',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white24, fontSize: 11)),
      ),
    ]);
  }
}

// ── Role chip ──────────────────────────────────────────────────
class _RoleChip extends StatelessWidget {
  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleChip({required this.selected, required this.label,
      required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 60,
        decoration: BoxDecoration(
          color: selected ? _kPurple.withOpacity(0.1) : _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _kPurple : Colors.white.withOpacity(0.05), width: 2),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 20, color: selected ? _kPurpleGlow : Colors.white24),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontWeight: FontWeight.w800,
              color: selected ? Colors.white : Colors.white24, fontSize: 14)),
        ]),
      ),
    );
  }
}
