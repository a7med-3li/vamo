import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../data/models/address_result.dart';
import '../../data/models/ride_option.dart';
import '../../providers/ride_book_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/trip_map_preview.dart';
import '../../widgets/vamo_button.dart';

/// Which of the two search bars is currently driving the results list.
enum _Field { pickup, dropoff }

/// Book-a-Ride screen.
///
/// Two search bars:
/// - the top bar is the pick-up location, defaulted to the device's current
///   location when it is known (left empty otherwise);
/// - the bottom bar is the drop-off location.
///
/// Each bar behaves the same way: typing fires debounced autocomplete, a
/// full-search fallback appears when autocomplete returns nothing, and tapping
/// a result pins it for that field. The ride cannot be requested until both
/// locations are entered.
class BookRideScreen extends StatefulWidget {
  const BookRideScreen({super.key});

  @override
  BookRideScreenState createState() => BookRideScreenState();
}

class BookRideScreenState extends State<BookRideScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final FocusNode _pickupFocus = FocusNode();
  final FocusNode _dropoffFocus = FocusNode();

  Timer? _pickupDebounce;
  Timer? _dropoffDebounce;

  static const _debounceDelay = Duration(milliseconds: 400);
  static const _currentLocationLabel = 'موقعي الحالي';

  _Field _activeField = _Field.pickup;
  bool _pickupEdited = false;

  bool get _isPickupActive => _activeField == _Field.pickup;

  String get _activeQuery => _isPickupActive
      ? _pickupController.text.trim()
      : _dropoffController.text.trim();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<RideBookProvider>();
      provider.addListener(_onProviderChanged);
      provider.loadCurrentLocation();
    });
  }

  /// Re-applies the device-location default into the pick-up bar while the
  /// user hasn't typed anything / hasn't pinned a pick-up address.
  void _onProviderChanged() {
    final provider = context.read<RideBookProvider>();
    if (provider.hasDeviceLocation &&
        !_pickupEdited &&
        _pickupController.text.isEmpty &&
        provider.pickupSelected == null) {
      _pickupController.text = _currentLocationLabel;
    }
  }

  void _onQueryChanged(_Field field, String value) {
    _activeField = field;
    final provider = context.read<RideBookProvider>();

    if (field == _Field.pickup) {
      _pickupEdited = value.isNotEmpty;
      _pickupDebounce?.cancel();
      if (provider.pickupSelected != null) provider.clearPickupSelection();
      if (value.trim().isEmpty) {
        provider.clearPickupSearch();
        return;
      }
      _pickupDebounce = Timer(_debounceDelay, () {
        if (mounted) provider.autoCompletePickup(value);
      });
    } else {
      _dropoffDebounce?.cancel();
      if (provider.dropoffSelected != null) provider.clearDropoffSelection();
      if (value.trim().isEmpty) {
        provider.clearDropoffSearch();
        return;
      }
      _dropoffDebounce = Timer(_debounceDelay, () {
        if (mounted) provider.autoCompleteDropoff(value);
      });
    }
  }

  void _clearField(_Field field) {
    final provider = context.read<RideBookProvider>();
    if (field == _Field.pickup) {
      _pickupController.clear();
      _pickupEdited = false;
      provider.clearPickupSelection();
      provider.clearPickupSearch();
      // Refill the device-location default, if available.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onProviderChanged();
      });
    } else {
      _dropoffController.clear();
      provider.clearDropoffSelection();
      provider.clearDropoffSearch();
    }
  }

  void _runFullSearch(_Field field) {
    final provider = context.read<RideBookProvider>();
    final query = field == _Field.pickup
        ? _pickupController.text.trim()
        : _dropoffController.text.trim();
    if (query.isEmpty) return;

    if (field == _Field.pickup) {
      _pickupDebounce?.cancel();
      provider.searchPickup(query);
    } else {
      _dropoffDebounce?.cancel();
      provider.searchDropoff(query);
    }
  }

  void _pinResult(AddressResult item) {
    final provider = context.read<RideBookProvider>();
    if (_isPickupActive) {
      provider.selectPickup(item);
      _pickupController.text = item.displayTitle;
      _pickupEdited = true;
      _pickupFocus.unfocus();
    } else {
      provider.selectDropoff(item);
      _dropoffController.text = item.displayTitle;
      _dropoffFocus.unfocus();
    }
  }

  @override
  void dispose() {
    context.read<RideBookProvider>().removeListener(_onProviderChanged);
    _pickupDebounce?.cancel();
    _dropoffDebounce?.cancel();
    _pickupController.dispose();
    _dropoffController.dispose();
    _pickupFocus.dispose();
    _dropoffFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.bg,
        appBar: AppBar(
          title: const Text('احجز رحلة'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildSearchSection(context),
              const SizedBox(height: 12),
              Expanded(child: _buildResultsSection(context)),
              _buildBottomPanel(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── Search bars ────────────────────────────────────────────────────
  Widget _buildSearchSection(BuildContext context) {
    final provider = context.watch<RideBookProvider>();
    final pickupQuery = _pickupController.text.trim();
    final dropoffQuery = _dropoffController.text.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Pick-up location bar ───────────────────────────────
          TextField(
            controller: _pickupController,
            focusNode: _pickupFocus,
            textInputAction: TextInputAction.search,
            onChanged: (v) => _onQueryChanged(_Field.pickup, v),
            onSubmitted: (_) => _runFullSearch(_Field.pickup),
            onTap: () => _activeField = _Field.pickup,
            decoration: InputDecoration(
              hintText: 'نقطة الانطلاق',
              prefixIcon: Icon(
                _pickupController.text == _currentLocationLabel
                    ? Icons.my_location_rounded
                    : Icons.trip_origin_rounded,
              ),
              suffixIcon: pickupQuery.isNotEmpty || _pickupController.text == _currentLocationLabel
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => _clearField(_Field.pickup),
                      tooltip: 'مسح',
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),

          // ── Drop-off location bar ──────────────────────────────
          TextField(
            controller: _dropoffController,
            focusNode: _dropoffFocus,
            textInputAction: TextInputAction.search,
            onChanged: (v) => _onQueryChanged(_Field.dropoff, v),
            onSubmitted: (_) => _runFullSearch(_Field.dropoff),
            onTap: () => _activeField = _Field.dropoff,
            decoration: InputDecoration(
              hintText: 'نقطة النزول أو الوجهة',
              prefixIcon: const Icon(Icons.location_on_outlined),
              suffixIcon: dropoffQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => _clearField(_Field.dropoff),
                      tooltip: 'مسح',
                    )
                  : null,
            ),
          ),

          // ── Location failure hint (below the pick-up bar) ──────
          if (provider.locationError != null &&
              provider.pickupSelected == null &&
              !provider.hasDeviceLocation)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  const Icon(Icons.location_off_rounded,
                      color: VamoTheme.alert, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.locationError!,
                      style:
                          const TextStyle(color: VamoTheme.alert, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: provider.loadCurrentLocation,
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),

          // ── Full-search fallback for the active bar ────────────
          if (provider.pickupSearch.isSearching || provider.dropoffSearch.isSearching)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'جارِ البحث...',
                      style: TextStyle(color: context.subtitleColor),
                    ),
                  ],
                ),
              ),
            )
          else if (_watchNoAutocompleteResults(context))
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: VamoButton(
                label: 'بحث شامل عن "$_activeQuery"',
                icon: Icons.travel_explore_rounded,
                isOutlined: true,
                onPressed: () => _runFullSearch(_activeField),
              ),
            ),
        ],
      ),
    );
  }

  /// True when the active field is idle (not searching), has a non-empty
  /// query, and shows no autocomplete rows (so the fallback should appear).
  bool _watchNoAutocompleteResults(BuildContext context) {
    final provider = context.watch<RideBookProvider>();
    final search = _isPickupActive
        ? provider.pickupSearch
        : provider.dropoffSearch;
    if (_activeQuery.isEmpty || search.resultsFromSearch) return false;
    return !search.isSearching && !search.hasResults;
  }

  // ── Results ─────────────────────────────────────────────────────────
  Widget _buildResultsSection(BuildContext context) {
    final provider = context.watch<RideBookProvider>();

    // ── Ride-request flow: loading / error / options ────────────────
    if (provider.isRequestingRide) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.rideRequestError != null) {
      return _buildRideRequestError(context, provider.rideRequestError!);
    }

    if (provider.rideOptions != null) {
      final options = provider.rideOptions!;
      if (options.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.route_rounded,
                    color: context.subtitleColor, size: 48),
                const SizedBox(height: 14),
                Text(
                  'لا توجد خيارات رحلة متاحة لهذه الوجهة حالياً.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.subtitleColor, fontSize: 15),
                ),
              ],
            ),
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: options.length + 2,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final tripMap = _buildTripMap(context);
            if (tripMap == null) return const SizedBox.shrink();
            return tripMap;
          }
          if (index == 1) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
              child: Text(
                'خيارات الرحلة المتاحة',
                style: TextStyle(
                  color: context.subtitleColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }
          return _RideOptionTile(option: options[index - 2]);
        },
      );
    }

    final search =
        _isPickupActive ? provider.pickupSearch : provider.dropoffSearch;

    if (search.isSearching || provider.pickupSearch.isSearching || provider.dropoffSearch.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (search.hasResults) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: search.results.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = search.results[index];
          return _AddressTile(
            address: item,
            isSelected: search.selected?.id == item.id,
            onTap: () => _pinResult(item),
          );
        },
      );
    }

    if (search.searchError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  color: context.subtitleColor, size: 40),
              const SizedBox(height: 12),
              Text(
                search.searchError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.subtitleColor),
              ),
            ],
          ),
        ),
      );
    }

    // Empty / idle state
    final tripMap = _buildTripMap(context);
    if (tripMap != null) {
      return tripMap;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isPickupActive
                  ? Icons.trip_origin_rounded
                  : Icons.location_on_outlined,
              color: context.subtitleColor,
              size: 48,
            ),
            const SizedBox(height: 14),
            Text(
              _isPickupActive
                  ? 'ابدأ بالكتابة لتحديد نقطة الانطلاق'
                  : 'ابدأ بالكتابة لتحديد نقطة النزول',
              style: TextStyle(color: context.subtitleColor, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the pick-up → drop-off trip map when both coordinates are known.
  /// Returns `null` while a coordinate is still missing so callers can fall
  /// back to their idle state.
  Widget? _buildTripMap(BuildContext context) {
    final provider = context.watch<RideBookProvider>();
    if (!provider.canRequestRide) return null;

    final pickup = provider.pickupCoordinates;
    final dropoff = provider.dropoffSelected;
    if (pickup == null || dropoff?.lat == null || dropoff?.lng == null) {
      return null;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TripMapPreview(
        pickup: LatLng(pickup.latitude, pickup.longitude),
        dropoff: LatLng(dropoff!.lat!, dropoff.lng!),
        height: 260,
      ),
    );
  }

  Widget _buildRideRequestError(BuildContext context, String message) {
    final provider = context.read<RideBookProvider>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                color: context.subtitleColor, size: 48),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.subtitleColor, fontSize: 15),
            ),
            const SizedBox(height: 16),
            VamoButton(
              label: 'إعادة المحاولة',
              icon: Icons.refresh_rounded,
              isOutlined: true,
              onPressed: provider.requestRide,
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom panel ────────────────────────────────────────────────────
  Widget _buildBottomPanel(BuildContext context) {
    final provider = context.watch<RideBookProvider>();
    final canRequest = provider.canRequestRide;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(top: BorderSide(color: context.cardBorderColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPickupRow(context, provider),
          const SizedBox(height: 16),
          VamoButton(
            label: _requestLabel(provider, canRequest),
            icon: Icons.directions_car_filled_rounded,
            isLoading: provider.isRequestingRide,
            onPressed: canRequest ? _onConfirmBooking : null,
          ),
        ],
      ),
    );
  }

