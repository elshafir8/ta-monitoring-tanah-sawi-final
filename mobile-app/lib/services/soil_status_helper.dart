class SoilStatusHelper {
  // Rentang acuan optimal tanah untuk budidaya sawi hijau
  static const double minPH = 6.0;
  static const double maxPH = 7.0;

  static const double minKelembaban = 50.0;
  static const double maxKelembaban = 70.0;

  static const double minSuhu = 15.0;
  static const double maxSuhu = 30.0;

  static const double minN = 50.0;
  static const double maxN = 150.0;

  static const double minP = 15.0;
  static const double maxP = 60.0;

  static const double minK = 80.0;
  static const double maxK = 200.0;

  static double? _parseToDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString());
  }

  /// Cek batas optimal pH (6.0 - 7.0)
  static bool isPHOptimal(dynamic ph) {
    final val = _parseToDouble(ph);
    if (val == null) return true;
    return val >= minPH && val <= maxPH;
  }

  /// Cek batas optimal Kelembaban (50% - 70%)
  static bool isKelembabanOptimal(dynamic kelembaban) {
    final val = _parseToDouble(kelembaban);
    if (val == null) return true;
    return val >= minKelembaban && val <= maxKelembaban;
  }

  /// Cek batas optimal Suhu Tanah (15°C - 30°C)
  static bool isSuhuOptimal(dynamic suhu) {
    final val = _parseToDouble(suhu);
    if (val == null) return true;
    return val >= minSuhu && val <= maxSuhu;
  }

  /// Cek batas optimal Nitrogen (50 - 150 mg/kg)
  static bool isNOptimal(dynamic n) {
    final val = _parseToDouble(n);
    if (val == null) return true;
    return val >= minN && val <= maxN;
  }

  /// Cek batas optimal Fosfor (15 - 60 mg/kg)
  static bool isPOptimal(dynamic p) {
    final val = _parseToDouble(p);
    if (val == null) return true;
    return val >= minP && val <= maxP;
  }

  /// Cek batas optimal Kalium (80 - 200 mg/kg)
  static bool isKOptimal(dynamic k) {
    final val = _parseToDouble(k);
    if (val == null) return true;
    return val >= minK && val <= maxK;
  }

  /// Mengecek apakah semua parameter berada dalam rentang acuan optimal
  static bool areParametersOptimal(Map<String, dynamic> data) {
    if (!isPHOptimal(data['ph'])) return false;
    if (!isKelembabanOptimal(data['kelembaban'])) return false;
    if (!isSuhuOptimal(data['suhu'])) return false;
    if (!isNOptimal(data['n'])) return false;
    if (!isPOptimal(data['p'])) return false;
    if (!isKOptimal(data['k'])) return false;
    return true;
  }

  /// Menghitung status tanah secara komprehensif:
  /// - Jika Decision Tree ESP32 mendeteksi "PERLU PERBAIKAN" -> return "PERLU PERBAIKAN"
  /// - Jika ada salah satu parameter (pH, kelembaban, suhu, N, P, K) di luar rentang acuan -> return "PERLU PERBAIKAN"
  /// - Jika seluruh parameter optimal dan tidak ada anomali -> return "SESUAI"
  static String evaluateStatus(Map<String, dynamic> data) {
    final rawStatus = (data['status_tanah'] ?? data['status'] ?? '')
        .toString()
        .toUpperCase()
        .trim();

    if (rawStatus == 'PERLU PERBAIKAN') {
      return 'PERLU PERBAIKAN';
    }

    if (!areParametersOptimal(data)) {
      return 'PERLU PERBAIKAN';
    }

    return 'SESUAI';
  }

  /// Helper boolean untuk status SESUAI
  static bool isSesuai(Map<String, dynamic> data) {
    return evaluateStatus(data) == 'SESUAI';
  }

  /// Mengambil daftar parameter yang berada di luar rentang acuan
  static List<String> getAnomalyParameters(Map<String, dynamic> data) {
    final issues = <String>[];
    if (!isPHOptimal(data['ph'])) {
      final v = _parseToDouble(data['ph']);
      issues.add("pH ($v)");
    }
    if (!isKelembabanOptimal(data['kelembaban'])) {
      final v = _parseToDouble(data['kelembaban']);
      issues.add("Kelembaban ($v%)");
    }
    if (!isSuhuOptimal(data['suhu'])) {
      final v = _parseToDouble(data['suhu']);
      issues.add("Suhu ($v°C)");
    }
    if (!isNOptimal(data['n'])) {
      final v = _parseToDouble(data['n']);
      issues.add("N ($v)");
    }
    if (!isPOptimal(data['p'])) {
      final v = _parseToDouble(data['p']);
      issues.add("P ($v)");
    }
    if (!isKOptimal(data['k'])) {
      final v = _parseToDouble(data['k']);
      issues.add("K ($v)");
    }
    return issues;
  }
}
