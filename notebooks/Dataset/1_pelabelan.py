"""
PROGRAM 1 (REVISI): PELABELAN DATASET
=====================================
Perubahan dari versi sebelumnya (mengacu pada saran Penguji 1 & 2):
  1. Aturan label dipisah jadi DUA bagian yang eksplisit:
       a. GERBANG MINIMUM MUTLAK  -> N < 50, P < 15, K < 80, Kelembaban < 50
          Jika salah satu terpenuhi: WAJIB "Perlu Perbaikan", suhu/pH tidak boleh menyelamatkan.
       b. RENTANG ACUAN (Tabel 4.2) -> pH, suhu, dan batas atas.
          "Sesuai" hanya jika SEMUA parameter berada dalam rentang.
  2. Semua ambang ada di satu tempat (file aturan_label.py, dict AMBANG) supaya mudah diganti
     setelah dikonfirmasi pembimbing dan sumber literatur.
  3. Ada laporan pemeriksaan: berapa data yang kena gerbang, parameter mana yang paling
     sering menyebabkan "Perlu Perbaikan", dan cek konsistensi label.

Label: 0.0 = Perlu Perbaikan, 1.0 = Sesuai (float64)
"""
import pandas as pd
from aturan_label import FITUR, AMBANG, GERBANG, PAKAI_BATAS_ATAS, gerbang_minimum, beri_label

NAMA_FILE = "dataset_mentah.xlsx"
FILE_OUT = "Dataset_Berlabel.csv"

def main():
    print("=" * 70)
    print(" PROGRAM 1: PELABELAN (GERBANG MINIMUM MUTLAK + RENTANG ACUAN)")
    print("=" * 70)

    df = pd.read_excel(NAMA_FILE)
    # standarisasi nama kolom (sama dengan versi lama)
    rename = {}
    for c in df.columns:
        cl = str(c).lower()
        if "ph" in cl: rename[c] = "pH"
        elif "lembab" in cl: rename[c] = "Kelembaban (%)"
        elif "suhu" in cl: rename[c] = "Suhu (°C)"
        elif cl.startswith("n"): rename[c] = "N (mg/kg)"
        elif cl.startswith("p"): rename[c] = "P (mg/kg)"
        elif cl.startswith("k"): rename[c] = "K (mg/kg)"
    df = df.rename(columns=rename)
    for c in FITUR:
        df[c] = pd.to_numeric(df[c], errors="coerce").astype("float64")
    df = df.dropna(subset=FITUR).reset_index(drop=True)

    df["Label"] = beri_label(df)
    df = df[FITUR + ["Label"]]

    # ---------------- laporan pemeriksaan ----------------
    n = len(df)
    n0 = int((df["Label"] == 0).sum())
    n1 = int((df["Label"] == 1).sum())
    print(f"\nTotal data          : {n}")
    print(f"Perlu Perbaikan (0) : {n0} ({n0/n*100:.1f}%)")
    print(f"Sesuai (1)          : {n1} ({n1/n*100:.1f}%)")

    g = gerbang_minimum(df)
    print(f"\nData yang kena GERBANG minimum : {int(g.sum())} ({g.mean()*100:.1f}%)")
    for p in GERBANG:
        print(f"   - {p:<16} < {AMBANG[p][0]:<5}: {int((df[p] < AMBANG[p][0]).sum())} data")

    print("\nParameter di luar rentang (semua data):")
    for p, (lo, hi) in AMBANG.items():
        bawah = int((df[p] < lo).sum())
        atas = int((df[p] > hi).sum()) if (PAKAI_BATAS_ATAS and hi is not None) else 0
        print(f"   - {p:<16}: di bawah min={bawah:<4} di atas max={atas}")

    # cek konsistensi: tidak boleh ada data kena gerbang tetapi berlabel Sesuai
    salah = int(((df["Label"] == 1) & g).sum())
    print(f"\nCek konsistensi (gerbang tapi berlabel Sesuai): {salah}  -> harus 0")
    assert salah == 0

    df["Label"] = df["Label"].astype("float64")
    df.to_csv(FILE_OUT, index=False)
    print(f"\n-> Selesai. File '{FILE_OUT}' siap dipakai Program 2.")


if __name__ == "__main__":
    main()