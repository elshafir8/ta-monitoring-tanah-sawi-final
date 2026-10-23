"""
PROGRAM 2 (REVISI): SPLIT DATA & OVERSAMPLING (SMOTE / ADASYN)
==============================================================
Perubahan dari versi sebelumnya:
  1. DATA SINTETIS DILABEL ULANG DENGAN ATURAN YANG SAMA.
     Alasan: daerah "Perlu Perbaikan" bentuknya tidak cembung (semua di luar kotak rentang),
     sehingga titik hasil interpolasi dua sampel "Perlu Perbaikan" bisa jatuh DI DALAM
     kotak "Sesuai". Label sintetis seperti itu salah dan membuat pohon membuat cabang aneh
     ("Perlu Perbaikan" melahirkan "Sesuai"). Karena label = fungsi dari aturan, label
     sintetis cukup dihitung ulang dengan aturan yang sama.
  2. TIDAK ADA DUPLIKASI BARIS. Versi lama menambal kekurangan ADASYN dengan
     sample(replace=True) sehingga ada baris kembar (Penguji 2 menanyakan duplikasi).
     Sekarang jumlah apa adanya dilaporkan.
  3. Oversampling tetap HANYA pada data latih; data uji murni tidak disentuh.
  4. Laporan hasil (jumlah label yang dikoreksi) disimpan ke laporan_oversampling.csv.
"""
import os
import warnings

import pandas as pd
from imblearn.over_sampling import ADASYN, SMOTE
from sklearn.model_selection import train_test_split

from aturan_label import FITUR, beri_label

warnings.filterwarnings("ignore")

FILE_IN = "Dataset_Berlabel.csv"
OUTPUT_DIR = "Dataset_Skenario_B_CSV"
RANDOM_STATE = 42
os.makedirs(OUTPUT_DIR, exist_ok=True)


def tambah_sintetik(df_train: pd.DataFrame, metode: str, tambahan_per_kelas: int):
    """Oversampling pada data latih, lalu label dihitung ulang dengan aturan."""
    X, y = df_train[FITUR], df_train["Label"]
    target = {
        0.0: int((y == 0.0).sum()) + tambahan_per_kelas,
        1.0: int((y == 1.0).sum()) + tambahan_per_kelas,
    }
    sampler = (SMOTE if metode == "smote" else ADASYN)(
        sampling_strategy=target, random_state=RANDOM_STATE
    )
    X_res, y_res = sampler.fit_resample(X, y)
    df_res = pd.DataFrame(X_res, columns=FITUR)
    df_res["Label"] = pd.Series(y_res).astype("float64").values

    # --- koreksi label sintetis memakai aturan ---
    label_aturan = beri_label(df_res).values
    n_koreksi = int((df_res["Label"].values != label_aturan).sum())
    df_res["Label"] = label_aturan.astype("float64")

    df_res = df_res.sample(frac=1, random_state=RANDOM_STATE).reset_index(drop=True)
    return df_res, n_koreksi


def main():
    print("=" * 70)
    print(" PROGRAM 2: SPLIT & OVERSAMPLING (LABEL SINTETIS DIKOREKSI DENGAN ATURAN)")
    print("=" * 70)

    df = pd.read_csv(FILE_IN, dtype={"Label": "float64"})
    print(f"Dataset: {len(df)} baris | label: {df['Label'].value_counts().to_dict()}\n")

    laporan = []
    for rasio_uji, nama in ((0.30, "7030"), (0.20, "8020")):
        tr, te = train_test_split(
            df, test_size=rasio_uji, random_state=RANDOM_STATE, stratify=df["Label"]
        )
        tr = tr.reset_index(drop=True)
        te = te.reset_index(drop=True)
        tr.to_csv(f"{OUTPUT_DIR}/Train_Asli_{nama}.csv", index=False)
        te.to_csv(f"{OUTPUT_DIR}/Test_Murni_{nama}.csv", index=False)
        print(f"[Split {nama}] latih={len(tr)} uji={len(te)}")

        # cek tidak ada baris data uji yang sama dengan data latih (bebas kebocoran)
        irisan = pd.merge(tr[FITUR], te[FITUR], how="inner").shape[0]
        print(f"   baris uji yang identik dengan baris latih: {irisan}")

        for target_total, tambahan in ((750, 125), (1000, 250)):
            for metode in ("smote", "adasyn"):
                hasil, n_koreksi = tambah_sintetik(tr, metode, tambahan)
                nama_file = f"Train_{metode.upper()}_{target_total}_{nama}.csv"
                hasil.to_csv(f"{OUTPUT_DIR}/{nama_file}", index=False)
                dup = int(hasil.duplicated(subset=FITUR).sum())
                dist = hasil["Label"].value_counts().to_dict()
                print(f"   {nama_file:<28} baris={len(hasil):<5} label={dist} "
                      f"| label sintetis dikoreksi={n_koreksi} | baris kembar={dup}")
                laporan.append({
                    "split": nama, "metode": metode.upper(), "target": target_total,
                    "baris_hasil": len(hasil), "label_dikoreksi": n_koreksi,
                    "baris_kembar": dup,
                })
        print()

    pd.DataFrame(laporan).to_csv(f"{OUTPUT_DIR}/laporan_oversampling.csv", index=False)
    print(f"Selesai. File ada di folder '{OUTPUT_DIR}/'.")


if __name__ == "__main__":
    main()