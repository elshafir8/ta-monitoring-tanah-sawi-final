import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.tree import DecisionTreeClassifier, export_text, plot_tree
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.svm import SVC
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, confusion_matrix
import warnings
warnings.filterwarnings('ignore')

FITUR = ['pH', 'Kelembaban (%)', 'Suhu (°C)', 'N (mg/kg)', 'P (mg/kg)', 'K (mg/kg)']

def evaluasi_model(y_true, y_pred):
    # Positif = 0.0 (Perlu Perbaikan)
    return {
        "Akurasi": accuracy_score(y_true, y_pred) * 100,
        "Presisi": precision_score(y_true, y_pred, pos_label=0.0, zero_division=0) * 100,
        "Recall": recall_score(y_true, y_pred, pos_label=0.0, zero_division=0) * 100,
        "F1-Score": f1_score(y_true, y_pred, pos_label=0.0, zero_division=0) * 100
    }

def latih_dan_uji(X_train, y_train, X_test, y_test):
    models = {
        "Decision Tree": DecisionTreeClassifier(max_depth=5, min_samples_split=10, min_samples_leaf=5, random_state=42),
        "SVM": make_pipeline(StandardScaler(), SVC(kernel="rbf", random_state=42)),
        "Random Forest": RandomForestClassifier(n_estimators=100, random_state=42),
        "Logistic Regression": make_pipeline(StandardScaler(), LogisticRegression(max_iter=1000))
    }

    hasil = []
    for nama, model in models.items():
        model.fit(X_train, y_train)
        y_pred = model.predict(X_test)
        metrik = evaluasi_model(y_test, y_pred)
        metrik["Model"] = nama
        hasil.append(metrik)
    return pd.DataFrame(hasil)

print("="*80)
print(" EVALUASI MODEL: DATA ASLI 500 VS SMOTE 1000")
print("="*80)

# =====================================================================
# 1. EVALUASI DATA ASLI (500)
# =====================================================================
print("\n--- 1. SKENARIO DATA ASLI (500) ---")
# 80:20
tr_asli_8020 = pd.read_csv('Train_Asli_8020.csv')
te_murni_8020 = pd.read_csv('Test_Murni_8020.csv')
df_8020 = latih_dan_uji(tr_asli_8020[FITUR], tr_asli_8020['Label'], te_murni_8020[FITUR], te_murni_8020['Label'])
df_8020.insert(0, "Rasio", "80:20")
df_8020.insert(0, "Skenario", "Data Asli 500")

# 70:30
tr_asli_7030 = pd.read_csv('Train_Asli_7030.csv')
te_murni_7030 = pd.read_csv('Test_Murni_7030.csv')
df_7030 = latih_dan_uji(tr_asli_7030[FITUR], tr_asli_7030['Label'], te_murni_7030[FITUR], te_murni_7030['Label'])
df_7030.insert(0, "Rasio", "70:30")
df_7030.insert(0, "Skenario", "Data Asli 500")

# =====================================================================
# 2. EVALUASI DATA SMOTE (1000)
# =====================================================================
print("\n--- 2. SKENARIO DATA SMOTE (1000) ---")
# 80:20
tr_smote_8020 = pd.read_csv('Train_SMOTE_1000_8020.csv')
df_smote_8020 = latih_dan_uji(tr_smote_8020[FITUR], tr_smote_8020['Label'], te_murni_8020[FITUR], te_murni_8020['Label'])
df_smote_8020.insert(0, "Rasio", "80:20")
df_smote_8020.insert(0, "Skenario", "SMOTE 1000")

# 70:30
tr_smote_7030 = pd.read_csv('Train_SMOTE_1000_7030.csv')
df_smote_7030 = latih_dan_uji(tr_smote_7030[FITUR], tr_smote_7030['Label'], te_murni_7030[FITUR], te_murni_7030['Label'])
df_smote_7030.insert(0, "Rasio", "70:30")
df_smote_7030.insert(0, "Skenario", "SMOTE 1000")

# Gabungkan semua hasil
hasil_semua = pd.concat([df_8020, df_7030, df_smote_8020, df_smote_7030], ignore_index=True)
print("\nTABEL HASIL EVALUASI MODEL (Gunakan ini untuk Tabel 4.6):")
print(hasil_semua.to_string(index=False))

