
import '../core/config/constants.dart'; 

class CurrencyService {

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

    if (targetCurrencyCode == BASE_CURRENCY_CODE) {
      return amountInIdr;
    }

    // Konversi amountInIdr ke USD
    double rateUsdToIdr = _fetchedRates[BASE_CURRENCY_CODE]!;
    double amountInUSD = amountInIdr / rateUsdToIdr;

    // Konversi amountInUSD ke TargetCurrency
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