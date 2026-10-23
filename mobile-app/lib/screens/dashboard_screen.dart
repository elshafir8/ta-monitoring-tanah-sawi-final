import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../main.dart' show kFirebaseDatabaseUrl;
import 'notification_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

// ==========================================
// 1. FUNGSI LOGIKA AMBANG BATAS (THRESHOLD)
// ==========================================

Map<String, dynamic> cekPH(double nilai, bool isValid) {
  if (!isValid) return {"status": "TIDAK VALID", "color": Colors.grey};
  if (nilai >= 6.0 && nilai <= 7.0) {
    return {"status": "NORMAL", "color": Colors.green};
  }
  return {"status": "TIDAK IDEAL", "color": Colors.red};
}

Map<String, dynamic> cekKelembapan(double nilai, bool isValid) {
  if (!isValid) return {"status": "TIDAK VALID", "color": Colors.grey};
  if (nilai >= 50.0 && nilai <= 70.0) {
    return {"status": "OPTIMAL", "color": Colors.green};
  }
  if (nilai < 50.0) return {"status": "KERING", "color": Colors.red};
  return {"status": "BASAH", "color": Colors.blue};
}

Map<String, dynamic> cekSuhu(double nilai, bool isValid) {
  if (!isValid) return {"status": "TIDAK VALID", "color": Colors.grey};
  if (nilai >= 15.0 && nilai <= 30.0) {
    return {"status": "STABIL", "color": Colors.green};
  }
  if (nilai < 15.0) return {"status": "RENDAH", "color": Colors.blue};
  return {"status": "TINGGI", "color": Colors.red};
}

Map<String, dynamic> cekN(double nilai, bool isValid) {
  if (!isValid) return {"status": "TIDAK VALID", "color": Colors.grey};
  if (nilai >= 50.0 && nilai <= 150.0) {
    return {"status": "IDEAL", "color": Colors.green};
  }
  if (nilai < 50.0) return {"status": "RENDAH", "color": Colors.red};
  return {"status": "TINGGI", "color": Colors.orange};
}

Map<String, dynamic> cekP(double nilai, bool isValid) {
  if (!isValid) return {"status": "TIDAK VALID", "color": Colors.grey};
  if (nilai >= 15.0 && nilai <= 60.0) {
    return {"status": "IDEAL", "color": Colors.green};
  }
  if (nilai < 15.0) return {"status": "RENDAH", "color": Colors.red};
  return {"status": "TINGGI", "color": Colors.orange};
}

Map<String, dynamic> cekK(double nilai, bool isValid) {
  if (!isValid) return {"status": "TIDAK VALID", "color": Colors.grey};
  if (nilai >= 80.0 && nilai <= 200.0) {
    return {"status": "IDEAL", "color": Colors.green};
  }
  if (nilai < 80.0) return {"status": "RENDAH", "color": Colors.red};
  return {"status": "TINGGI", "color": Colors.orange};
}

Map<String, dynamic> cekSuhuUdara(double nilai, bool isValid) {
  if (!isValid) return {"status": "TIDAK VALID", "color": Colors.grey};
  if (nilai >= 22.0 && nilai <= 30.0) {
    return {"status": "NORMAL", "color": Colors.green};
  }
  if (nilai < 22.0) return {"status": "SEJUK", "color": Colors.blue};
  return {"status": "PANAS", "color": Colors.orange};
}

Map<String, dynamic> cekKelembabanUdara(double nilai, bool isValid) {
  if (!isValid) return {"status": "TIDAK VALID", "color": Colors.grey};
  if (nilai >= 50.0 && nilai <= 80.0) {
    return {"status": "IDEAL", "color": Colors.green};
  }
  if (nilai < 50.0) return {"status": "KERING", "color": Colors.orange};
  return {"status": "LEMBAB", "color": Colors.blue};
}

