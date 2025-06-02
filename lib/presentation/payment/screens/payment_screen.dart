import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk NumberFormat
import '../../../core/config/constants.dart';
import '../../../data/models/movie_detail_model.dart';
import '../../../data/models/rental_model.dart';
import '../../../data/sources/local/database_helper.dart';
import '../../../data/sources/local/preferences_helper.dart';
import '../../../services/currency_service.dart';
import '../../../services/location_service.dart';
import '../../../services/notification_service.dart';

class PaymentScreen extends StatefulWidget {
  final MovieDetailModel movie;
  const PaymentScreen({super.key, required this.movie});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final LocationService _locationService = LocationService();
  final CurrencyService _currencyService = CurrencyService();
  final NotificationService _notificationService = NotificationService();

  String? _selectedCurrencyCode;
  String _selectedCurrencySymbol = '';
  double? _displayedPrice; // Harga yang sudah dikonversi ke _selectedCurrencyCode
  double _currentBasePriceIdr = 0.0; // Harga dasar dalam IDR untuk durasi terpilih

  bool _isLoadingDetails = true; // Untuk loading awal (lokasi, mata uang awal)
  bool _isCalculatingPrice = false; // Untuk loading saat ganti durasi/mata uang

  String? _error;
  final List<SupportedCountry> _availableCurrencies = SUPPORTED_COUNTRIES;

  // Inisialisasi _selectedRentalDuration dengan benar
  late RentalDurationOption _selectedRentalDuration;

  @override
  void initState() {
    super.initState();
    // Cari durasi default dari konstanta
    _selectedRentalDuration = SUPPORTED_RENTAL_DURATIONS.firstWhere(
      (opt) => opt.duration == DEFAULT_RENTAL_DURATION,
      orElse: () => SUPPORTED_RENTAL_DURATIONS.length > 1 ? SUPPORTED_RENTAL_DURATIONS[1] : SUPPORTED_RENTAL_DURATIONS[0] // Fallback aman
    );
    // Set harga dasar awal berdasarkan durasi default, lalu inisialisasi detail pembayaran
    _calculateBasePriceIdrAndUpdateDisplay(_selectedRentalDuration); // Hitung harga dasar IDR awal
    _initializePaymentLocationAndCurrency(); // Kemudian tentukan mata uang & konversi
  }

  /// Menghitung harga dasar dalam IDR berdasarkan durasi terpilih
  void _calculateBasePriceIdrAndUpdateDisplay(RentalDurationOption selectedDurationOption) {
    if (!mounted) return;
    // Hitung jumlah hari, bulatkan ke atas jika ada sisa jam
    int totalHours = selectedDurationOption.duration.inHours;
    int totalDays = (totalHours / 24).ceil();
    if (totalDays == 0 && totalHours > 0) totalDays = 1; // Minimal 1 hari jika ada jam

    setState(() {
      _currentBasePriceIdr = totalDays * BASE_RENTAL_PRICE_PER_DAY_IDR;
    });
    
    print("Durasi: ${selectedDurationOption.label}, Total Hari Dihitung: $totalDays, Harga Dasar IDR: $_currentBasePriceIdr");

    // Setelah base price IDR dihitung ulang, update harga yang ditampilkan dalam mata uang terpilih
    if (_selectedCurrencyCode != null && _selectedCurrencySymbol.isNotEmpty) {
      _updateDisplayedPriceForCurrency(_selectedCurrencyCode!, _selectedCurrencySymbol);
    }
  }

