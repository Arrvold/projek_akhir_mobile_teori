// lib/services/currency_service.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;
import '../core/config/constants.dart'; // Untuk RENTAL_PRICE_IDR dan SUPPORTED_COUNTRIES

class CurrencyService {

  final Map<String, double> _mockExchangeRatesToIDR = {
    'USD': 15500.0, 
    'GBP': 19500.0,
    'JPY': 105.0,   
    'EUR': 16800.0,
    'AUD': 10200.0,
    'CAD': 11500.0,
    'SGD': 11400.0,
    'MYR': 3300.0,
    'INR': 185.0,
    'IDR': 1.0,
  };
  
  // Simpan nilai tukar yang diambil dari API agar tidak fetch berulang kali
  Map<String, double> _fetchedRates = {};
  DateTime? _lastFetchTime;


  Future<Map<String, double>> _fetchExchangeRatesFromAPI(String baseCurrency) async {

    print("Menggunakan MOCK exchange rates karena API tidak diimplementasikan.");
    await Future.delayed(const Duration(seconds: 1)); // Simulasi delay API
    _fetchedRates = _mockExchangeRatesToIDR; 
    // Jika base IDR:
    Map<String, double> ratesFromIdr = {};
    _mockExchangeRatesToIDR.forEach((key, value) {
      ratesFromIdr[key] = RENTAL_PRICE_IDR / value; // Harga dalam mata uang asing
    });
    _fetchedRates = ratesFromIdr; 

    Map<String, double> ratesRelativeToUSD = {
      'USD': 1.0,
      'IDR': 15500.0,
      'GBP': 0.79, 
      'JPY': 148.0, 
      'EUR': 0.92,
      'AUD': 1.52,
      'CAD': 1.36,
      'SGD': 1.35,
      'MYR': 4.70,
      'INR': 83.0,
    };
    _fetchedRates = ratesRelativeToUSD;
    _lastFetchTime = DateTime.now();
    return _fetchedRates;
  }

  Future<double?> getPriceInCurrency(String targetCurrencyCode) async {
    // Cek apakah perlu fetch ulang (misalnya jika sudah lebih dari beberapa jam)
    if (_fetchedRates.isEmpty || _lastFetchTime == null || DateTime.now().difference(_lastFetchTime!).inHours > 6) {
      await _fetchExchangeRatesFromAPI('USD'); // Ambil rates berbasis USD
    }

    if (!_fetchedRates.containsKey('IDR') || !_fetchedRates.containsKey(targetCurrencyCode)) {
      print("Nilai tukar untuk IDR atau $targetCurrencyCode tidak ditemukan dalam fetched rates.");
      return null; // Atau fallback ke harga IDR jika targetCurrencyCode adalah IDR
    }

    if (targetCurrencyCode == BASE_CURRENCY_CODE) { // Jika target adalah IDR
        return RENTAL_PRICE_IDR;
    }

    // Konversi: IDR -> USD -> TargetCurrency
    double priceInUSD = RENTAL_PRICE_IDR / _fetchedRates[BASE_CURRENCY_CODE]!; // Harga film dalam USD
    double priceInTargetCurrency = priceInUSD * _fetchedRates[targetCurrencyCode]!; // Harga film dalam mata uang target

    return priceInTargetCurrency;
  }

  SupportedCountry? getSupportedCountryByCode(String countryCode) {
    try {
      return SUPPORTED_COUNTRIES.firstWhere((c) => c.countryCode.toUpperCase() == countryCode.toUpperCase());
    } catch (e) {
      return null;
    }
  }
}