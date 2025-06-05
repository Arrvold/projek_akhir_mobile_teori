
import '../core/config/constants.dart'; 

class CurrencyService {
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
  
  Map<String, double> _fetchedRates = {}; 
  DateTime? _lastFetchTime;


  Future<void> _ensureExchangeRatesFetched() async {
    if (_fetchedRates.isEmpty || 
        _lastFetchTime == null || 
        DateTime.now().difference(_lastFetchTime!).inHours > 6) {
      
      print("CurrencyService: Memuat/memperbarui nilai tukar (menggunakan mock rates)...");

      _fetchedRates = Map.from(_mockRatesRelativeToUSD); 
      _lastFetchTime = DateTime.now();
      print("CurrencyService: Mock rates loaded: $_fetchedRates");
    }
  }

  

  /// Mengkonversi sejumlah `amountInIdr` ke `targetCurrencyCode`.
  Future<double?> getPriceInCurrency(double amountInIdr, String targetCurrencyCode) async {
    await _ensureExchangeRatesFetched(); 


    if (!_fetchedRates.containsKey(BASE_CURRENCY_CODE) || 
        !_fetchedRates.containsKey(targetCurrencyCode) ||
        !_fetchedRates.containsKey('USD')) { 
      print("Nilai tukar untuk IDR, USD, atau $targetCurrencyCode tidak ditemukan dalam _fetchedRates.");
      if (targetCurrencyCode == BASE_CURRENCY_CODE) {
        return amountInIdr; 
      }
      return null;
    }

    // Jika target mata uang adalah IDR, langsung kembalikan jumlah aslinya
    if (targetCurrencyCode == BASE_CURRENCY_CODE) {
      return amountInIdr;
    }

    // 1. Konversi amountInIdr ke USD
    //    _fetchedRates[BASE_CURRENCY_CODE] adalah nilai 1 USD dalam IDR (misal, 16300.0)
    double rateUsdToIdr = _fetchedRates[BASE_CURRENCY_CODE]!;
    double amountInUSD = amountInIdr / rateUsdToIdr;

    // 2. Konversi amountInUSD ke TargetCurrency
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
      return null; 
    }
  }
}