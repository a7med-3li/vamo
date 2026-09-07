import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/vamo_button.dart';
import '../../widgets/vamo_text_field.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

/// Registration screen for new drivers.
///
/// Uses the `registerDriver` endpoint with national ID and license number.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedGender = 'MALE';
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    _licenseNumberController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();
    auth.clearError();

    final success = await auth.registerDriver(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      gender: _selectedGender,
      nationalId: _nationalIdController.text.trim(),
      licenseNumber: _licenseNumberController.text.trim(),
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
                                width: 80,
                                height: 80,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Title ──────────────────────────────
                        Text(
                          'إنشاء حساب سائق',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'سجل بياناتك لبدء استقبال طلبات الركوب',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: context.subtitleColor,
                              ),
                        ),
                        const SizedBox(height: 28),

                        // ── Error banner ───────────────────────
                        ErrorBanner(
                          message: auth.error,
                          onDismiss: auth.clearError,
                        ),
                        if (auth.error != null) const SizedBox(height: 16),

                        // ── First name ─────────────────────────
                        VamoTextField(
                          controller: _firstNameController,
                          label: 'الاسم الأول',
                          hint: 'أحمد',
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (value) {
                            if (value == null || value.trim().length < 2) {
                              return 'الاسم الأول يجب أن يكون حرفين على الأقل.';
                            }
                            if (value.trim().length > 50) {
                              return 'الاسم الأول لا يتجاوز 50 حرف.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // ── Last name ──────────────────────────
                        VamoTextField(
                          controller: _lastNameController,
                          label: 'اسم العائلة',
                          hint: 'محمد',
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (value) {
                            if (value == null || value.trim().length < 2) {
                              return 'اسم العائلة يجب أن يكون حرفين على الأقل.';
                            }
                            if (value.trim().length > 50) {
                              return 'اسم العائلة لا يتجاوز 50 حرف.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // ── Phone ──────────────────────────────
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
                            final regex = RegExp(r'^[+]?[0-9]{10,15}$');
                            if (!regex.hasMatch(value.trim())) {
                              return 'رقم الجوال غير صالح (10-15 رقم).';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // ── Gender ─────────────────────────────
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'الجنس',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: context.subtitleColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              decoration: BoxDecoration(
                                color: context.fieldColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: context.cardBorderColor),
                              ),
                              child: Row(
                                children: [
                                  _genderOption('MALE', 'ذكر', Icons.male_rounded),
                                  const SizedBox(width: 8),
                                  _genderOption('FEMALE', 'أنثى', Icons.female_rounded),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ── National ID ────────────────────────
                        VamoTextField(
                          controller: _nationalIdController,
                          label: 'الرقم القومي',
                          hint: 'XXXXXXXXXXXXXXX',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.badge_outlined,
                          textDirection: TextDirection.ltr,
                          validator: (value) {
                            if (value == null || value.trim().length < 5) {
                              return 'الرقم القومي يجب أن يكون 5 أرقام على الأقل.';
                            }
                            if (value.trim().length > 50) {
                              return 'الرقم القومي لا يتجاوز 50 رقم.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // ── License number ─────────────────────
                        VamoTextField(
                          controller: _licenseNumberController,
                          label: 'رقم رخصة القيادة',
                          hint: 'XXXXXXXXXX',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.credit_card_rounded,
                          textDirection: TextDirection.ltr,
                          validator: (value) {
                            if (value == null || value.trim().length < 5) {
                              return 'رقم الرخصة يجب أن يكون 5 أحرف على الأقل.';
                            }
                            if (value.trim().length > 50) {
                              return 'رقم الرخصة لا يتجاوز 50 حرف.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // ── Password ───────────────────────────
                        VamoTextField(
                          controller: _passwordController,
                          label: 'كلمة المرور',
                          hint: '6 أحرف على الأقل',
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
                            if (value.trim().length > 128) {
                              return 'كلمة المرور لا تتجاوز 128 حرف.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        // ── Register button ────────────────────
                        VamoButton(
                          label: 'إنشاء الحساب',
                          icon: Icons.person_add_alt_1_rounded,
                          isLoading: auth.isLoading,
                          onPressed: _handleRegister,
                        ),
                        const SizedBox(height: 20),

                        // ── Login link ─────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'لديك حساب بالفعل؟',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: context.subtitleColor,
                                  ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'تسجيل الدخول',
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

  Widget _genderOption(String value, String label, IconData icon) {
    final isSelected = _selectedGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? VamoTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : context.subtitleColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : context.subtitleColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}