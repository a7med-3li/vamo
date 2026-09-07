import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/vamo_button.dart';
import '../../widgets/vamo_text_field.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';

/// Login screen with phone number and password.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  late final AnimationController _animController;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();
    auth.clearError();

    final success = await auth.login(
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.bg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _animController,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Logo ──────────────────────────────
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: VamoTheme.primary.withValues(alpha: 0.25),
                                  blurRadius: 30,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                'assets/images/vamo-logo.png',
                                width: 90,
                                height: 90,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Title ──────────────────────────────
                        Text(
                          'مرحبًا بعودتك',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'سجل دخولك للبدء في استقبال الطلبات',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: context.subtitleColor,
                              ),
                        ),
                        const SizedBox(height: 32),

                        // ── Error banner ───────────────────────
                        ErrorBanner(
                          message: auth.error,
                          onDismiss: auth.clearError,
                        ),
                        if (auth.error != null) const SizedBox(height: 16),

                        // ── Phone field ────────────────────────
                        VamoTextField(
                          controller: _phoneController,
                          label: 'رقم الجوال',
                          hint: '01XXXXXXXXX',
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone_outlined,
                          textDirection: TextDirection.ltr,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'يرجى إدخال رقم الجوال.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // ── Password field ─────────────────────
                        VamoTextField(
                          controller: _passwordController,
                          label: 'كلمة المرور',
                          hint: '••••••••',
                          obscureText: _obscurePassword,
                          prefixIcon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: context.subtitleColor,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().length < 6) {
                              return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        // ── Login button ───────────────────────
                        VamoButton(
                          label: 'تسجيل الدخول',
                          icon: Icons.login_rounded,
                          isLoading: auth.isLoading,
                          onPressed: _handleLogin,
                        ),
                        const SizedBox(height: 20),

                        // ── Register link ──────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'ليس لديك حساب؟',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: context.subtitleColor,
                                  ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'إنشاء حساب سائق',
                                style: TextStyle(
                                  color: Color(0xFF4ADE80),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}