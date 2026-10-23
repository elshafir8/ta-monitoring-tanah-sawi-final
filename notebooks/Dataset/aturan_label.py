"""
ATURAN_LABEL: satu-satunya tempat aturan label & ambang batas didefinisikan.
Dipakai oleh Program 1, 2, dan 3 supaya konsisten (label, SMOTE, dan evaluasi
selalu memakai aturan yang sama). Ganti ambang HANYA di file ini.
"""
import numpy as np
import pandas as pd

FITUR = ["pH", "Kelembaban (%)", "Suhu (°C)", "N (mg/kg)", "P (mg/kg)", "K (mg/kg)"]

# ------------------------------------------------------------------
# AMBANG (ganti di sini saja bila pembimbing/literatur menyarankan lain)
# None = tidak dipakai
# ------------------------------------------------------------------
AMBANG = {
    #  parameter         (minimum, maksimum)
    "pH":             (6.0, 7.0),
    "Kelembaban (%)": (50.0, 70.0),
    "Suhu (°C)":      (15.0, 30.0),
    "N (mg/kg)":      (50.0, 150.0),
    "P (mg/kg)":      (15.0, 60.0),
    "K (mg/kg)":      (80.0, 200.0),
}
# Parameter yang menjadi GERBANG MINIMUM MUTLAK (sesuai arahan Penguji 1)
GERBANG = ["N (mg/kg)", "P (mg/kg)", "K (mg/kg)", "Kelembaban (%)"]
# Parameter DUA SISI yang juga dijadikan gerbang (di luar rentang -> otomatis Perlu Perbaikan).
# Default kosong = persis seperti arahan Penguji 1 (hanya batas minimum). Isi ["pH"] jika
# pembimbing menyetujui pH ikut jadi gerbang.
GERBANG_DUA_SISI = []
PAKAI_BATAS_ATAS = True   # False = hanya batas minimum yang dipakai (tanyakan pembimbing)


def gerbang_minimum(df: pd.DataFrame) -> pd.Series:
    """True jika salah satu parameter gerbang di bawah minimum -> wajib Perlu Perbaikan."""
    kondisi = [df[p] < AMBANG[p][0] for p in GERBANG]
    for p in GERBANG_DUA_SISI:
        lo, hi = AMBANG[p]
        kondisi.append((df[p] < lo) | (df[p] > hi))
    return np.logical_or.reduce(kondisi)


def dalam_rentang(df: pd.DataFrame) -> pd.Series:
    """True jika SEMUA parameter berada dalam rentang acuan."""
    kondisi = []
    for p, (lo, hi) in AMBANG.items():
        c = df[p] >= lo
        if PAKAI_BATAS_ATAS and hi is not None:
            c = c & (df[p] <= hi)
        kondisi.append(c)
    return np.logical_and.reduce(kondisi)


def beri_label(df: pd.DataFrame) -> pd.Series:
    """Label akhir: gerbang minimum menang mutlak, lalu cek rentang."""
    sesuai = (~gerbang_minimum(df)) & dalam_rentang(df)
    return pd.Series(sesuai.astype("float64"), index=df.index, name="Label")