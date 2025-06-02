import 'package:flutter/material.dart';
import '../../../core/config/constants.dart';
import '../../../data/models/movie_detail_model.dart'; 
import '../../../data/sources/local/database_helper.dart';
import '../../../data/sources/local/preferences_helper.dart';
import '../../../services/currency_service.dart';
import '../../../services/location_service.dart';
import '../../../services/notification_service.dart'; 
import '../../../data/models/rental_model.dart';


class PaymentScreen extends StatefulWidget {
  final MovieDetailModel movie; // Terima MovieDetailModel

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
  double? _displayedPrice;
  bool _isLoading = true;
  String? _error;
  List<SupportedCountry> _availableCurrencies = SUPPORTED_COUNTRIES;
  RentalDurationOption _selectedRentalDuration = SUPPORTED_RENTAL_DURATIONS.firstWhere(
      (opt) => opt.duration.inHours == RENTAL_DURATION_HOURS, 
      orElse: () => SUPPORTED_RENTAL_DURATIONS[1] 
  ); 

  @override
  void initState() {
    super.initState();
    _initializePaymentDetails();
  }

  Future<void> _initializePaymentDetails() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      String? deviceCountryCode = await _locationService.getCurrentCountryCode();
      String targetCurrency = FALLBACK_CURRENCY_CODE; // Default ke USD
      String targetSymbol = SUPPORTED_COUNTRIES.firstWhere((c) => c.currencyCode == FALLBACK_CURRENCY_CODE).currencySymbol;


      if (deviceCountryCode != null) {
        final supportedCountry = _currencyService.getSupportedCountryByCode(deviceCountryCode);
        if (supportedCountry != null) {
          targetCurrency = supportedCountry.currencyCode;
          targetSymbol = supportedCountry.currencySymbol;
        }
      }
      
      await _updatePriceForCurrency(targetCurrency, targetSymbol);

    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); });
      // Jika error, coba tampilkan harga default dalam IDR atau USD
      await _updatePriceForCurrency(BASE_CURRENCY_CODE, SUPPORTED_COUNTRIES.firstWhere((c) => c.currencyCode == BASE_CURRENCY_CODE).currencySymbol);

    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _updatePriceForCurrency(String currencyCode, String currencySymbol) async {
     if (!mounted) return;
     setState(() { _isLoading = true; }); // Tampilkan loading saat ganti mata uang
    try {
      double? price = await _currencyService.getPriceInCurrency(currencyCode);
      if (mounted) {
        setState(() {
          _selectedCurrencyCode = currencyCode;
          _selectedCurrencySymbol = currencySymbol;
          _displayedPrice = price;
        });
      }
    } catch (e) {
       if (mounted) setState(() { _error = "Gagal mengkonversi mata uang."; });
    } finally {
       if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _processPayment() async {
    if (_displayedPrice == null || _selectedCurrencyCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Informasi harga tidak tersedia.")));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      //Dapatkan ID pengguna login
      int? loggedInUserId = await PreferencesHelper.getLoggedInUserId();

      if (loggedInUserId == null) {
        throw Exception("Sesi pengguna tidak ditemukan. Silakan login kembali.");
      }

      DateTime rentalStartUtc = DateTime.now().toUtc();
      Duration selectedDuration = _selectedRentalDuration.duration;
      DateTime rentalEndUtc = rentalStartUtc.add(selectedDuration);

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

      //NOTIFIKASI
      await _notificationService.showPaymentSuccessNotification(widget.movie.title);
      await _notificationService.scheduleWatchReminder(widget.movie.title, widget.movie.id, rentalStartUtc);
      await _notificationService.scheduleExpiryReminder(widget.movie.title, widget.movie.id, rentalEndUtc);
      
      print("Notifikasi akan dijadwalkan (placeholder)");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Film "${widget.movie.title}" berhasil disewa!'), backgroundColor: Colors.green),
        );
        // Kembali 2 kali: dari payment screen, lalu dari detail screen
        int popCount = 0;
        Navigator.popUntil(context, (route) {
          popCount++;
          return popCount == 3 || !Navigator.canPop(context); // Pop 2x atau sampai root
        });
      }

    } catch (e) {
      print("Error saat proses pembayaran: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses penyewaan: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
       if (mounted) setState(() { _isLoading = false; });
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Pembayaran: ${widget.movie.title}'),
      ),
      body: _isLoading && _displayedPrice == null // Hanya loading awal
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _displayedPrice == null // Error saat init dan tidak ada harga
              ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Colors.red))))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Detail Film:', style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(widget.movie.title, style: theme.textTheme.titleLarge?.copyWith(fontSize: 20)),
                      if (widget.movie.tagline != null && widget.movie.tagline!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text('"${widget.movie.tagline!}"', style: theme.textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic)),
                        ),
                      const SizedBox(height: 20),
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
                        onChanged: (RentalDurationOption? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedRentalDuration = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      Text('Mata Uang & Harga:', style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 10),
                      if (_availableCurrencies.isNotEmpty)
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Pilih Mata Uang',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                          ),
                          value: _selectedCurrencyCode,
                          items: _availableCurrencies.map((SupportedCountry country) {
                            return DropdownMenuItem<String>(
                              value: country.currencyCode,
                              child: Text('${country.countryName} (${country.currencyCode}) - ${country.currencySymbol}'),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              final selected = _availableCurrencies.firstWhere((c) => c.currencyCode == newValue);
                              _updatePriceForCurrency(selected.currencyCode, selected.currencySymbol);
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
                              _isLoading && _displayedPrice != null // Loading saat ganti mata uang
                                ? const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: CircularProgressIndicator(strokeWidth: 2))
                                : _displayedPrice != null
                                  ? Text(
                                      '${_selectedCurrencySymbol} ${_displayedPrice?.toStringAsFixed(2)}', // Format 2 desimal
                                      style: theme.textTheme.headlineSmall?.copyWith(color: theme.primaryColor, fontWeight: FontWeight.bold),
                                    )
                                  : const Text('Harga tidak tersedia', style: TextStyle(color: Colors.orange)),
                              if(_error != null && _displayedPrice != null) // error saat ganti mata uang
                                Padding(
                                  padding: const EdgeInsets.only(top:8.0),
                                  child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: _isLoading ? Container(width: 20, height: 20, margin: const EdgeInsets.only(right:8), child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.payment),
                        label: Text(_isLoading ? 'Memproses...' : 'Bayar Sekarang'),
                        style: theme.elevatedButtonTheme.style?.copyWith(
                          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
                        ),
                        onPressed: _isLoading ? null : _processPayment,
                      ),
                    ],
                  ),
                ),
    );
  }
}