// ==========================================
// 2. KELAS UTAMA DASHBOARD
// ==========================================
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color.fromARGB(190, 91, 126, 60);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: const CircleAvatar(
                backgroundColor: Color(0xFFE0E0E0),
                radius: 18,
                backgroundImage: AssetImage('assets/petani.jpg'),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Smart AgriFIS',
              style: TextStyle(
                color: Color(0xFF2D5A27),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.green),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: kFirebaseDatabaseUrl,
        ).ref('monitoring_sawi').onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          double valPH = 0.0;
          double valKelembaban = 0.0;
          double valSuhu = 0.0;
          double valN = 0.0;
          double valP = 0.0;
          double valK = 0.0;
          double valSuhuUdara = 0.0;
          double valKelembabanUdara = 0.0;

          // Flag Validitas per Parameter dari Firebase
          bool phValid = true;
          bool moistureValid = true;
          bool soilTempValid = true;
          bool nValid = true;
          bool pValid = true;
          bool kValid = true;
          bool airTempValid = true;
          bool airHumValid = true;

          // Status Sensor & Mode
          String statusSensor = "Non-Aktif";
          Color warnaSensor = Colors.red;
          String modeSistem = "Otomatis";
          String statusTanah = "SESUAI";
          Map<String, dynamic> dataFirebase = {};

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            dataFirebase = Map<String, dynamic>.from(
              snapshot.data!.snapshot.value as Map,
            );

            // 1. Tampilan Nilai Sensor
            valPH = (dataFirebase['ph'] ?? 0).toDouble();
            valKelembaban = (dataFirebase['kelembaban'] ?? 0).toDouble();
            valSuhu = (dataFirebase['suhu'] ?? 0).toDouble();
            valN = (dataFirebase['n'] ?? 0).toDouble();
            valP = (dataFirebase['p'] ?? 0).toDouble();
            valK = (dataFirebase['k'] ?? 0).toDouble();
            valSuhuUdara = (dataFirebase['suhu_udara'] ?? 0).toDouble();
            valKelembabanUdara = (dataFirebase['kelembaban_udara'] ?? 0)
                .toDouble();

            // Ambil Flag Validitas dari Firebase
            phValid = dataFirebase['ph_valid'] == true;
            moistureValid = dataFirebase['moisture_valid'] == true;
            soilTempValid = dataFirebase['soil_temp_valid'] == true;
            nValid = dataFirebase['n_valid'] == true;
            pValid = dataFirebase['p_valid'] == true;
            kValid = dataFirebase['k_valid'] == true;
            airTempValid = dataFirebase['air_temp_valid'] == true;
            airHumValid = dataFirebase['air_hum_valid'] == true;

            // Perbaikan 1: Status tanah membaca string mentah dengan aman tanpa memaksa jadi "SESUAI"
            statusTanah = (dataFirebase['status_tanah']?.toString() ?? "SESUAI")
                .toUpperCase()
                .trim();
            if (statusTanah != "SESUAI" && statusTanah != "PERLU PERBAIKAN") {
              statusTanah = "DATA SENSOR TIDAK VALID";
            }

            // Mode sistem dari Firebase
            modeSistem = dataFirebase['mode_sistem']?.toString() ?? "Otomatis";

            // 3. Status Koneksi Sensor (Aktif / Non-Aktif berdasarkan selisih waktu <= 2 menit)
            int? timestampMs;
            if (dataFirebase['timestamp'] != null) {
              if (dataFirebase['timestamp'] is int) {
                int rawTs = dataFirebase['timestamp'] as int;
                timestampMs = rawTs < 10000000000 ? rawTs * 1000 : rawTs;
              } else if (dataFirebase['timestamp'] is num) {
                num rawTs = dataFirebase['timestamp'] as num;
                timestampMs = rawTs < 10000000000
                    ? (rawTs * 1000).toInt()
                    : rawTs.toInt();
              } else if (dataFirebase['timestamp'] is String) {
                timestampMs = DateTime.tryParse(
                  dataFirebase['timestamp'],
                )?.millisecondsSinceEpoch;
              }
            }
            if (timestampMs == null && dataFirebase['last_updated'] != null) {
              if (dataFirebase['last_updated'] is int) {
                int rawTs = dataFirebase['last_updated'] as int;
                timestampMs = rawTs < 10000000000 ? rawTs * 1000 : rawTs;
              } else if (dataFirebase['last_updated'] is num) {
                num rawTs = dataFirebase['last_updated'] as num;
                timestampMs = rawTs < 10000000000
                    ? (rawTs * 1000).toInt()
                    : rawTs.toInt();
              } else if (dataFirebase['last_updated'] is String) {
                timestampMs = DateTime.tryParse(
                  dataFirebase['last_updated'],
                )?.millisecondsSinceEpoch;
              }
            }

            bool isSensorActive = false;
            if (timestampMs != null) {
              final nowMs = DateTime.now().millisecondsSinceEpoch;
              final diffMinutes = (nowMs - timestampMs).abs() / (1000 * 60);
              if (diffMinutes <= 2.0) {
                isSensorActive = true;
              }
            }

            if (isSensorActive) {
              bool isRaining = dataFirebase['is_raining'] == true;
              if (isRaining) {
                statusSensor = "Aktif (Hujan)";
                warnaSensor = Colors.blue;
              } else {
                statusSensor = "Aktif";
                warnaSensor = Colors.green;
              }
            } else {
              statusSensor = "Non-Aktif";
              warnaSensor = Colors.red;
            }
          }

          // Perbaikan 2: Kirim flag validitas ke fungsi cek parameter masing-masing
          var infoPH = cekPH(valPH, phValid);
          var infoKelembaban = cekKelembapan(valKelembaban, moistureValid);
          var infoSuhu = cekSuhu(valSuhu, soilTempValid);
          var infoN = cekN(valN, nValid);
          var infoP = cekP(valP, pValid);
          var infoK = cekK(valK, kValid);
          var infoSuhuUdara = cekSuhuUdara(valSuhuUdara, airTempValid);
          var infoKelembabanUdara = cekKelembabanUdara(
            valKelembabanUdara,
            airHumValid,
          );

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 150,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/sawi.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black45, bgColor],
                            stops: [0.1, 1.0],
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 30,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Halo, Petani!",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Pantau kondisi lahan pada tanaman sawi hijau saat ini.",
                            style: TextStyle(
                              color: Color.fromARGB(231, 255, 255, 255),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DeviceStatusCard(
                        title: "SENSOR TANAH",
                        value: statusSensor,
                        icon: Icons.sensors,
                        iconColor: warnaSensor,
                      ),
                      const SizedBox(height: 12),
                      DeviceStatusCard(
                        title: "MODE SISTEM",
                        value: modeSistem,
                        icon: Icons.settings,
                        iconColor: Colors.blueAccent,
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Monitoring Sensor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: MiniParameterCard(
                              title: "pH TANAH",
                              value: valPH.toStringAsFixed(1),
                              status: infoPH['status']!,
                              icon: Icons.science_outlined,
                              color: infoPH['color'],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: MiniParameterCard(
                              title: "LEMBAB TANAH",
                              value: "${valKelembaban.toStringAsFixed(1)}%",
                              status: infoKelembaban['status']!,
                              icon: Icons.water_drop_outlined,
                              color: infoKelembaban['color'],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: MiniParameterCard(
                              title: "SUHU TANAH",
                              value: "${valSuhu.toStringAsFixed(1)}°C",
                              status: infoSuhu['status']!,
                              icon: Icons.thermostat_outlined,
                              color: infoSuhu['color'],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: MiniParameterCard(
                              title: "SUHU UDARA",
                              value: "${valSuhuUdara.toStringAsFixed(1)}°C",
                              status: infoSuhuUdara['status']!,
                              icon: Icons.cloud_outlined,
                              color: infoSuhuUdara['color'],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: MiniParameterCard(
                              title: "LEMBAB UDARA",
                              value:
                                  "${valKelembabanUdara.toStringAsFixed(1)}%",
                              status: infoKelembabanUdara['status']!,
                              icon: Icons.air_outlined,
                              color: infoKelembabanUdara['color'],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        "Kadar Nutrisi (NPK)",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: NutrisiMiniCard(
                              label: "NITROGEN (N)",
                              value: valN.toStringAsFixed(1),
                              status: infoN['status']!,
                              color: infoN['color'],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: NutrisiMiniCard(
                              label: "FOSFOR (P)",
                              value: valP.toStringAsFixed(1),
                              status: infoP['status']!,
                              color: infoP['color'],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: NutrisiMiniCard(
                              label: "KALIUM (K)",
                              value: valK.toStringAsFixed(1),
                              status: infoK['status']!,
                              color: infoK['color'],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      StatusKondisiCard(status: statusTanah),
                      const SizedBox(height: 24),
                      const TrenKelembabanCard(),
                      const SizedBox(height: 24),
                      const RiwayatMonitoringList(),
                      const SizedBox(height: 24),
                      RekomendasiCard(data: dataFirebase),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 3. WIDGET STATUS KONDISI CARD
// ==========================================
class StatusKondisiCard extends StatelessWidget {
  final String status;

  const StatusKondisiCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final String s = status.toUpperCase().trim();
    final bool tidakValid = s == "DATA SENSOR TIDAK VALID";
    final bool isSesuai = !tidakValid && s != "PERLU PERBAIKAN";

    final Color statusColor = tidakValid
        ? Colors.grey
        : (isSesuai ? Colors.green : Colors.red);
    final IconData statusIcon = tidakValid
        ? Icons.sensors_off
        : (isSesuai
              ? Icons.check_circle_outline_rounded
              : Icons.warning_amber_rounded);
    final String judul = tidakValid
        ? "DATA TIDAK VALID"
        : (isSesuai ? "SESUAI" : "PERLU PERBAIKAN");
    final String deskripsi = tidakValid
        ? 'Data sensor tidak dapat dibaca. Periksa sambungan sensor RS485.'
        : (isSesuai
              ? 'Parameter utama berada dalam batas acuan. Periksa rekomendasi di bawah untuk parameter lainnya.'
              : 'Terdapat parameter tanah yang membutuhkan tindakan penanganan.');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Row(
            children: [
              Icon(Icons.grass, color: Color(0xFF2D5A27), size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Status Kondisi Lahan",
                  style: TextStyle(
                    color: Color(0xFF1E3A1A),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Icon(statusIcon, size: 80, color: statusColor),
          const SizedBox(height: 12),
          Text(
            judul,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: statusColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            deskripsi,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 4. WIDGET PENDUKUNG LAINNYA
// ==========================================

class MiniParameterCard extends StatelessWidget {
  final String title, value, status;
  final IconData icon;
  final Color color;

  const MiniParameterCard({
    super.key,
    required this.title,
    required this.value,
    required this.status,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class NutrisiMiniCard extends StatelessWidget {
  final String label, value, status;
  final Color color;
  const NutrisiMiniCard({
    super.key,
    required this.label,
    required this.value,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
              const Text(
                "mg/kg",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class DeviceStatusCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color iconColor;
  const DeviceStatusCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ],
      ),
    );
  }
}

class TrenKelembabanCard extends StatelessWidget {
  const TrenKelembabanCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tren Kelembaban",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const Text(
            "5 pencatatan terakhir",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 30),
          StreamBuilder(
            stream: FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL: kFirebaseDatabaseUrl,
            ).ref('riwayat_harian').limitToLast(5).onValue,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildBar("H-4", 0.1),
                    _buildBar("H-3", 0.1),
                    _buildBar("H-2", 0.1),
                    _buildBar("H-1", 0.1),
                    _buildBar("Hari Ini", 0.1),
                  ],
                );
              }

              final dataRiwayat = Map<String, dynamic>.from(
                snapshot.data!.snapshot.value as Map,
              );
              var tanggalList = dataRiwayat.keys.toList()..sort();

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: tanggalList.map((tgl) {
                  double nilai = (dataRiwayat[tgl]['kelembaban'] ?? 0)
                      .toDouble();
                  String label;
                  if (dataRiwayat[tgl]['waktu'] != null) {
                    label = dataRiwayat[tgl]['waktu'].toString();
                  } else if (tgl.contains('_')) {
                    label = tgl.split('_').last.replaceAll('-', ':');
                  } else {
                    label = tgl.split('-').last;
                  }
                  return _buildBar(label, nilai / 100);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String day, double heightFactor) {
    return Column(
      children: [
        Container(
          height: 120 * heightFactor.clamp(0.05, 1.0),
          width: 35,
          decoration: BoxDecoration(
            color: const Color(0xFF2D5A27),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          day,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class RiwayatMonitoringList extends StatelessWidget {
  const RiwayatMonitoringList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Riwayat Monitoring",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryScreen(),
                    ),
                  );
                },
                child: const Text(
                  "LIHAT SEMUA",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder(
            stream: FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL: kFirebaseDatabaseUrl,
            ).ref('riwayat_harian').limitToLast(3).onValue,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return const Center(child: Text("Belum ada riwayat harian."));
              }

              final data = Map<String, dynamic>.from(
                snapshot.data!.snapshot.value as Map,
              );
              var sortedKeys = data.keys.toList()
                ..sort((a, b) => b.compareTo(a));

              return Column(
                children: sortedKeys.map((key) {
                  final itemMap = data[key];
                  double? kVal = double.tryParse("${itemMap['kelembaban']}");
                  double? phVal = double.tryParse("${itemMap['ph']}");

                  String displayDate = key;
                  if (itemMap['tanggal'] != null && itemMap['waktu'] != null) {
                    displayDate = "${itemMap['tanggal']} • ${itemMap['waktu']}";
                  } else if (key.contains('_')) {
                    final parts = key.split('_');
                    displayDate =
                        "${parts[0]} • ${parts[1].replaceAll('-', ':')}";
                  }

                  return RiwayatItem(
                    tanggal: displayDate,
                    kelembaban: kVal != null
                        ? kVal.toStringAsFixed(1)
                        : "${itemMap['kelembaban']}",
                    ph: phVal != null
                        ? phVal.toStringAsFixed(1)
                        : (itemMap['ph']?.toString() ?? "-"),
                    statusTanah:
                        itemMap['status_tanah']?.toString() ?? "SESUAI",
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class RiwayatItem extends StatelessWidget {
  final String tanggal, kelembaban, ph;
  final String statusTanah;

  const RiwayatItem({
    super.key,
    required this.tanggal,
    required this.kelembaban,
    required this.ph,
    this.statusTanah = "SESUAI",
  });

  @override
  Widget build(BuildContext context) {
    final String s = statusTanah.toUpperCase().trim();
    final bool tidakValid = s == "DATA SENSOR TIDAK VALID";
    final bool isSesuai = !tidakValid && s != "PERLU PERBAIKAN";

    final String labelStatus = tidakValid
        ? "TIDAK VALID"
        : (isSesuai ? "SESUAI" : "PERLU PERBAIKAN");
    final Color statusColor = tidakValid
        ? Colors.grey
        : (isSesuai ? Colors.green : Colors.red);

    return Column(
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.1),
                child: Icon(
                  tidakValid
                      ? Icons.sensors_off
                      : (isSesuai
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_rounded),
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Pengecekan Rutin",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "Lembap: $kelembaban%  •  pH: $ph",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    tanggal,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      labelStatus,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 5. WIDGET REKOMENDASI CARD
// ==========================================
class RekomendasiCard extends StatelessWidget {
  final Map<String, dynamic>? data;

  const RekomendasiCard({super.key, this.data});

  List<Map<String, String>> _generateRekomendasi(Map<String, dynamic> data) {
    final rekomendasi = <Map<String, String>>[];

    double ph = (data['ph'] ?? 6.5).toDouble();
    double kelembaban = (data['kelembaban'] ?? 60.0).toDouble();
    double suhu = (data['suhu'] ?? 25.0).toDouble();
    double n = (data['n'] ?? 100.0).toDouble();
    double p = (data['p'] ?? 30.0).toDouble();
    double k = (data['k'] ?? 120.0).toDouble();

    bool phValid = data['ph_valid'] == true;
    bool moistureValid = data['moisture_valid'] == true;
    bool soilTempValid = data['soil_temp_valid'] == true;
    bool nValid = data['n_valid'] == true;
    bool pValid = data['p_valid'] == true;
    bool kValid = data['k_valid'] == true;

    // pH Tanah
    if (phValid) {
      if (ph < 6.0) {
        rekomendasi.add({
          "kondisi": "pH tanah terdeteksi asam (di bawah batas optimal).",
          "aksi":
              "👉 Lakukan evaluasi pH tanah. Pertimbangkan pengapuran pertanian untuk menetralkan asam.",
        });
      } else if (ph > 7.0) {
        rekomendasi.add({
          "kondisi": "pH tanah terdeteksi basa (di atas batas optimal).",
          "aksi":
              "👉 Lakukan evaluasi pH tanah. Pertimbangkan penambahan unsur penurun pH atau pembilasan tanah.",
        });
      }
    }

    // Kelembaban Tanah
    if (moistureValid) {
      if (kelembaban < 50.0) {
        rekomendasi.add({
          "kondisi": "Kelembaban tanah terdeteksi kering.",
          "aksi":
              "🚰 Segera lakukan penyiraman untuk menjaga kebutuhan air tanaman.",
        });
      } else if (kelembaban > 70.0) {
        rekomendasi.add({
          "kondisi": "Tanah terdeteksi terlalu basah/jenuh air.",
          "aksi":
              "🛑 Hentikan penyiraman. Periksa saluran drainase agar tidak terjadi genangan yang memicu busuk akar.",
        });
      }
    }

    // Suhu Tanah
    if (soilTempValid) {
      if (suhu < 15.0) {
        rekomendasi.add({
          "kondisi": "Suhu tanah terdeteksi terlalu dingin.",
          "aksi":
              "🌱 Pantau kondisi lingkungan sekitar. Pertimbangkan penggunaan penutup tanah jika suhu terus menurun.",
        });
      } else if (suhu > 30.0) {
        rekomendasi.add({
          "kondisi": "Suhu tanah terdeteksi terlalu panas.",
          "aksi":
              "☂️ Jaga kelembaban tanah dengan penyiraman ringan untuk membantu menstabilkan suhu.",
        });
      }
    }

    // Nitrogen (N)
    if (nValid) {
      if (n < 50.0) {
        rekomendasi.add({
          "kondisi": "Kadar unsur Nitrogen (N) terdeteksi rendah.",
          "aksi":
              "🧪 Berikan pupuk susulan yang mengandung unsur Nitrogen untuk memacu pertumbuhan daun.",
        });
      } else if (n > 150.0) {
        rekomendasi.add({
          "kondisi": "Kadar unsur Nitrogen (N) terdeteksi tinggi.",
          "aksi":
              "🛑 Kurangi atau tunda pemberian pupuk kaya Nitrogen untuk mencegah tanaman rebah.",
        });
      }
    }

    // Fosfor (P)
    if (pValid) {
      if (p < 15.0) {
        rekomendasi.add({
          "kondisi": "Kadar unsur Fosfor (P) terdeteksi rendah.",
          "aksi":
              "🧪 Berikan pupuk susulan yang mengandung unsur Fosfor untuk mendukung sistem perakaran.",
        });
      } else if (p > 60.0) {
        rekomendasi.add({
          "kondisi": "Kadar unsur Fosfor (P) terdeteksi berlebih.",
          "aksi":
              "🛑 Tunda aplikasi pupuk Fosfor tambahan. Lakukan penyiraman rutin.",
        });
      }
    }

    // Kalium (K)
    if (kValid) {
      if (k < 80.0) {
        rekomendasi.add({
          "kondisi": "Kadar unsur Kalium (K) terdeteksi rendah.",
          "aksi":
              "🧪 Berikan pupuk susulan yang mengandung unsur Kalium untuk menjaga daya tahan tanaman.",
        });
      } else if (k > 200.0) {
        rekomendasi.add({
          "kondisi": "Kadar unsur Kalium (K) terdeteksi tinggi.",
          "aksi": "🛑 Hentikan sementara pemberian pupuk Kalium tambahan.",
        });
      }
    }

    return rekomendasi;
  }

  Widget _buildContent(Map<String, dynamic> currentData) {
    final String statusTanah =
        (currentData['status_tanah']?.toString() ?? "SESUAI")
            .toUpperCase()
            .trim();
    final bool tidakValid = statusTanah == "DATA SENSOR TIDAK VALID";
    final bool isSesuai = !tidakValid && statusTanah != "PERLU PERBAIKAN";

    final List<Map<String, String>> listRek = tidakValid
        ? []
        : _generateRekomendasi(currentData);

    String pesanKosong;
    IconData ikonKosong;
    Color warnaIkon;
    if (tidakValid) {
      pesanKosong = "Data sensor tidak valid. Periksa sambungan sensor RS485.";
      ikonKosong = Icons.sensors_off;
      warnaIkon = Colors.grey;
    } else if (isSesuai) {
      pesanKosong =
          "Semua parameter dalam rentang acuan. Tidak ada tindakan perbaikan yang diperlukan.";
      ikonKosong = Icons.check_circle;
      warnaIkon = const Color(0xFF69F0AE);
    } else {
      pesanKosong =
          "Status perlu perbaikan. Periksa parameter sensor dan kalibrasi alat.";
      ikonKosong = Icons.warning_amber_rounded;
      warnaIkon = Colors.orangeAccent;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 67, 94, 63),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                "REKOMENDASI SISTEM",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Tindakan yang Disarankan",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          if (listRek.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(ikonKosong, color: warnaIkon, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      pesanKosong,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: listRek.map((rek) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rek['kondisi'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          rek['aksi'] ?? '',
                          style: const TextStyle(
                            color: Color(0xFFE0E0E0),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (data != null && data!.isNotEmpty) {
      return _buildContent(data!);
    }

    return StreamBuilder(
      stream: FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: kFirebaseDatabaseUrl,
      ).ref('monitoring_sawi').onValue,
      builder: (context, snapshot) {
        Map<String, dynamic> currentData = {};
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          currentData = Map<String, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );
        }
        return _buildContent(currentData);
      },
    );
  }
}
