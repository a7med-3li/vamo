import 'package:geolocator/geolocator.dart';

/// Resolves the driver's current position from the device.
///
/// Used to report the driver's live location when marking a ride as arrived.
class LocationService {
  /// Returns the device's current coordinates, or `null` when the location
  /// cannot be determined (service disabled, permission denied, timeout, ...).
  Future<({double latitude, double longitude})?> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return (latitude: position.latitude, longitude: position.longitude);
    } catch (_) {
      return null;
    }
  }
}