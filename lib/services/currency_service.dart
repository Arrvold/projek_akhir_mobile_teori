
import '../core/config/constants.dart'; // Untuk BASE_CURRENCY_CODE dan SUPPORTED_COUNTRIES

class CurrencyService {
  // Nilai tukar MOCK: 1 MATA_UANG_ASING = X IDR
  // Ini bisa digunakan jika Anda ingin langsung mengkonversi dari IDR ke mata uang lain
  // final Map<String, double> _mockExchangeRatesToIDR = {
  //   'USD': 15500.0,
  //   'GBP': 19500.0,
  //   'JPY': 105.0,
  //   'EUR': 16800.0,
  //   'AUD': 10200.0,
  //   'CAD': 11500.0,
  //   'SGD': 11400.0,
  //   'MYR': 3300.0,
  //   'INR': 185.0,
  //   'IDR': 1.0,
  // };

  // Kita akan menggunakan nilai tukar relatif terhadap USD sebagai basis internal.
  // 1 USD = X OTHER_CURRENCY
  // Ini lebih umum jika Anda menggunakan API nilai tukar.
  final Map<String, double> _mockRatesRelativeToUSD = {
    'USD': 1.0,      
    'IDR': 16300.0,  
    'GBP': 0.79,   
    'JPY': 157.0,   
    'EUR': 0.92,   
    'AUD': 1.50,   
    'CAD': 1.37,  
    'SGD': 1.35,   
    'MYR': 4.70,   
    'INR': 83.50,  
  };
  
  Map<String, double> _fetchedRates = {}; // Akan menyimpan _mockRatesRelativeToUSD
  DateTime? _lastFetchTime;

  /// Mengambil atau memuat nilai tukar (saat ini menggunakan mock).
  /// Nilai tukar disimpan relatif terhadap USD.
  Future<void> _ensureExchangeRatesFetched() async {
    // Cek apakah perlu fetch ulang (misalnya jika sudah lebih dari beberapa jam atau belum ada)
    if (_fetchedRates.isEmpty || 
        _lastFetchTime == null || 
        DateTime.now().difference(_lastFetchTime!).inHours > 6) {
      
      print("CurrencyService: Memuat/memperbarui nilai tukar (menggunakan mock rates)...");
      // Untuk implementasi nyata, di sini Anda akan memanggil API nilai tukar
      // await _fetchExchangeRatesFromAPI('USD'); 

      // Menggunakan mock data untuk proyek ini
      _fetchedRates = Map.from(_mockRatesRelativeToUSD); // Salin dari mock
      _lastFetchTime = DateTime.now();
      print("CurrencyService: Mock rates loaded: $_fetchedRates");
    }
  }

  // Komentari atau hapus _fetchExchangeRatesFromAPI jika hanya menggunakan mock,
  // atau implementasikan pemanggilan API sungguhan di sini.
  // Future<Map<String, double>> _fetchExchangeRatesFromAPI(String baseCurrency) async {
  //   print("Menggunakan MOCK exchange rates karena API tidak diimplementasikan.");
  //   await Future.delayed(const Duration(seconds: 1)); 
  //   _fetchedRates = _mockRatesRelativeToUSD; // Menggunakan mock yang sudah berbasis USD
  //   _lastFetchTime = DateTime.now();
  //   return _fetchedRates;
  // }

  /// Mengkonversi sejumlah `amountInIdr` ke `targetCurrencyCode`.
  Future<double?> getPriceInCurrency(double amountInIdr, String targetCurrencyCode) async {
    await _ensureExchangeRatesFetched(); // Pastikan nilai tukar sudah ada

    // Validasi apakah mata uang yang dibutuhkan ada di dalam _fetchedRates kita (yang berbasis USD)
    // Kita juga butuh nilai tukar IDR terhadap USD.
    if (!_fetchedRates.containsKey(BASE_CURRENCY_CODE) || // BASE_CURRENCY_CODE adalah 'IDR'
        !_fetchedRates.containsKey(targetCurrencyCode) ||
        !_fetchedRates.containsKey('USD')) { // Pastikan USD juga ada sebagai basis
      print("Nilai tukar untuk IDR, USD, atau $targetCurrencyCode tidak ditemukan dalam _fetchedRates.");
      if (targetCurrencyCode == BASE_CURRENCY_CODE) {
        return amountInIdr; // Jika targetnya IDR, langsung kembalikan
      }
      return null;
    }

    // Jika target mata uang adalah IDR, langsung kembalikan jumlah aslinya
    if (targetCurrencyCode == BASE_CURRENCY_CODE) {
      return amountInIdr;
    }

    // Langkah Konversi: IDR -> USD -> TargetCurrency
    // 1. Konversi amountInIdr ke USD
    //    _fetchedRates[BASE_CURRENCY_CODE] adalah nilai 1 USD dalam IDR (misal, 16300.0)
    double rateUsdToIdr = _fetchedRates[BASE_CURRENCY_CODE]!;
    double amountInUSD = amountInIdr / rateUsdToIdr;

    // 2. Konversi amountInUSD ke TargetCurrency
    //    _fetchedRates[targetCurrencyCode] adalah nilai 1 USD dalam TargetCurrency (misal, 0.92 untuk EUR)
    double rateUsdToTarget = _fetchedRates[targetCurrencyCode]!;
    double priceInTargetCurrency = amountInUSD * rateUsdToTarget;
    
    print("Konversi: $amountInIdr IDR -> $amountInUSD USD -> $priceInTargetCurrency $targetCurrencyCode");

    return priceInTargetCurrency;
  }

  /// Mendapatkan data negara yang didukung berdasarkan kode negaranya.
  SupportedCountry? getSupportedCountryByCode(String countryCode) {
    try {
      return SUPPORTED_COUNTRIES.firstWhere((c) => c.countryCode.toUpperCase() == countryCode.toUpperCase());
    } catch (e) {
      return null; // Kembalikan null jika tidak ditemukan
    }
  }
}