import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

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
        return placemarks.first.isoCountryCode?.toUpperCase(); 
      }
    } catch (e) {
      print("Error mendapatkan kode negara: $e");
    }
    return null;
  }

  /// Mendapatkan nama zona waktu lokal perangkat
  Future<String> getCurrentTimeZoneName() async {
    try {
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      print('Zona Waktu Perangkat (flutter_timezone): $currentTimeZone');
      return currentTimeZone;
    } catch (e) {
      print("Error mendapatkan nama zona waktu dengan flutter_timezone: $e");
      return "Etc/UTC"; 
    }
  }
}