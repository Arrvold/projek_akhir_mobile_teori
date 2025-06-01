// lib/services/currency_service.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;
import '../core/config/constants.dart'; // Untuk RENTAL_PRICE_IDR dan SUPPORTED_COUNTRIES

class CurrencyService {
  // GANTI DENGAN API KEY ExchangeRate-API ANDA atau layanan lain
  // Contoh ini menggunakan struktur respons dari ExchangeRate-API V6
  // static const String _exchangeRateApiKey = 'YOUR_EXCHANGERATE_API_KEY';
  // static const String _exchangeRateApiBaseUrl = 'https://v6.exchangerate-api.com/v6';

  // Untuk PROYEK KULIAH, jika API sulit, bisa hardcode perkiraan nilai tukar
  // Ini TIDAK AKURAT dan TIDAK REAL-TIME
  final Map<String, double> _mockExchangeRatesToIDR = {
    'USD': 15500.0, // 1 USD = 15500 IDR
    'GBP': 19500.0, // 1 GBP = 19500 IDR
    'JPY': 105.0,   // 1 JPY = 105 IDR (seharusnya IDR/JPY, jadi 1 IDR = 0.0095 JPY, atau 1 JPY = 105 IDR)
                 // Mari kita standarkan: 1 MATA_UANG_ASING = X IDR
    'EUR': 16800.0,
    'AUD': 10200.0,
    'CAD': 11500.0,
    'SGD': 11400.0,
    'MYR': 3300.0,
    'INR': 185.0,
    'IDR': 1.0, // 1 IDR = 1 IDR
  };
  
  // Simpan nilai tukar yang diambil dari API agar tidak fetch berulang kali
  Map<String, double> _fetchedRates = {};
  DateTime? _lastFetchTime;


  Future<Map<String, double>> _fetchExchangeRatesFromAPI(String baseCurrency) async {
    // Implementasi pemanggilan API nilai tukar di sini
    // Contoh dengan ExchangeRate-API:
    // final response = await http.get(Uri.parse('$_exchangeRateApiBaseUrl/$_exchangeRateApiKey/latest/$baseCurrency'));
    // if (response.statusCode == 200) {
    //   final data = json.decode(response.body);
    //   if (data['result'] == 'success') {
    //     // data['conversion_rates'] adalah Map<String, dynamic>, perlu konversi ke Map<String, double>
    //     return Map<String, double>.from(data['conversion_rates'].map((key, value) => MapEntry(key, (value as num).toDouble())));
    //   } else {
    //     throw Exception('Gagal mengambil nilai tukar dari API: ${data['error-type']}');
    //   }
    // } else {
    //   throw Exception('Error koneksi API nilai tukar: ${response.statusCode}');
    // }

    // Untuk sekarang, kita return mock rates
    print("Menggunakan MOCK exchange rates karena API tidak diimplementasikan.");
    await Future.delayed(const Duration(seconds: 1)); // Simulasi delay API
    _fetchedRates = _mockExchangeRatesToIDR; // Ini adalah X FOREIGN_CURRENCY = IDR
                                             // Kita butuh IDR ke FOREIGN_CURRENCY
                                             // Atau base USD lalu konversi
    // Jika base IDR:
    Map<String, double> ratesFromIdr = {};
    _mockExchangeRatesToIDR.forEach((key, value) {
      ratesFromIdr[key] = RENTAL_PRICE_IDR / value; // Harga dalam mata uang asing
    });
    _fetchedRates = ratesFromIdr; // Ini adalah harga film dalam tiap mata uang.
                                 // Lebih baik kita simpan nilai tukar murni saja.
                                 // 1 IDR = X FOREIGN_CURRENCY

    // Simpan nilai tukar murni 1 USD = X OTHER_CURRENCY
    // Mari gunakan base USD untuk nilai tukar
    // 1 USD = 15500 IDR
    // 1 USD = 0.8 GBP (misalnya) -> 1 GBP = 1/0.8 USD
    Map<String, double> ratesRelativeToUSD = {
      'USD': 1.0,
      'IDR': 15500.0,
      'GBP': 0.79, // 1 USD = 0.79 GBP
      'JPY': 148.0, // 1 USD = 148 JPY
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