String _requestLabel(RideBookProvider provider, bool canRequest) {
  if (canRequest) return 'اطلب رحلة';
  if (!provider.hasPickup) return 'حدد نقطة الانطلاق أولاً';
  return 'حدد نقطة النزول أولاً';
}

  Widget _buildPickupRow(BuildContext context, RideBookProvider provider) {
    if (provider.isLocating) {
      return Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'جارِ تحديد موقعك الحالي...',
            style: TextStyle(color: context.subtitleColor),
          ),
        ],
      );
    }

    final selected = provider.pickupSelected;
    String label;
    IconData icon;
    Color iconColor;
    if (selected != null) {
      label = selected.displayTitle;
      icon = Icons.trip_origin_rounded;
      iconColor = VamoTheme.accentDark;
    } else if (provider.hasDeviceLocation) {
      label = '$_currentLocationLabel\n'
          '(${provider.deviceLocation!.latitude.toStringAsFixed(5)}, '
          '${provider.deviceLocation!.longitude.toStringAsFixed(5)})';
      icon = Icons.my_location_rounded;
      iconColor = VamoTheme.accentDark;
    } else {
      label = 'لم يتم تحديد نقطة الانطلاق';
      icon = Icons.location_off_rounded;
      iconColor = VamoTheme.alert;
    }

    return Row(
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: context.subtitleColor, height: 1.4),
          ),
        ),
      ],
    );
  }

  void _onConfirmBooking() {
    context.read<RideBookProvider>().requestRide();
  }
}

