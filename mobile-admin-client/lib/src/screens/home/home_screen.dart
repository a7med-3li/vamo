import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/vamo_button.dart';
import '../auth/login_screen.dart';
import '../corridors/corridors_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../corridors/add_corridor_screen.dart';
import '../subscriptions/pending_subscriptions_screen.dart';
import '../fare_configs/fare_configs_screen.dart';
import '../drivers/pending_drivers_screen.dart';

/// Main dashboard shown after login.
///
/// Contains a top action menu, notifications bell, bottom navigation,
/// and a focused Home view featuring Today's Ride and QR Boarding Pass.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  /// Public method to switch tabs from child widgets.
  void switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.bg,
        appBar: _buildAppBar(context),
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            _DashboardTab(),
            CorridorsScreen(),
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.bg,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: VamoTheme.accent.withValues(alpha: 0.15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: SvgPicture.asset(
                  'assets/images/vamo_logo.svg',
                  width: 24,
                  height: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Vamo',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
          ),
        ],
      ),
      actions: [
        // ── Theme Switcher Button (Sun / Moon) ─────────────────
        Builder(
          builder: (context) {
            final themeProvider = context.watch<ThemeProvider>();
            final isDark = themeProvider.isDark;
            return IconButton(
              onPressed: () => context.read<ThemeProvider>().toggleTheme(),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                ),
              ),
              icon: Icon(
                isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                color: isDark ? const Color(0xFFFACC15) : const Color(0xFF05472A),
                size: 22,
              ),
              tooltip: isDark ? 'الوضع المضيء' : 'الوضع الداكن',
            );
          },
        ),
        const SizedBox(width: 8),

        // ── Notification Bell Icon with Badge ──────────────────
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
          style: IconButton.styleFrom(
            backgroundColor: context.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: context.cardBorderColor),
            ),
          ),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_outlined,
                color: context.titleColor,
                size: 22,
              ),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: VamoTheme.alert,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // ── Hamburger Menu (3 lines instead of 3 dots) ─────────
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuSelection(context, value),
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.cardBorderColor),
            ),
            child: Icon(
              Icons.menu_rounded,
              color: context.titleColor,
              size: 22,
            ),
          ),
          color: context.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: context.cardBorderColor),
          ),
          position: PopupMenuPosition.under,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline_rounded,
                      color: context.subtitleColor, size: 20),
                  const SizedBox(width: 12),
                  const Text('الملف الشخصي',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const PopupMenuDivider(height: 1),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded,
                      color: Color(0xFFF87171), size: 20),
                  SizedBox(width: 12),
                  Text('تسجيل الخروج',
                      style: TextStyle(
                        color: Color(0xFFF87171),
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'profile':
        switchTab(2);
        break;
      case 'logout':
        _confirmLogout(context);
        break;
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: VamoTheme.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تسجيل الخروج',
              style: TextStyle(fontWeight: FontWeight.w800)),
          content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج من حسابك؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء',
                  style: TextStyle(color: Color(0xFFA0A0A0))),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final auth = context.read<AuthProvider>();
                await auth.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
              style:
                  FilledButton.styleFrom(backgroundColor: const Color(0xFFB91C1C)),
              child: const Text('تسجيل الخروج'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(top: BorderSide(color: context.cardBorderColor)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.dashboard_rounded, 'الرئيسية'),
              _navItem(1, Icons.route_rounded, 'إدارة المسارات'),
              _navItem(2, Icons.person_outline_rounded, 'حسابي'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? VamoTheme.accent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? VamoTheme.accent : context.subtitleColor,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: VamoTheme.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The "Home" tab content — Admin Dashboard focused on managing the system.
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Greeting Card ──────────────────────────────────
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF05472A), Color(0xFF0A6B3E)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: VamoTheme.accent.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      auth.displayName.isNotEmpty
                          ? auth.displayName[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرحبًا، ${auth.displayName} 👋',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'لوحة تحكم الإدارة - Vamo Admin',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: context.subtitleColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Admin Quick Actions ─────────────────────────────
            Text('إجراءات سريعة', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF05472A), Color(0xFF081A19)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF166534).withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: VamoTheme.accent.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: VamoTheme.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.add_road_rounded,
                      color: VamoTheme.accent,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'إضافة مسار جديد',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'قم بتكوين مسار جديد للنظام، متضمناً المحطات وتكلفة الاشتراك.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF9E9E9E),
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddCorridorScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VamoTheme.accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.add_rounded, color: Colors.black),
                      label: const Text(
                        'إضافة مسار',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: VamoButton(
                    label: 'الطلبات المعلقة',
                    icon: Icons.pending_actions_rounded,
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PendingSubscriptionsScreen()));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: VamoButton(
                    label: 'عرض وإدارة المسارات',
                    icon: Icons.list_alt_rounded,
                    onPressed: () {
                      final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                      homeState?.switchTab(1);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            VamoButton(
              label: 'إدارة أسعار الرحلات',
              icon: Icons.payments_outlined,
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FareConfigsScreen()));
              },
            ),
            const SizedBox(height: 12),
            VamoButton(
              label: 'طلبات السائقين المعلقة',
              icon: Icons.directions_car_filled_rounded,
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PendingDriversScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
