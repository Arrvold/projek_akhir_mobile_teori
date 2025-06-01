import 'package:flutter/material.dart';
// TAMBAHKAN IMPORT INI:
import '../../../data/sources/local/preferences_helper.dart';

class ImpressionsScreen extends StatelessWidget {
  const ImpressionsScreen({super.key});

  // UBAH MENJADI ASYNC DAN TAMBAHKAN PEMANGGILAN clearUserSession
  Future<void> _logout(BuildContext context) async { // Jadikan async
    // Hapus sesi pengguna dari SharedPreferences
    await PreferencesHelper.clearUserSession();

    // Cek apakah widget masih terpasang sebelum navigasi dan menampilkan SnackBar
    if (!context.mounted) return;

    // Navigasi kembali ke halaman login dan hapus semua rute sebelumnya
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Anda telah berhasil logout.'), // Ubah pesan
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kesan Pesan'),
        // backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Kesan dan Pesan untuk Mata Kuliah Pemrograman Mobile:',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2.0,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'TPM SANGAT MENYENANGKAN, TUGASNYA SEDIKIT DAN DEADLINE NYA PANJANG :)',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                  textAlign: TextAlign.justify,
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {
                _logout(context);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                textStyle: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}