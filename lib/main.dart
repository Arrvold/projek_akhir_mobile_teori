import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tzdata; 
import 'package:timezone/timezone.dart' as tz;      
import 'package:flutter_timezone/flutter_timezone.dart';
import 'presentation/splash/screens/splash_screen.dart';
import 'presentation/auth/screens/login_screen.dart';
import 'presentation/auth/screens/register_screen.dart';
import 'presentation/main_layout/main_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi data zona waktu
  tzdata.initializeTimeZones();
  // Set zona waktu lokal
  try {
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));
    print("Zona waktu lokal diset untuk package timezone: $currentTimeZone");
  } catch (e) {
    print("Gagal mengatur zona waktu lokal untuk package timezone: $e. Menggunakan UTC sebagai fallback.");
  }


  // Inisialisasi Notification Service
  await NotificationService().initNotifications();
  print("MAIN.DART: Notification service initialized.");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sewa Film App',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        primaryColor: Colors.indigo[700], 
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Poppins', 
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0), 
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100], 
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 16.0,
          ),
          prefixIconColor: Colors.indigo[300],
          suffixIconColor: Colors.indigo[300],
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              vertical: 14.0,
              horizontal: 24.0,
            ),
            textStyle: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 2, // Sedikit shadow
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.indigo[600],
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 26.0,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          headlineSmall: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          titleMedium: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
          bodyMedium: TextStyle(fontSize: 14.0, color: Colors.black54),
          bodyLarge: TextStyle(
            fontSize: 16.0,
            color: Colors.black87,
            height: 1.4,
          ),
          labelLarge: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ), // Untuk teks di ElevatedButton
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.indigo[700],
          unselectedItemColor: Colors.grey[500],
          backgroundColor: Colors.white,
          elevation: 8.0, // Shadow untuk bottom nav bar
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.indigo[700],
          foregroundColor:
              Colors.white, // Warna untuk title dan icons di AppBar
          elevation: 0, // AppBar tanpa shadow jika menyatu dengan body
          titleTextStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        chipTheme: ChipThemeData(
          // Tema untuk ChoiceChip (filter genre)
          backgroundColor: Colors.grey[200],
          selectedColor: Colors.indigo[600],
          labelStyle: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.normal,
          ),
          secondaryLabelStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.normal,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
        cardTheme: CardTheme(
          // Tema untuk Card
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        ),
      ),
      debugShowCheckedModeBanner: false, // Hilangkan banner debug
      // Tentukan halaman awal berdasarkan status login
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}
