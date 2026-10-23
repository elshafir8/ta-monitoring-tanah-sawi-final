import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../main.dart' show kFirebaseDatabaseUrl;

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color greenTheme = Color(0xFF2D5A27);

    return Scaffold(
      backgroundColor: const Color.fromARGB(190, 91, 126, 60),
      appBar: AppBar(
        title: const Text(
          "Riwayat & Tren",
          style: TextStyle(color: greenTheme, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: greenTheme),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tren Kelembaban",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              "Statistik kelembaban tanah beberapa data terakhir",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            const LargeTrenCard(),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Log Monitoring Harian",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: const [
                        Icon(
                          Icons.autorenew,
                          size: 13,
                          color: Color(0xFF69F0AE),
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Otomatis terekam tiap 10 menit saat alat aktif",
                          style: TextStyle(
                            color: Color(0xFF69F0AE),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showSaveDialog(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    "Simpan Manual",
                    style: TextStyle(fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: greenTheme,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const DetailedHistoryList(),
          ],
        ),
      ),
    );
  }

  void _showSaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Simpan Snapshot Manual?"),
        content: const Text(
          "Data riwayat sudah terekam otomatis setiap 10 menit saat sensor aktif. Anda juga dapat menyimpan snapshot kondisi saat ini secara manual.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveCurrentSnapshot();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Data berhasil disimpan ke riwayat!"),
                  ),
                );
              }
            },
            child: const Text("Simpan Sekarang"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCurrentSnapshot() async {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kFirebaseDatabaseUrl,
    );
    // Ambil data terbaru dari monitoring_sawi
    final snapshot = await db.ref('monitoring_sawi').get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final now = DateTime.now();
      final dateStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final timeStr =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      final recordKey =
          "${dateStr}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}";

      // Simpan ke riwayat_harian dengan key tanggal & jam
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
        'tipe': 'Manual',
        'timestamp': ServerValue.timestamp,
      });
    }
  }
}

class LargeTrenCard extends StatelessWidget {
  const LargeTrenCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: StreamBuilder(
              stream: FirebaseDatabase.instanceFor(
                app: Firebase.app(),
                databaseURL: kFirebaseDatabaseUrl,
              ).ref('riwayat_harian').limitToLast(7).onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("Belum ada data tren."));
                }

                final data = Map<String, dynamic>.from(
                  snapshot.data!.snapshot.value as Map,
                );
                var sortedKeys = data.keys.toList()..sort();

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: sortedKeys.map((key) {
                    double val = (data[key]['kelembaban'] ?? 0).toDouble();

                    // Format label waktu/tanggal pada grafik
                    String label;
                    if (data[key]['waktu'] != null) {
                      label = data[key]['waktu'].toString();
                    } else if (key.contains('_')) {
                      label = key.split('_').last.replaceAll('-', ':');
                    } else {
                      label = key.split('-').last;
                    }

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "${val.toStringAsFixed(1)}%",
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 30,
                          height: 140 * (val / 100).clamp(0.1, 1.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D5A27),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DetailedHistoryList extends StatelessWidget {
  const DetailedHistoryList({super.key});

  String _formatDecimal(dynamic val) {
    if (val == null) return "-";
    if (val is num) return val.toDouble().toStringAsFixed(1);
    final parsed = double.tryParse(val.toString());
    if (parsed != null) return parsed.toStringAsFixed(1);
    return val.toString();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: kFirebaseDatabaseUrl,
      ).ref('riwayat_harian').onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(
            child: Text(
              "Belum ada riwayat.",
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final data = Map<String, dynamic>.from(
          snapshot.data!.snapshot.value as Map,
        );
        var sortedKeys = data.keys.toList()..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedKeys.length,
          itemBuilder: (context, index) {
            final key = sortedKeys[index];
            final item = data[key];

            // Status mutlak Decision Tree: SESUAI (Hijau) atau PERLU PERBAIKAN (Merah)
            final String rawStatus =
                (item['status_tanah'] ?? item['status'] ?? 'SESUAI')
                    .toString()
                    .toUpperCase()
                    .trim();
            final bool isSesuai = rawStatus != 'PERLU PERBAIKAN';
            final String labelStatus = isSesuai ? 'SESUAI' : 'PERLU PERBAIKAN';
            final Color statusColor = isSesuai ? Colors.green : Colors.red;

            final String lembabStr = _formatDecimal(item['kelembaban']);
            final String phStr = _formatDecimal(item['ph']);

            // Tampilkan Tanggal dan Jam secara lengkap
            String displayTitle = key;
            if (item['tanggal'] != null && item['waktu'] != null) {
              displayTitle = "${item['tanggal']} • ${item['waktu']}";
            } else if (key.contains('_')) {
              final parts = key.split('_');
              final tgl = parts[0];
              final wkt = parts[1].replaceAll('-', ':');
              displayTitle = "$tgl • $wkt";
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.12),
                  child: Icon(
                    isSesuai
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_rounded,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  displayTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text("Lembap: $lembabStr% | pH: $phStr"),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    labelStatus,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDetail("N", "${_formatDecimal(item['n'])} mg/kg"),
                        _buildDetail("P", "${_formatDecimal(item['p'])} mg/kg"),
                        _buildDetail("K", "${_formatDecimal(item['k'])} mg/kg"),
                        _buildDetail(
                          "Suhu",
                          "${_formatDecimal(item['suhu'])}°C",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetail(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}