/// A passive (non-selectable) ride-option row shown after requesting a ride.
/// Tapping/selecting will be enabled once the booking flow is implemented.
class _RideOptionTile extends StatelessWidget {
  const _RideOptionTile({required this.option});

  final RideOption option;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: VamoTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(option.icon, color: VamoTheme.accentDark, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        option.typeLabel,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.titleColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      option.formattedPrice,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: VamoTheme.accentDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildChip(
                      context,
                      icon: Icons.schedule_rounded,
                      text: option.formattedDuration,
                    ),
                    const SizedBox(width: 12),
                    _buildChip(
                      context,
                      icon: Icons.straighten_rounded,
                      text: option.formattedDistance,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.subtitleColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: context.subtitleColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// A single tappable address row in the results list.
class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.isSelected,
    required this.onTap,
  });

  final AddressResult address;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? VamoTheme.accent.withValues(alpha: 0.12)
          : context.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? VamoTheme.accent : context.cardBorderColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.place_outlined,
                color: isSelected ? VamoTheme.accent : context.subtitleColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.displayTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.titleColor,
                      ),
                    ),
                    if (address.description.isNotEmpty &&
                        address.description != address.title) ...[
                      const SizedBox(height: 2),
                      Text(
                        address.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.subtitleColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}