import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/theme.dart';

/// A static trip preview on an OpenStreetMap base layer: two markers (pick-up
/// and drop-off) joined by a straight route line, auto-fitted to the screen.
class TripMapPreview extends StatefulWidget {
  const TripMapPreview({
    super.key,
    required this.pickup,
    required this.dropoff,
    this.height = 220,
    this.showLegend = true,
  });

  final LatLng pickup;
  final LatLng dropoff;
  final double height;

  /// Whether to render the small pick-up/drop-off legend below the map.
  final bool showLegend;

  @override
  TripMapPreviewState createState() => TripMapPreviewState();
}

class TripMapPreviewState extends State<TripMapPreview> {
  final MapController _mapController = MapController();

  LatLng get _midpoint => LatLng(
        (widget.pickup.latitude + widget.dropoff.latitude) / 2,
        (widget.pickup.longitude + widget.dropoff.longitude) / 2,
      );

  LatLngBounds get _bounds =>
      LatLngBounds.fromPoints([widget.pickup, widget.dropoff]);

  @override
  void didUpdateWidget(TripMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pickup != widget.pickup ||
        oldWidget.dropoff != widget.dropoff) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitToTrip());
    }
  }

  /// Centers and zooms the camera so both points fit inside the visible area.
  Future<void> _fitToTrip() async {
    if (!mounted) return;
    final result = _mapController.fitCamera(
      CameraFit.bounds(
        bounds: _bounds,
        padding: const EdgeInsets.all(56),
      ),
    );
    if (!result) {
      // The map may not be ready yet — retry on the next frame.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: _bounds,
            padding: const EdgeInsets.all(56),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.cardBorderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: widget.height,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _midpoint,
                initialZoom: 12,
                initialCameraFit: CameraFit.bounds(
                  bounds: _bounds,
                  padding: const EdgeInsets.all(56),
                ),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.vamo.passenger',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [widget.pickup, widget.dropoff],
                      strokeWidth: 4,
                      color: VamoTheme.accentDark,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    _buildMarker(
                      widget.pickup,
                      icon: Icons.trip_origin_rounded,
                      color: VamoTheme.accentDark,
                      halo: const Color(0xFF05472A),
                    ),
                    _buildMarker(
                      widget.dropoff,
                      icon: Icons.location_on_rounded,
                      color: VamoTheme.alert,
                      halo: const Color(0xFFB91C1C),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.showLegend) _buildLegend(context),
        ],
      ),
    );
  }

  Marker _buildMarker(LatLng point,
      {required IconData icon, required Color color, required Color halo}) {
    return Marker(
      point: point,
      width: 36,
      height: 36,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: halo, width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: context.cardColor),
      child: Row(
        children: [
          _legendItem(
            context,
            dotColor: VamoTheme.accentDark,
            label: 'نقطة الانطلاق',
          ),
          const SizedBox(width: 18),
          _legendItem(
            context,
            dotColor: VamoTheme.alert,
            label: 'نقطة النزول',
          ),
          const Spacer(),
          Icon(Icons.layers_rounded, color: context.subtitleColor, size: 16),
        ],
      ),
    );
  }

  Widget _legendItem(BuildContext context,
      {required Color dotColor, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: context.subtitleColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}