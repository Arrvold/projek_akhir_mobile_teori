import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk NumberFormat
import '../../../data/models/rental_model.dart';
import '../../../data/sources/local/database_helper.dart';
import '../../../data/sources/local/preferences_helper.dart';
import '../../../services/time_service.dart';
import '../../../services/location_service.dart';
import '../../../core/config/constants.dart'; // Untuk SUPPORTED_COUNTRIES, WIB, WITA, WIT, FALLBACK_TIMEZONE_NAME
// Import MovieDetailScreen jika Anda ingin navigasi ke detail dari histori
import '../../movie_detail/screens/movie_detail_screen.dart';
// Import MovieModel jika Anda berencana navigasi ke MovieDetailScreen yang mungkin menerimanya
// import '../../../data/models/movie_model.dart';


class RentalHistoryScreen extends StatefulWidget {
  const RentalHistoryScreen({super.key});

  @override
  State<RentalHistoryScreen> createState() => _RentalHistoryScreenState();
}

class _RentalHistoryScreenState extends State<RentalHistoryScreen> {
  List<RentalModel> _rentalHistory = [];
  bool _isLoading = true;
  String? _error;

  final TimeService _timeService = TimeService(); // Inisialisasi TimeService
  final LocationService _locationService = LocationService(); // Inisialisasi LocationService
  
  String _deviceEffectiveTimeZoneName = FALLBACK_TIMEZONE_NAME; // Zona waktu efektif awal
  String? _selectedDisplayTimeZone; // Zona waktu yang dipilih pengguna untuk display

  List<Map<String, String>> _displayableTimezones = []; // Daftar untuk dropdown

  @override
  void initState() {
    super.initState();
    _prepareTimezonesAndLoadHistory();
  }

  void _prepareDisplayableTimezones() {
    final Set<String> uniqueIanaNames = {};
    final List<Map<String, String>> timezones = [];

    // Fungsi helper untuk menambahkan zona waktu ke daftar jika unik
    void addUniqueTimezone(String iana, String displayName) {
      if (uniqueIanaNames.add(iana)) {
        timezones.add({'iana': iana, 'name': displayName});
      }
    }

    // Tambahkan zona waktu spesifik Indonesia di awal
    addUniqueTimezone(WIB, 'Indonesia (WIB)');
    addUniqueTimezone(WITA, 'Indonesia (WITA)');
    addUniqueTimezone(WIT, 'Indonesia (WIT)');

    // Tambahkan zona waktu dari SUPPORTED_COUNTRIES
    for (var country in SUPPORTED_COUNTRIES) {
      String displayName = '${country.countryName} (${country.timeZoneName.split('/').last.replaceAll('_', ' ')})';
      addUniqueTimezone(country.timeZoneName, displayName);
    }

    // Tambahkan zona waktu efektif perangkat jika belum ada di daftar
    // Ini berguna jika zona waktu efektif perangkat adalah hasil fallback (mis. London)
    // atau zona waktu IANA valid lainnya yang belum tercakup.
    if (_deviceEffectiveTimeZoneName.isNotEmpty) {
       addUniqueTimezone(_deviceEffectiveTimeZoneName, 'Default Perangkat (${_deviceEffectiveTimeZoneName.split('/').last.replaceAll('_', ' ')})');
    }


    // Urutkan berdasarkan nama untuk tampilan yang lebih baik
    timezones.sort((a, b) => a['name']!.compareTo(b['name']!));
    
    if (mounted) {
      setState(() {
        _displayableTimezones = timezones;
      });
    }
  }

  Future<void> _prepareTimezonesAndLoadHistory() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      String? deviceCountryCode = await _locationService.getCurrentCountryCode();
      String? deviceActualTimeZone = await _locationService.getCurrentTimeZoneName();
      
