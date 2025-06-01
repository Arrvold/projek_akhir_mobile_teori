import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata; // Data zona waktu
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

  /// Memformat DateTime UTC ke string yang bisa dibaca dalam zona waktu target.
  /// Jika zona waktu target tidak valid, akan fallback ke UTC.
  String formatDateTimeForDisplay(DateTime dateTimeUtc, String targetTimeZoneName) {
    try {
      final targetLocation = tz.getLocation(targetTimeZoneName);
      final tz.TZDateTime targetTime = tz.TZDateTime.from(dateTimeUtc, targetLocation);
      // Format: "Senin, 20 Mei 2024, 15:30 WITA" (Contoh)
      // 'id_ID' untuk format bahasa Indonesia
      return DateFormat('EEEE, d MMMM yyyy, HH:mm zzzz', 'id_ID').format(targetTime);
    } catch (e) {
      print("Error formatting datetime untuk zona waktu '$targetTimeZoneName': $e. Fallback ke UTC.");
      // Fallback ke UTC jika zona waktu target tidak valid atau tidak ditemukan
      return DateFormat('EEEE, d MMMM yyyy, HH:mm', 'id_ID').format(dateTimeUtc) + " (UTC)";
    }
  }

  /// Mendapatkan nama zona waktu IANA dari daftar negara yang didukung berdasarkan kode negara.
  String? getTimezoneForSupportedCountry(String countryCode) {
     try {
      return SUPPORTED_COUNTRIES.firstWhere(
        (c) => c.countryCode.toUpperCase() == countryCode.toUpperCase()
      ).timeZoneName;
    } catch (e) {
      // Jika tidak ada di daftar negara yang didukung secara eksplisit
      return null;
    }
  }

  /// Menentukan zona waktu efektif yang akan digunakan untuk display.
  /// Berdasarkan zona waktu perangkat, daftar negara yang didukung, atau fallback.
  String getEffectiveTimeZoneName({
    required String? currentDeviceActualTimeZone, // Dari flutter_timezone
    required String? deviceCountryCode, // Dari geocoding
  }) {
    print("Mencari zona waktu efektif: Device TZ='${currentDeviceActualTimeZone}', Device Country='${deviceCountryCode}'");

    // 1. Prioritaskan zona waktu dari negara yang didukung jika kode negara cocok
    if (deviceCountryCode != null) {
      final String? tzFromSupportedCountry = getTimezoneForSupportedCountry(deviceCountryCode);
      if (tzFromSupportedCountry != null) {
        print("Menggunakan zona waktu dari negara yang didukung: $tzFromSupportedCountry (berdasarkan kode negara $deviceCountryCode)");
        return tzFromSupportedCountry;
      }
    }

    // 2. Jika kode negara tidak cocok atau tidak ada,
    //    dan zona waktu perangkat adalah salah satu zona waktu Indonesia spesifik.
    //    (Mungkin deviceCountryCode adalah 'ID' tapi zona waktu perangkat lebih spesifik, mis. WITA)
    if (currentDeviceActualTimeZone != null) {
      if (currentDeviceActualTimeZone == WIB ||
          currentDeviceActualTimeZone == WITA ||
          currentDeviceActualTimeZone == WIT) {
        print("Menggunakan zona waktu spesifik Indonesia: $currentDeviceActualTimeZone");
        return currentDeviceActualTimeZone;
      }
    }
    
    // 3. Jika tidak ada yang cocok di atas, gunakan FALLBACK_TIMEZONE_NAME
    print("Zona waktu perangkat '$currentDeviceActualTimeZone' atau negara '$deviceCountryCode' tidak secara eksplisit dipetakan, fallback ke $FALLBACK_TIMEZONE_NAME");
    return FALLBACK_TIMEZONE_NAME;
  }
}