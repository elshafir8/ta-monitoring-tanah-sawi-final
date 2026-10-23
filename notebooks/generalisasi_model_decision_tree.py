import pandas as pd
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from sklearn.tree import DecisionTreeClassifier, plot_tree, export_text

# =====================================================================
# 1. PERSIAPAN DATASET
# =====================================================================
# Ganti baris ini sesuai cara kamu membaca dataset, misalnya:
df = pd.read_csv('Dataset_Berlabel.csv')

# Simulasi pembentukan dataset jika belum di-load:
X = df[['pH', 'Kelembaban (%)', 'Suhu (°C)', 'N (mg/kg)', 'P (mg/kg)', 'K (mg/kg)']]
y = df['Label']  # 1.0 = Sesuai, 0.0 = Perlu Perbaikan

feature_names = ['pH', 'Kelembaban (%)', 'Suhu (°C)', 'N (mg/kg)', 'P (mg/kg)', 'K (mg/kg)']
class_names = ['Perlu Perbaikan', 'Sesuai']

# Membagi Data Latih dan Data Uji
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.3, random_state=42, stratify=y
)

# =====================================================================
# 2. PELATIHAN MODEL DECISION TREE
# =====================================================================
dt_model = DecisionTreeClassifier(
    criterion='gini',
    max_depth=5,              # Kedalaman ideal agar pohon tidak overfit
    min_samples_split=10,     # Mencegah percabangan dari sampel terlalu kecil
    min_samples_leaf=5,       # Minimal sampel pada leaf node
    random_state=42
)

# Latih Model
dt_model.fit(X_train, y_train)

# =====================================================================
# 3. KONVERSI KE RULE-BASED LOGIC (TEKS IF-THEN)
# =====================================================================
print("="*60)
print("             HASIL KONVERSI KE RULE-BASED LOGIC             ")
print("="*60)

tree_rules = export_text(
    dt_model,
    feature_names=feature_names
)
print(tree_rules)

# =====================================================================
# 4. VISUALISASI POHON KEPUTUSAN MENGGUNAKAN MATPLOTLIB
# =====================================================================
plt.figure(figsize=(20, 10), dpi=300)

plot_tree(
    dt_model,
    feature_names=feature_names,
    class_names=class_names,
    filled=True,            # Memberi warna pada node berdasarkan dominasi kelas
    rounded=True,           # Membulatkan sudut kotak node
    fontsize=9,
    impurity=True           # Menampilkan nilai Gini Impurity
)

plt.title("Visualisasi Pohon Keputusan (Decision Tree) Kondisi Tanah", fontsize=16, fontweight='bold', pad=20)
plt.tight_layout()

# Simpan gambar ke file jika diperlukan
plt.savefig('decision_tree_visualization.png', dpi=300, bbox_inches='tight')

# Tampilkan grafik
plt.show()