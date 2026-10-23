import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'soil_status_helper.dart';
import '../main.dart'; // Untuk mengakses kFirebaseDatabaseUrl

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _isFirstLoad = true;
  static String? _lastStatusTanah;
  static bool _lastPompaState = false;

  // Variabel untuk Auto-Logging Riwayat Harian (setiap 10 menit saat sensor aktif)
  static DateTime? _lastAutoSaveTime;
  static const int _autoSaveIntervalMinutes = 10;

  // Variabel Cooldown Notifikasi (1 Jam agar tidak spamming notifikasi yang sama)
  static DateTime? _lastWarningNotificationTime;
  static const Duration _warningNotificationCooldown = Duration(hours: 1);

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(settings: initializationSettings);

    // Meminta izin notifikasi untuk Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    _listenToFirebase();
  }

  static void _listenToFirebase() {
    FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kFirebaseDatabaseUrl,
    ).ref('monitoring_sawi').onValue.listen((event) {
      if (event.snapshot.value == null) return;

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final String currentStatus =
          (data['status_tanah']?.toString() ?? "SESUAI").toUpperCase().trim();

      // AUTO-LOGGING RIWAYAT SENSOR (Setiap 10 Menit saat Alat Aktif)
      _checkAndAutoSaveHistory(data);

      // Silent background logging: simpan riwayat penyiraman jika pompa selesai
      bool pompaAktif = data['pompa_aktif'] == true;
      if (_lastPompaState && !pompaAktif) {
        double kelembaban = (data['kelembaban'] ?? 0).toDouble();
        String modeSistem = data['mode_sistem']?.toString() ?? "Otomatis";
        _saveWateringHistory(kelembaban: kelembaban, mode: modeSistem);
      }
      _lastPompaState = pompaAktif;

      // CEGAH SPAM SAAT STARTUP:
      // Data pertama kali yang diterima saat inisialisasi aplikasi tidak memicu notifikasi.
      if (_isFirstLoad) {
        _isFirstLoad = false;
        _lastStatusTanah = currentStatus;
        return;
      }

      // LOGIKA COOLDOWN NOTIFIKASI:
      // Jika status "PERLU PERBAIKAN", ESP32 mungkin akan terus mengirimkan status tersebut.
      // Notifikasi hanya dikirim jika:
      // 1. Status baru saja berubah menjadi "PERLU PERBAIKAN" (transisi anomali baru), ATAU
      // 2. Masa cooldown (1 jam) sudah berakhir dan kondisi masih "PERLU PERBAIKAN".
      if (currentStatus == "PERLU PERBAIKAN") {
        final now = DateTime.now();
        final bool isNewAnomaly = _lastStatusTanah != "PERLU PERBAIKAN";
        final bool cooldownExpired =
            _lastWarningNotificationTime == null ||
            now.difference(_lastWarningNotificationTime!) >=
                _warningNotificationCooldown;

        if (isNewAnomaly || cooldownExpired) {
          _lastWarningNotificationTime = now;

          // == PERBAIKAN DI SINI ==
          // Ambil daftar parameter yang tidak optimal menggunakan SoilStatusHelper
          List<String> anomalyList = SoilStatusHelper.getAnomalyParameters(
            data,
          );
          String detailPesan = anomalyList.isNotEmpty
              ? "Parameter di luar rentang: ${anomalyList.join(', ')}. Silakan buka aplikasi untuk melihat rekomendasi."
              : "Status tanah: PERLU PERBAIKAN. Silakan buka aplikasi untuk melihat rekomendasi tindakan.";

          _showPushNotification(
            id: 101,
            title: "⚠️ Peringatan Kondisi Tanah",
            body: detailPesan, // Menggunakan detail parameter spesifik
          );

          _saveNotificationToFirebase(
            title: "⚠️ Kondisi Tanah: PERLU PERBAIKAN",
            message: detailPesan, // Disimpan juga dengan detail ke database
            type: "warning",
          );
        }
      } else if (currentStatus == "SESUAI") {
        _lastWarningNotificationTime = null;
      }

      _lastStatusTanah = currentStatus;
    });
  }

  // Fungsi auto-logging otomatis saat alat hidup
  static Future<void> _checkAndAutoSaveHistory(
    Map<String, dynamic> data,
  ) async {
    // 1. Cek apakah sensor sedang aktif (heartbeat timestamp <= 2 menit)
    int? timestampMs;
    if (data['timestamp'] != null) {
      if (data['timestamp'] is int) {
        int rawTs = data['timestamp'] as int;
        timestampMs = rawTs < 10000000000 ? rawTs * 1000 : rawTs;
      } else if (data['timestamp'] is num) {
        num rawTs = data['timestamp'] as num;
        timestampMs = rawTs < 10000000000
            ? (rawTs * 1000).toInt()
            : rawTs.toInt();
      } else if (data['timestamp'] is String) {
        timestampMs = DateTime.tryParse(
          data['timestamp'],
        )?.millisecondsSinceEpoch;
      }
    }
    if (timestampMs == null && data['last_updated'] != null) {
      if (data['last_updated'] is int) {
        int rawTs = data['last_updated'] as int;
        timestampMs = rawTs < 10000000000 ? rawTs * 1000 : rawTs;
      } else if (data['last_updated'] is num) {
        num rawTs = data['last_updated'] as num;
        timestampMs = rawTs < 10000000000
            ? (rawTs * 1000).toInt()
            : rawTs.toInt();
      } else if (data['last_updated'] is String) {
        timestampMs = DateTime.tryParse(
          data['last_updated'],
        )?.millisecondsSinceEpoch;
      }
    }

    // Periksa status aktif
    bool isAlive = true;
    if (timestampMs != null) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final diffMinutes = (nowMs - timestampMs).abs() / (1000 * 60);
      if (diffMinutes > 2.0) {
        isAlive = false;
      }
    }

    // Jika sensor mati / offline, jangan simpan riwayat palsu
    if (!isAlive) return;

    final now = DateTime.now();
    // Cek selisih waktu dari penyimpanan terakhir (minimal interval 10 menit)
    if (_lastAutoSaveTime != null &&
        now.difference(_lastAutoSaveTime!).inMinutes <
            _autoSaveIntervalMinutes) {
      return;
    }

    _lastAutoSaveTime = now;

    final String dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final String timeStr =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final String recordKey =
        "${dateStr}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}";

    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kFirebaseDatabaseUrl,
    );

    await db.ref('riwayat_harian/$recordKey').set({
      'tanggal': dateStr,
      'waktu': timeStr,
      'tanggal_lengkap': "$dateStr $timeStr",
      'kelembaban': data['kelembaban'],
      'ph': data['ph'],
      'suhu': data['suhu'],
      'n': data['n'],
      'p': data['p'],
      'k': data['k'],
      'status_tanah': data['status_tanah'] ?? 'SESUAI',
      'tipe': 'Otomatis',
      'timestamp': ServerValue.timestamp,
    });
  }

  static Future<void> _showPushNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'agrifis_alert_channel',
          'Peringatan AgriFIS',
          channelDescription: 'Saluran notifikasi kondisi tanah Smart AgriFIS',
          importance: Importance.max,
          priority: Priority.max,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }

  static void _saveNotificationToFirebase({
    required String title,
    required String message,
    required String type,
  }) {
    final now = DateTime.now();
    final dateStr =
        "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}";

    FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kFirebaseDatabaseUrl,
    ).ref('notifications').push().set({
      'title': title,
      'message': message,
      'type': type,
      'date': dateStr,
      'timestamp': ServerValue.timestamp,
    });
  }

  static void _saveWateringHistory({
    required double kelembaban,
    required String mode,
  }) {
    final now = DateTime.now();
    final dateStr = "${now.day}/${now.month}/${now.year}";
    final timeStr = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";

    FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kFirebaseDatabaseUrl,
    ).ref('riwayat_penyiraman').push().set({
      'kelembaban': kelembaban.toStringAsFixed(1),
      'waktu': timeStr,
      'tanggal_lengkap': dateStr,
      'tipe': mode,
      'timestamp': ServerValue.timestamp,
    });
  }
}