# =====================================================================
# 3. TRAINING MODEL FINAL (POHON A) UNTUK ESP32 & GAMBAR LAPORAN
# =====================================================================
print("\n" + "="*80)
print(" 3. MODEL FINAL YANG MASUK ESP32 (POHON A - AWAL N)")
print("="*80)

# Pakai Data Asli 70:30
X_train_final = tr_asli_7030[FITUR]
y_train_final = tr_asli_7030['Label']
X_test_final = te_murni_7030[FITUR]
y_test_final = te_murni_7030['Label']

model_final = DecisionTreeClassifier(max_depth=5, min_samples_split=10, min_samples_leaf=5, random_state=42)
model_final.fit(X_train_final, y_train_final)

print("\nAturan If-Else Pohon A (Copy ke Laporan):")
print(export_text(model_final, feature_names=FITUR))

# Visualisasi Pohon Final (Untuk Gambar 4.6)
plt.figure(figsize=(15, 8))
plot_tree(model_final, feature_names=FITUR, class_names=['Perlu Perbaikan', 'Sesuai'],
          filled=True, rounded=True, fontsize=10)
plt.title("Gambar 4.6 Visualisasi Struktur Pohon Keputusan Model Final (Awal N)", fontweight='bold')
plt.tight_layout()
plt.savefig('Gambar_4.6_Pohon_A.png', dpi=300)
plt.show()

# Confusion Matrix Pohon A (Untuk Gambar 4.4)
y_pred_final = model_final.predict(X_test_final)
cm_final = confusion_matrix(y_test_final, y_pred_final, labels=[0.0, 1.0])
plt.figure(figsize=(6, 5))
sns.heatmap(cm_final, annot=True, fmt="d", cmap="Blues", cbar=False,
            xticklabels=["Perlu Perbaikan (0)", "Sesuai (1)"],
            yticklabels=["Perlu Perbaikan (0)", "Sesuai (1)"])
plt.title("Gambar 4.4 Confusion Matrix Model Final (Pohon A)", fontweight='bold')
plt.xlabel("Prediksi")
plt.ylabel("Aktual")
plt.savefig('Gambar_4.4_Confusion_Matrix.png', dpi=300)
plt.show()

# Cetak Metrik Pohon A
metrik_final = evaluasi_model(y_test_final, y_pred_final)
print("\nMetrik Model Final (Pohon A - Data Asli 500, 70:30):")
for k, v in metrik_final.items():
    print(f"{k}: {v:.2f}%")

# =====================================================================
# 4. EKSPOR KE BAHASA C++ (UNTUK ESP32) - VERSI 100% FLOAT
# =====================================================================
NAMA_C = {'pH': 'ph', 'Kelembaban (%)': 'kelembaban', 'Suhu (°C)': 'suhu',
          'N (mg/kg)': 'nitrogen', 'P (mg/kg)': 'fosfor', 'K (mg/kg)': 'kalium'}
tr = model_final.tree_
kelas = model_final.classes_

def rek_cpp(node, d):
    pad = "  " * d
    if tr.feature[node] == -2:
        # Mengembalikan nilai float (1.0f atau 0.0f)
        return f"{pad}return {float(kelas[np.argmax(tr.value[node][0])]):.1f}f;\n"
    v = NAMA_C[FITUR[tr.feature[node]]]
    thr = round(float(tr.threshold[node]), 6)
    return (f"{pad}if ({v} <= {thr:.6f}f) {{\n"
            + rek_cpp(tr.children_left[node], d + 1)
            + f"{pad}}} else {{\n" + rek_cpp(tr.children_right[node], d + 1) + f"{pad}}}\n")

kode_h = (
    "// DIHASILKAN OTOMATIS - Pohon A (Awal N) Sesuai Arahan Penguji\n"
    "// Mengembalikan 0.0f = Perlu Perbaikan, 1.0f = Sesuai.\n"
    "#pragma once\n\n"
    "// Fungsi mengembalikan tipe data float\n"
    "inline float klasifikasiTanah(float ph, float kelembaban, float suhu,\n"
    "                              float nitrogen, float fosfor, float kalium) {\n"
    + rek_cpp(0, 1) + "}\n"
)
with open("klasifikasi_tanah_model.h", "w") as f:
    f.write(kode_h)
print("\nFile 'klasifikasi_tanah_model.h' berhasil dibuat! (Copy isinya ke Arduino IDE).")