  Future<void> _initializePaymentLocationAndCurrency() async {
    if (!mounted) return;
    setState(() { _isLoadingDetails = true; _error = null; });
    try {
      String? deviceCountryCode = await _locationService.getCurrentCountryCode();
      String targetCurrencyCode = FALLBACK_CURRENCY_CODE;
      String targetSymbol = SUPPORTED_COUNTRIES.firstWhere((c) => c.currencyCode == FALLBACK_CURRENCY_CODE).currencySymbol;

      if (deviceCountryCode != null) {
        final supportedCountry = _currencyService.getSupportedCountryByCode(deviceCountryCode);
        if (supportedCountry != null) {
          targetCurrencyCode = supportedCountry.currencyCode;
          targetSymbol = supportedCountry.currencySymbol;
        }
      }
      // Harga awal akan dihitung berdasarkan _currentBasePriceIdr yang sudah diset dari durasi default
      await _updateDisplayedPriceForCurrency(targetCurrencyCode, targetSymbol);

    } catch (e) {
      if (mounted) setState(() { _error = "Gagal memuat info pembayaran awal: ${e.toString()}"; });
      print("PaymentScreen Init Error: $e");
      final idrData = SUPPORTED_COUNTRIES.firstWhere((c) => c.currencyCode == BASE_CURRENCY_CODE);
      await _updateDisplayedPriceForCurrency(BASE_CURRENCY_CODE, idrData.currencySymbol); // Fallback ke IDR
    } finally {
      if (mounted) setState(() { _isLoadingDetails = false; });
    }
  }

