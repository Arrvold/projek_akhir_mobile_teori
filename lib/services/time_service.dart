import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import '../core/config/constants.dart';

class TimeService {
  TimeService() {
    _initializeTimeZones();
  }

  // Pastikan inisialisasi hanya dijalankan sekali
  static bool _isTimezonesInitialized = false;
  void _initializeTimeZones() {
    if (!_isTimezonesInitialized) {
      tzdata.initializeTimeZones();
      _isTimezonesInitialized = true;
      print("Data zona waktu diinisialisasi.");
    }
  }

  // Memformat DateTime UTC ke string yang bisa dibaca
  String formatDateTimeForDisplay(DateTime dateTimeUtc, String targetTimeZoneName) {
    try {
      final targetLocation = tz.getLocation(targetTimeZoneName);
      final tz.TZDateTime targetTime = tz.TZDateTime.from(dateTimeUtc, targetLocation);
      return DateFormat('EEEE, d MMMM yyyy, HH:mm zzzz', 'id_ID').format(targetTime);
    } catch (e) {
      print("Error formatting datetime untuk zona waktu '$targetTimeZoneName': $e. Fallback ke UTC.");
      // Fallback
      return DateFormat('EEEE, d MMMM yyyy, HH:mm', 'id_ID').format(dateTimeUtc) + " (UTC)";
    }
  }

  /// mendapatkan nama zona waktu
  String? getTimezoneForSupportedCountry(String countryCode) {
     try {
      return SUPPORTED_COUNTRIES.firstWhere(
        (c) => c.countryCode.toUpperCase() == countryCode.toUpperCase()
      ).timeZoneName;
    } catch (e) {
      return null;
    }
  }

  // menentukan zona waktu efektif yang akan digunakan untuk display
  String getEffectiveTimeZoneName({
    required String? currentDeviceActualTimeZone, 
    required String? deviceCountryCode,
  }) {
    print("Mencari zona waktu efektif: Device TZ='${currentDeviceActualTimeZone}', Device Country='${deviceCountryCode}'");

    // prioritaskan zona waktu dari negara yang didukung
    if (deviceCountryCode != null) {
      final String? tzFromSupportedCountry = getTimezoneForSupportedCountry(deviceCountryCode);
      if (tzFromSupportedCountry != null) {
        print("Menggunakan zona waktu dari negara yang didukung: $tzFromSupportedCountry (berdasarkan kode negara $deviceCountryCode)");
        return tzFromSupportedCountry;
      }
    }

    if (currentDeviceActualTimeZone != null) {
      if (currentDeviceActualTimeZone == WIB ||
          currentDeviceActualTimeZone == WITA ||
          currentDeviceActualTimeZone == WIT) {
        print("Menggunakan zona waktu spesifik Indonesia: $currentDeviceActualTimeZone");
        return currentDeviceActualTimeZone;
      }
    }
    
    print("Zona waktu perangkat '$currentDeviceActualTimeZone' atau negara '$deviceCountryCode' tidak secara eksplisit dipetakan, fallback ke $FALLBACK_TIMEZONE_NAME");
    return FALLBACK_TIMEZONE_NAME;
  }
}