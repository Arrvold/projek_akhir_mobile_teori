import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
// Hapus import flutter_native_timezone
// import 'package:flutter_native_timezone/flutter_native_timezone.dart';
// Tambahkan import flutter_timezone
import 'package:flutter_timezone/flutter_timezone.dart';
// import '../core/config/constants.dart'; // Untuk fallback timezone jika diperlukan

class LocationService {
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Layanan lokasi dinonaktifkan.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Izin lokasi ditolak permanen, kami tidak dapat meminta izin.');
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<String?> getCurrentCountryCode() async {
    try {
      Position position = await _determinePosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        print('Kode Negara Perangkat (geocoding): ${placemarks.first.isoCountryCode}');
        return placemarks.first.isoCountryCode?.toUpperCase(); // Pastikan uppercase untuk konsistensi
      }
    } catch (e) {
      print("Error mendapatkan kode negara: $e");
    }
    return null;
  }

  /// Mendapatkan nama zona waktu IANA lokal perangkat menggunakan flutter_timezone.
  Future<String> getCurrentTimeZoneName() async {
    try {
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      print('Zona Waktu Perangkat (flutter_timezone): $currentTimeZone'); // e.g., "Asia/Jakarta", "America/New_York"
      return currentTimeZone;
    } catch (e) {
      print("Error mendapatkan nama zona waktu dengan flutter_timezone: $e");
      // Kembalikan zona waktu UTC atau fallback lain yang aman jika gagal
      return "Etc/UTC"; // Atau bisa juga FALLBACK_TIMEZONE_NAME dari constants.dart
    }
  }
}