      if (mounted) {
         _deviceEffectiveTimeZoneName = _timeService.getEffectiveTimeZoneName(
          currentDeviceActualTimeZone: deviceActualTimeZone,
          deviceCountryCode: deviceCountryCode,
        );
        _selectedDisplayTimeZone = _deviceEffectiveTimeZoneName; // Default ke zona waktu efektif perangkat
        
        _prepareDisplayableTimezones(); // Siapkan daftar zona waktu untuk dropdown setelah _deviceEffectiveTimeZoneName diketahui

        print("RentalHistoryScreen: Zona Waktu Display Awal = $_selectedDisplayTimeZone");
        await _loadRentalHistory();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Gagal menentukan info lokasi/zona waktu: ${e.toString()}";
          _isLoading = false; 
        });
      }
    }
  }

  Future<void> _loadRentalHistory() async {
    if (!mounted) return;
    // Jika tidak sedang loading dari _prepareTimezonesAndLoadHistory, set loading true
    if (!_isLoading) setState(() { _isLoading = true; _error = null; });

    try {
      int? userId = await PreferencesHelper.getLoggedInUserId();
      if (userId == null) {
        if (mounted) {
          setState(() {
             _error = "Pengguna belum login. Tidak bisa memuat histori.";
             _isLoading = false; // Set loading false karena ini error terminal
          });
        }
        return;
      }
      final history = await DatabaseHelper.instance.getRentalsForUser(userId);
      if (mounted) {
        setState(() {
          _rentalHistory = history;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Gagal memuat histori penyewaan: ${e.toString()}";
        });
      }
      print("Error loading rental history: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getCurrencySymbol(String currencyCode) {
    try {
      return SUPPORTED_COUNTRIES.firstWhere((c) => c.currencyCode == currencyCode).currencySymbol;
    } catch (e) {
      return currencyCode; 
    }
  }

  // Fungsi untuk navigasi ke detail film jika diperlukan
  void _navigateToDetail(int movieId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailScreen(movieId: movieId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Zona waktu yang akan digunakan untuk display, berdasarkan pilihan user atau default perangkat
    final String currentTimeZoneForDisplay = _selectedDisplayTimeZone ?? _deviceEffectiveTimeZoneName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histori Penyewaan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _prepareTimezonesAndLoadHistory,
            tooltip: 'Muat Ulang',
          )
        ],
      ),
      body: Column(
        children: [
          // Dropdown untuk memilih zona waktu
          if (!_isLoading && _error == null && _displayableTimezones.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Tampilkan Waktu Dalam Zona',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                  isDense: true,
                ),
                value: _selectedDisplayTimeZone, // Harus cocok dengan salah satu value di items
                isExpanded: true,
                hint: Text(_deviceEffectiveTimeZoneName.split('/').last), // Tampilkan default jika _selectedDisplayTimeZone null
                items: _displayableTimezones.map<DropdownMenuItem<String>>((Map<String, String> tzMap) {
                  return DropdownMenuItem<String>(
                    value: tzMap['iana'],
                    child: Text(tzMap['name']!, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null && newValue != _selectedDisplayTimeZone) {
                    setState(() {
                      _selectedDisplayTimeZone = newValue;
                    });
                  }
                },
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 16), textAlign: TextAlign.center),
                        ),
                      )
                    : _rentalHistory.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.movie_filter_outlined, size: 80, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Belum ada riwayat penyewaan.',
                                    style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Film yang Anda sewa akan muncul di sini.',
                                    style: theme.textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _prepareTimezonesAndLoadHistory,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8.0),
                              itemCount: _rentalHistory.length,
                              itemBuilder: (context, index) {
                                final rental = _rentalHistory[index];
                                final currencySymbol = _getCurrencySymbol(rental.currencyCodePaid);
                                final NumberFormat currencyFormatter = NumberFormat.currency(
                                  locale: 'id_ID',
                                  symbol: '$currencySymbol ',
                                  decimalDigits: (rental.currencyCodePaid == 'IDR' || rental.currencyCodePaid == 'JPY') ? 0 : 2,
                                );
                                
                                return InkWell(
                                  onTap: () => _navigateToDetail(rental.movieId), // Panggil _navigateToDetail
                                  borderRadius: BorderRadius.circular(12.0), // Sesuaikan dengan radius Card jika Card punya shape
                                  child: Card(
                                    elevation: 2.0,
                                    margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: 80,
                                            height: 120,
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(6.0),
                                              child: Image.network(
                                                rental.moviePosterPath.isNotEmpty ? 'https://image.tmdb.org/t/p/w200${rental.moviePosterPath}' : 'https://via.placeholder.com/200x300.png?text=No+Image',
                                                fit: BoxFit.cover,
                                                errorBuilder: (ctx, err, st) => Container(color: Colors.grey[200], child: const Icon(Icons.movie_creation_outlined, color: Colors.grey, size: 30)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12.0),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  rental.movieTitle,
                                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 17),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 6.0),
                                                Text(
                                                  'Harga: ${currencyFormatter.format(rental.pricePaid)}',
                                                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.green[700]),
                                                ),
                                                const SizedBox(height: 4.0),
                                                Divider(color: Colors.grey[300], height: 10),
                                                const SizedBox(height: 4.0),
                                                Text(
                                                  'Disewa Mulai:',
                                                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                                                ),
                                                Text(
                                                  _timeService.formatDateTimeForDisplay(rental.rentalStartUtc, currentTimeZoneForDisplay),
                                                  style: theme.textTheme.bodyMedium,
                                                ),
                                                const SizedBox(height: 4.0),
                                                Text(
                                                  'Berakhir Pada:',
                                                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                                                ),
                                                Text(
                                                  _timeService.formatDateTimeForDisplay(rental.rentalEndUtc, currentTimeZoneForDisplay),
                                                  style: theme.textTheme.bodyMedium,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // onTap: () => _navigateToDetail(rental.movieId), // Jika ingin bisa diklik ke detail
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}