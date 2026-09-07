import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../../data/models/ride_request.dart';
import '../../providers/theme_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/vamo_button.dart';
import '../auth/login_screen.dart';

/// Main driver dashboard.
///
/// Contains a large Active/Inactive (on-shift) toggle. When the driver is
/// active, a list of pending ride requests is shown, each with an
/// accept button (placeholder until the backend endpoint is implemented).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverProvider>().loadProfile();
    });
  }

  Future<void> _onToggleShift(BuildContext context) async {
    final driver = context.read<DriverProvider>();

    // Re-fetch the profile first so an admin approval/rejection is picked
    // up from the server without needing to restart the app.
    await driver.loadProfile();
    if (!context.mounted) return;

    if (!driver.canToggle) {
      ScaffoldMessenger.of(context).showSnackBar(
        _statusSnackBar('حسابك لم تتم الموافقة عليه بعد. انتظر اعتماد الإدارة.'),
      );
      return;
    }

    await driver.toggleShift();

    if (driver.toggleError != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(_statusSnackBar(driver.toggleError!));
      }
    }
  }

  SnackBar _statusSnackBar(String message) {
    return SnackBar(
      content: Text(message, textAlign: TextAlign.center),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: context.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تسجيل الخروج',
              style: TextStyle(fontWeight: FontWeight.w800)),
          content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج من حسابك؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء',
                  style: TextStyle(color: context.subtitleColor)),
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.bg,
        appBar: _buildAppBar(context),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => context.read<DriverProvider>().loadProfile(),
            color: VamoTheme.accent,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildGreeting(context),
                  const SizedBox(height: 20),
                  _buildShiftToggleCard(context),
                  const SizedBox(height: 24),
                  _buildApprovalNotice(context),
                  const SizedBox(height: 12),
                  _buildRideRequestsSection(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── App bar ──────────────────────────────────────────────────────────

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
                child: Image.asset(
                  'assets/images/vamo-logo.png',
                  width: 24,
                  height: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Vamo للسائقين',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
          ),
        ],
      ),
      actions: [
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
                  side: BorderSide(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
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
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'logout') _confirmLogout(context);
          },
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
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded,
                      color: const Color(0xFFF87171), size: 20),
                  const SizedBox(width: 12),
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

  // ── Greeting ─────────────────────────────────────────────────────────

  Widget _buildGreeting(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Row(
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
                  : 'V',
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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'جاهز لاستقبال طلبات الركوب',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.subtitleColor,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Shift toggle card ────────────────────────────────────────────────

  Widget _buildShiftToggleCard(BuildContext context) {
    final driver = context.watch<DriverProvider>();
    final onShift = driver.isOnShift;
    final isToggling = driver.isToggling;

    final gradientColors = onShift
        ? const [Color(0xFF05472A), Color(0xFF0A6B3E)]
        : (context.isDarkTheme
            ? [const Color(0xFF1F1F1F), const Color(0xFF141414)]
            : [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)]);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: onShift
              ? const Color(0xFF166534).withValues(alpha: 0.6)
              : context.cardBorderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (onShift ? VamoTheme.accent : Colors.black)
                .withValues(alpha: onShift ? 0.2 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status icon + labels
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: onShift
                      ? const Color(0xFF166534)
                      : Colors.black.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  onShift
                      ? Icons.directions_car_filled_rounded
                      : Icons.directions_car_filled_outlined,
                  color: onShift ? VamoTheme.accent : context.subtitleColor,
                  size: 34,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      onShift ? 'نشط الآن' : 'غير نشط',
                      style: TextStyle(
                        color: onShift
                            ? Colors.white
                            : context.titleColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      onShift
                          ? 'أنت تستقبل طلبات الركوب حاليًا'
                          : 'فعّل حالتك لاستقبال طلبات الركوب',
                      style: TextStyle(
                        color: onShift ? Colors.white70 : context.subtitleColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Switch
              GestureDetector(
                onTap: !isToggling ? () => _onToggleShift(context) : null,
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 68,
                  height: 38,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: onShift
                        ? VamoTheme.accent
                        : Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    alignment: onShift
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: onShift
                            ? Colors.white
                            : (context.isDarkTheme
                                ? const Color(0xFF3A3A3A)
                                : Colors.white),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isToggling
                          ? const Padding(
                              padding: EdgeInsets.all(7),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: VamoTheme.primary,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Approval notice ─────────────────────────────────────────────────

  Widget _buildApprovalNotice(BuildContext context) {
    final driver = context.watch<DriverProvider>();
    final profile = driver.profile;

    if (driver.isLoadingProfile && profile == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: VamoTheme.accent),
        ),
      );
    }

    if (profile == null) {
      return ErrorBanner(
        message: driver.profileError ?? 'تعذر تحميل بيانات السائق.',
        onDismiss: driver.clearProfileError,
      );
    }

    if (profile.isPending) {
      return _infoNotice(
        context,
        icon: Icons.hourglass_top_rounded,
        color: VamoTheme.warning,
        title: 'الحساب قيد المراجعة',
        message: 'سيتم تفعيل حسابك بعد اعتماده من الإدارة. تعذّر تفعيل استقبال الطلبات حتى ذلك الحين.',
      );
    }

    if (profile.isRejected) {
      return _infoNotice(
        context,
        icon: Icons.close_rounded,
        color: VamoTheme.alert,
        title: 'تم رفض الحساب',
        message: 'للأسف لم يتم اعتماد حسابك. تواصل مع الإدارة للمزيد من التفاصيل.',
      );
    }

    // Approved — show driver details line.
    return Row(
      children: [
        Icon(Icons.verified_rounded, color: VamoTheme.success, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'حسابك معتمد · ${profile.approvalLabel}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: VamoTheme.success,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }

  Widget _infoNotice(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.subtitleColor,
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Ride requests section ────────────────────────────────────────────

  Widget _buildRideRequestsSection(BuildContext context) {
    final driver = context.watch<DriverProvider>();

    if (!driver.isOnShift) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.cardBorderColor),
        ),
        child: Column(
          children: [
            Icon(
              Icons.wifi_protected_setup_rounded,
              color: context.subtitleColor,
              size: 42,
            ),
            const SizedBox(height: 16),
            Text(
              'استقبال الطلبات متوقف',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'فعّل الحالة "نشط" من الأعلى لعرض طلبات الركوب المتاحة.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.subtitleColor,
                    height: 1.6,
                  ),
            ),
          ],
        ),
      );
    }

    if (driver.isLoadingRideRequests) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: VamoTheme.accent),
        ),
      );
    }

    if (driver.rideRequestsError != null) {
      return ErrorBanner(
        message: driver.rideRequestsError,
        onDismiss: driver.clearRideRequestsError,
      );
    }

    if (driver.rideRequests.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.cardBorderColor),
        ),
        child: Column(
          children: [
            Icon(Icons.taxi_alert_rounded, color: context.subtitleColor, size: 42),
            const SizedBox(height: 16),
            Text(
              'لا توجد طلبات حالياً',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'ستظهر طلبات الركوب هنا فور توفرها.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.subtitleColor,
                    height: 1.6,
                  ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.assignment_outlined, color: VamoTheme.accent, size: 22),
            const SizedBox(width: 8),
            Text(
              'طلبات الركوب',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (final request in driver.rideRequests) ...[
          _buildRideRequestCard(context, request),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildRideRequestCard(BuildContext context, RideRequest request) {
    final driver = context.watch<DriverProvider>();
    final accepting = driver.isAccepting(request.id);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Passenger row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: VamoTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: VamoTheme.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.passengerName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (request.vehicleLabel.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        request.vehicleLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.subtitleColor,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '${request.price.toStringAsFixed(0)} ج.م',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: VamoTheme.accent,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Trip details
          _tripLine(context, Icons.circle_outlined, request.pickupLabel,
              color: VamoTheme.accent),
          const SizedBox(height: 10),
          _tripLine(context, Icons.place_outlined, request.destinationLabel,
              color: VamoTheme.alert),
          const SizedBox(height: 16),
          // Meta chips: distance + duration
          Row(
            children: [
              _metaChip(context, Icons.straighten_rounded,
                  '${request.distanceInKm.toStringAsFixed(1)} كم'),
              const SizedBox(width: 8),
              _metaChip(context, Icons.schedule_rounded,
                  '${request.durationMinutes} دقيقة'),
            ],
          ),
          const SizedBox(height: 18),
          // Actions
          accepting
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: VamoTheme.accent,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: VamoButton(
                        label: 'قبول الطلب',
                        icon: Icons.check_circle_outline_rounded,
                        onPressed: () =>
                            _handleAcceptRequest(context, request.id),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () =>
                          _handleDismissRequest(context, request.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.subtitleColor,
                        side: BorderSide(color: context.cardBorderColor),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                      child: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _metaChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.cardBorderColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: context.subtitleColor, size: 15),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.subtitleColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  Widget _tripLine(BuildContext context, IconData icon, String text,
      {required Color color}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.titleColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAcceptRequest(BuildContext context, String requestId) async {
    final driver = context.read<DriverProvider>();

    final accepted = await driver.acceptRideRequest(requestId);
    if (!context.mounted) return;

    if (accepted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(_statusSnackBar('تم قبول الطلب بنجاح.'));
    } else {
      final reason = driver.acceptError ??
          'تعذر قبول الطلب. قد يكون تم الاستيلاء عليه من سائق آخر.';
      ScaffoldMessenger.of(context).showSnackBar(_statusSnackBar(reason));
    }
  }

  void _handleDismissRequest(BuildContext context, String requestId) {
    context.read<DriverProvider>().dismissRideRequest(requestId);
  }
}