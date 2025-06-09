import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

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
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_notification_icon');

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
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
        }
      },
      onDidReceiveBackgroundNotificationResponse:
          notificationTapBackground, 
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
    
    final bool? alarmGranted = await androidImplementation!.requestExactAlarmsPermission();
    print("Izin alarm presisi Android diberikan: $alarmGranted");


    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'rental_channel',
      'Notifikasi Penyewaan Film', 
      description:
          'Channel untuk notifikasi terkait penyewaan film.', 
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


  Future<void> showSimpleNotification({
    required int id,
    required String title,
    required String body,
    String? payload, 
  }) async {
    const AndroidNotificationDetails
    androidNotificationDetails = AndroidNotificationDetails(
      'rental_channel', 
      'Notifikasi Penyewaan Film',
      channelDescription: 'Channel untuk notifikasi terkait penyewaan film.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
    
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

  //fungsi penjadwalan notifikasi
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTimeUtc,
    String? payload,
  }) async {
    try {

      final String localTimezone = await FlutterTimezone.getLocalTimezone();
      final tz.Location location = tz.getLocation(localTimezone);


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
                .exactAllowWhileIdle, 
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      print("Notification scheduled successfully for $scheduledDate");
    } catch (e) {
      print("Error scheduling notification: $e");
    }
  }

  // wrapper spesifik untuk notifikasi aplikasi

  static const int paymentSuccessId = 0;
  static const int watchReminderIdBase =
      1000; 
  static const int expiryReminderIdBase =
      2000;

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
      id: watchReminderIdBase + movieId, 
      title: 'Saatnya Menonton!',
      body:
          'Jangan lupa untuk menonton film "$movieTitle" yang baru saja Anda sewa.',
      scheduledDateTimeUtc: rentalStartTimeUtc.add(
        const Duration(minutes: 1),
      ), 
      payload: 'watch_reminder_$movieId',
    );
  }

  Future<void> scheduleExpiryReminder(
    String movieTitle,
    int movieId,
    DateTime rentalEndTimeUtc,
  ) async {
    await scheduleNotification(
      id: expiryReminderIdBase + movieId, 
      title: 'Waktu Sewa Segera Habis!',
      body: 'Waktu sewa untuk film "$movieTitle" akan berakhir dalam 1 jam.',
      scheduledDateTimeUtc: rentalEndTimeUtc.subtract(
        const Duration(hours: 1),
      ), 
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

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {

  print(
    'Notification Tapped in Background: payload=${notificationResponse.payload}',
  );

}