  Future<void> _updateDisplayedPriceForCurrency(String currencyCode, String currencySymbol) async {
    if (!mounted) return;
    setState(() { _isCalculatingPrice = true; _error = null; });
    try {
      // Kirim _currentBasePriceIdr (harga dasar IDR yang sudah dihitung berdasarkan durasi)
      double? price = await _currencyService.getPriceInCurrency(_currentBasePriceIdr, currencyCode);
      if (mounted) {
        setState(() {
          _selectedCurrencyCode = currencyCode;
          _selectedCurrencySymbol = currencySymbol;
          _displayedPrice = price;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = "Gagal mengkonversi mata uang ke $currencyCode."; });
      print("Update Price Error: $e");
    } finally {
      if (mounted) setState(() { _isCalculatingPrice = false; });
    }
  }

  Future<void> _processPayment() async {
    if (_displayedPrice == null || _selectedCurrencyCode == null) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Informasi harga tidak tersedia.")));
      return;
    }
    if (!mounted) return;
    setState(() { _isLoadingDetails = true; }); // Gunakan _isLoadingDetails untuk proses bayar

    try {
      int? loggedInUserId = await PreferencesHelper.getLoggedInUserId();
      if (loggedInUserId == null) { throw Exception("Sesi pengguna tidak ditemukan. Silakan login kembali."); }

      DateTime rentalStartUtc = DateTime.now().toUtc();
      Duration finalRentalDuration = _selectedRentalDuration.duration;
      DateTime rentalEndUtc = rentalStartUtc.add(finalRentalDuration);

      RentalModel newRental = RentalModel(
        userId: loggedInUserId,
        movieId: widget.movie.id,
        movieTitle: widget.movie.title,
        moviePosterPath: widget.movie.posterPath ?? '',
        rentalStartUtc: rentalStartUtc,
        rentalEndUtc: rentalEndUtc,
        pricePaid: _displayedPrice!,
        currencyCodePaid: _selectedCurrencyCode!,
      );

      await DatabaseHelper.instance.insertRental(newRental);
      
      await _notificationService.showPaymentSuccessNotification(widget.movie.title);
      await _notificationService.scheduleWatchReminder(widget.movie.title, widget.movie.id, rentalStartUtc);
      // Gunakan rentalEndUtc yang dinamis untuk notifikasi habis sewa (jika tidak dalam mode tes)
      await _notificationService.scheduleExpiryReminder(widget.movie.title, widget.movie.id, rentalEndUtc); 
      // await _notificationService.scheduleExpiryReminder(widget.movie.title, widget.movie.id, rentalStartUtc); // Untuk tes 3 menit
      
      print("PaymentScreen: Semua notifikasi telah diproses/dijadwalkan.");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Film "${widget.movie.title}" berhasil disewa!'), backgroundColor: Colors.green),
        );
        
        int popCount = 0;
        Navigator.popUntil(context, (route) {
          popCount++;
          return popCount >= 2 || !Navigator.canPop(context); 
        });
      }

    } catch (e) {
      print("Error saat proses pembayaran: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses penyewaan: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    } finally { if (mounted) setState(() { _isLoadingDetails = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Pembayaran: ${widget.movie.title}'),
      ),
      body: _isLoadingDetails && _displayedPrice == null 
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _displayedPrice == null
              ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 16), textAlign: TextAlign.center,)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Detail Film:', style: theme.textTheme.headlineSmall?.copyWith(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(widget.movie.title, style: theme.textTheme.titleLarge?.copyWith(fontSize: 22)),
                      if (widget.movie.tagline != null && widget.movie.tagline!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text('"${widget.movie.tagline!}"', style: theme.textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic)),
                        ),
                      const SizedBox(height: 24),

                      Text('Pilih Durasi Sewa:', style: theme.textTheme.headlineSmall?.copyWith(fontSize: 18)),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<RentalDurationOption>(
                        decoration: InputDecoration(
                          labelText: 'Durasi Penyewaan',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
                        ),
                        value: _selectedRentalDuration,
                        items: SUPPORTED_RENTAL_DURATIONS.map((RentalDurationOption option) {
                          return DropdownMenuItem<RentalDurationOption>(
                            value: option,
                            child: Text(option.label),
                          );
                        }).toList(),
                        onChanged: _isCalculatingPrice ? null : (RentalDurationOption? newValue) {
                          if (newValue != null) {
                            // Panggil _calculateBasePriceIdrAndUpdateDisplay saat durasi berubah
                            _calculateBasePriceIdrAndUpdateDisplay(newValue);
                            // Update state _selectedRentalDuration juga penting
                            setState(() {
                              _selectedRentalDuration = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      Text('Mata Uang & Harga:', style: theme.textTheme.headlineSmall?.copyWith(fontSize: 18)),
                      const SizedBox(height: 10),
                      if (_availableCurrencies.isNotEmpty)
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Pilih Mata Uang',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
                          ),
                          value: _selectedCurrencyCode,
                          items: _availableCurrencies.map((SupportedCountry country) {
                            return DropdownMenuItem<String>(
                              value: country.currencyCode,
                              child: Text('${country.countryName} (${country.currencyCode}) - ${country.currencySymbol}', overflow: TextOverflow.ellipsis,),
                            );
                          }).toList(),
                          onChanged: _isCalculatingPrice ? null : (String? newValue) {
                            if (newValue != null) {
                              final selectedCountryData = _availableCurrencies.firstWhere((c) => c.currencyCode == newValue);
                              _updateDisplayedPriceForCurrency(selectedCountryData.currencyCode, selectedCountryData.currencySymbol);
                            }
                          },
                        ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                               Text('Total Pembayaran:', style: theme.textTheme.titleMedium),
                               const SizedBox(height: 8),
                              _isCalculatingPrice 
                                ? const CircularProgressIndicator(strokeWidth: 2)
                                : _displayedPrice != null
                                  ? Text(
                                      // Menggunakan NumberFormat untuk format mata uang
                                      NumberFormat.currency(
                                        locale: _selectedCurrencyCode == 'IDR' ? 'id_ID' : 'en_US', // Sesuaikan locale
                                        symbol: '$_selectedCurrencySymbol ',
                                        decimalDigits: (_selectedCurrencyCode == 'IDR' || _selectedCurrencyCode == 'JPY') ? 0 : 2,
                                      ).format(_displayedPrice),
                                      style: theme.textTheme.headlineSmall?.copyWith(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 22),
                                    )
                                  : _error != null 
                                      ? Text(_error!, style: const TextStyle(color: Colors.redAccent))
                                      : const Text('Harga tidak tersedia', style: TextStyle(color: Colors.orangeAccent)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: _isLoadingDetails ? Container(width: 20, height: 20, margin: const EdgeInsets.only(right:8), child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.payment_rounded),
                        label: Text(_isLoadingDetails ? 'Memproses...' : 'Bayar Sekarang'),
                        style: theme.elevatedButtonTheme.style,
                        onPressed: _isLoadingDetails || _isCalculatingPrice ? null : _processPayment,
                      ),
                    ],
                  ),
                ),
    );
  }
}