import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart'; // Untuk mendapatkan zona waktu lokal IANA

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();
  factory NotificationService() {
    return _notificationService;
  }
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    // Pengaturan inisialisasi untuk Android
    // Ganti 'app_notification_icon' dengan nama file ikon notifikasi Anda (tanpa ekstensi)
    // yang ada di android/app/src/main/res/drawable/
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_notification_icon');

    // Pengaturan inisialisasi untuk iOS
    final DarwinInitializationSettings
    initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission:
          true, // Default true, bisa false jika Anda handle permintaan izin terpisah
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
          macOS: initializationSettingsDarwin, // Bisa pakai setting Darwin juga
        );

    // Inisialisasi plugin
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (
        NotificationResponse notificationResponse,
      ) async {
        // Handle saat notifikasi di-tap
        final String? payload = notificationResponse.payload;
        if (payload != null) {
          print('NOTIFICATION PAYLOAD: $payload');
          // Di sini Anda bisa navigasi ke halaman tertentu berdasarkan payload
          // Misalnya: if (payload == 'payment_success') { ... }
        }
      },
      onDidReceiveBackgroundNotificationResponse:
          notificationTapBackground, // Untuk background
    );

    // Minta izin notifikasi untuk Android 13+
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (androidImplementation != null) {
      final bool? granted =
          await androidImplementation.requestNotificationsPermission();
      print("Izin notifikasi Android 13+ diberikan: $granted");
    }
    // Minta izin alarm presisi (jika diperlukan, tergantung versi plugin & target Android)
    final bool? alarmGranted = await androidImplementation!.requestExactAlarmsPermission();
    print("Izin alarm presisi Android diberikan: $alarmGranted");

    // Buat Channel Notifikasi (Untuk Android 8.0+)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'rental_channel', // id
      'Notifikasi Penyewaan Film', // title
      description:
          'Channel untuk notifikasi terkait penyewaan film.', // description
      importance: Importance.max,
      playSound: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    print("Notification service initialized.");
  }

  // Fungsi untuk menampilkan notifikasi langsung
  Future<void> showSimpleNotification({
    required int id,
    required String title,
    required String body,
    String? payload, // Data tambahan yang dikirim saat notifikasi di-tap
  }) async {
    const AndroidNotificationDetails
    androidNotificationDetails = AndroidNotificationDetails(
      'rental_channel', // Gunakan ID channel yang sama
      'Notifikasi Penyewaan Film',
      channelDescription: 'Channel untuk notifikasi terkait penyewaan film.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      // icon: 'app_notification_icon', // Bisa diset di sini juga atau default dari inisialisasi
    );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(presentSound: true),
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
    print("Simple notification shown: id=$id, title=$title");
  }

  // Fungsi untuk menjadwalkan notifikasi
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTimeUtc, // Waktu harus dalam UTC
    String? payload,
  }) async {
    try {
      // Dapatkan zona waktu lokal perangkat
      final String localTimezone = await FlutterTimezone.getLocalTimezone();
      final tz.Location location = tz.getLocation(localTimezone);

      // Konversi waktu UTC terjadwal ke TZDateTime di zona waktu lokal
      // Ini penting agar penjadwalan akurat menurut jam perangkat
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
        scheduledDateTimeUtc,
        location,
      );

      print(
        "Scheduling notification: id=$id, title=$title, time=$scheduledDate ($localTimezone)",
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'rental_channel',
            'Notifikasi Penyewaan Film',
            channelDescription:
                'Channel untuk notifikasi terkait penyewaan film.',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(presentSound: true),
        ),
        androidScheduleMode:
            AndroidScheduleMode
                .exactAllowWhileIdle, // Untuk penjadwalan yang lebih presisi
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
        // matchDateTimeComponents: DateTimeComponents.time, // Atau sesuaikan jika perlu mencocokkan tanggal juga
      );
      print("Notification scheduled successfully for $scheduledDate");
    } catch (e) {
      print("Error scheduling notification: $e");
    }
  }

  // --- Wrapper Spesifik untuk Notifikasi Aplikasi Anda ---

  // ID Notifikasi (gunakan ID unik untuk setiap jenis notifikasi jika perlu dibatalkan terpisah)
  static const int paymentSuccessId = 0;
  static const int watchReminderIdBase =
      1000; // Base ID, tambahkan movieId untuk unik
  static const int expiryReminderIdBase =
      2000; // Base ID, tambahkan movieId untuk unik

  Future<void> showPaymentSuccessNotification(String movieTitle) async {
    await showSimpleNotification(
      id: paymentSuccessId,
      title: 'Pembayaran Berhasil!',
      body: 'Anda telah berhasil menyewa film "$movieTitle". Selamat menonton!',
      payload: 'payment_success_${movieTitle.hashCode}',
    );
  }

  Future<void> scheduleWatchReminder(
    String movieTitle,
    int movieId,
    DateTime rentalStartTimeUtc,
  ) async {
    await scheduleNotification(
      id: watchReminderIdBase + movieId, // ID unik per film
      title: 'Saatnya Menonton!',
      body:
          'Jangan lupa untuk menonton film "$movieTitle" yang baru saja Anda sewa.',
      scheduledDateTimeUtc: rentalStartTimeUtc.add(
        const Duration(minutes: 1),
      ), // 1 menit setelah sewa
      payload: 'watch_reminder_$movieId',
    );
  }

  Future<void> scheduleExpiryReminder(
    String movieTitle,
    int movieId,
    DateTime rentalEndTimeUtc,
  ) async {
    await scheduleNotification(
      id: expiryReminderIdBase + movieId, // ID unik per film
      title: 'Waktu Sewa Segera Habis!',
      body: 'Waktu sewa untuk film "$movieTitle" akan berakhir dalam 1 jam.',
      scheduledDateTimeUtc: rentalEndTimeUtc.subtract(
        const Duration(hours: 1),
      ), // 1 jam sebelum habis
      payload: 'expiry_reminder_$movieId',
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    print("Notification cancelled: id=$id");
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    print("All notifications cancelled");
  }
}

// Callback untuk handle tap notifikasi saat aplikasi di background (Android)
// Ini harus top-level function atau static method
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {

  print(
    'Notification Tapped in Background: payload=${notificationResponse.payload}',
  );

}
