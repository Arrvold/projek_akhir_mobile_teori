import 'package:flutter/material.dart';
import '../../history/screens/rental_history_screen.dart'; // <-- IMPORT BARU

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Saya'),
        // backgroundColor: theme.primaryColor, // Jika ingin konsisten
      ),
      body: SingleChildScrollView(
        // Agar bisa scroll jika konten banyak
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start, // Ubah ke start
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20), // Spasi dari atas
              const CircleAvatar(
                radius: 60,
                // backgroundImage: AssetImage('assets/images/profile_picture.jpg'),
                child: Icon(Icons.person, size: 60),
              ),
              const SizedBox(height: 20),
              Text(
                'ARJIKUSNA MAHARJANTA',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'NIM: 123220072',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Kelas: [TPM IF-B]',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 10),
              // Tombol untuk ke Histori Penyewaan
              ListTile(
                leading: Icon(Icons.history, color: theme.primaryColor),
                title: Text(
                  'Histori Penyewaan',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RentalHistoryScreen(),
                    ),
                  );
                },
              ),
              // Anda bisa menambahkan item lain di sini (mis. Pengaturan, Bantuan, dll.)
              // ListTile(
              //   leading: Icon(Icons.settings_outlined, color: theme.primaryColor),
              //   title: Text('Pengaturan', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              //   trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              //   onTap: () { /* ... */ },
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
