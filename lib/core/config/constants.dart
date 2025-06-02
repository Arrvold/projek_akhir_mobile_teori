
const double BASE_RENTAL_PRICE_PER_DAY_IDR = 15000.0; // Contoh: Rp15.000 per hari
const int RENTAL_DURATION_HOURS = 48; // Ini bisa jadi durasi default awal

// Mata uang dasar dan fallback
const String BASE_CURRENCY_CODE = 'IDR';
const String FALLBACK_CURRENCY_CODE = 'USD';
const String FALLBACK_TIMEZONE_NAME = 'Europe/London';

// Daftar negara, mata uang, simbol, dan zona waktu yang didukung
class SupportedCountry {
  final String countryCode;
  final String currencyCode;
  final String currencySymbol;
  final String timeZoneName;
  final String countryName;

  const SupportedCountry({
    required this.countryCode,
    required this.currencyCode,
    required this.currencySymbol,
    required this.timeZoneName,
    required this.countryName,
  });
}

const List<SupportedCountry> SUPPORTED_COUNTRIES = [
  SupportedCountry(
    countryCode: 'ID',
    currencyCode: 'IDR',
    currencySymbol: 'Rp',
    timeZoneName: 'Asia/Jakarta',
    countryName: 'Indonesia',
  ),
  SupportedCountry(
    countryCode: 'US',
    currencyCode: 'USD',
    currencySymbol: '\$',
    timeZoneName: 'America/New_York',
    countryName: 'Amerika Serikat',
  ),
  SupportedCountry(
    countryCode: 'GB',
    currencyCode: 'GBP',
    currencySymbol: '£',
    timeZoneName: 'Europe/London',
    countryName: 'Inggris Raya',
  ),
  SupportedCountry(
    countryCode: 'JP',
    currencyCode: 'JPY',
    currencySymbol: '¥',
    timeZoneName: 'Asia/Tokyo',
    countryName: 'Jepang',
  ),
  SupportedCountry(
    countryCode: 'DE',
    currencyCode: 'EUR',
    currencySymbol: '€',
    timeZoneName: 'Europe/Berlin',
    countryName: 'Jerman (Euro)',
  ),
  SupportedCountry(
    countryCode: 'AU',
    currencyCode: 'AUD',
    currencySymbol: 'A\$',
    timeZoneName: 'Australia/Sydney',
    countryName: 'Australia',
  ),
  SupportedCountry(
    countryCode: 'CA',
    currencyCode: 'CAD',
    currencySymbol: 'C\$',
    timeZoneName: 'America/Toronto',
    countryName: 'Kanada',
  ),
  SupportedCountry(
    countryCode: 'SG',
    currencyCode: 'SGD',
    currencySymbol: 'S\$',
    timeZoneName: 'Asia/Singapore',
    countryName: 'Singapura',
  ),
  SupportedCountry(
    countryCode: 'MY',
    currencyCode: 'MYR',
    currencySymbol: 'RM',
    timeZoneName: 'Asia/Kuala_Lumpur',
    countryName: 'Malaysia',
  ),
  SupportedCountry(
    countryCode: 'IN',
    currencyCode: 'INR',
    currencySymbol: '₹',
    timeZoneName: 'Asia/Kolkata',
    countryName: 'India',
  ),
];

// Zona waktu spesifik Indonesia
const String WIB = 'Asia/Jakarta';
const String WITA = 'Asia/Makassar';
const String WIT = 'Asia/Jayapura';

class RentalDurationOption {
  final String label; 
  final Duration duration; 

  const RentalDurationOption({required this.label, required this.duration});
}

const List<RentalDurationOption> SUPPORTED_RENTAL_DURATIONS = [
  RentalDurationOption(label: '1 Hari (24 Jam)', duration: Duration(hours: 24)),
  RentalDurationOption(label: '2 Hari (48 Jam)', duration: Duration(hours: 48)), 
  RentalDurationOption(label: '3 Hari (72 Jam)', duration: Duration(hours: 72)),
  RentalDurationOption(label: '1 Minggu (168 Jam)', duration: Duration(days: 7)),
];

const Duration DEFAULT_RENTAL_DURATION = Duration(hours: 48);