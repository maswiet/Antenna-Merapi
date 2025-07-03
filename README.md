# Antenna-Merapi

**Antenna-Merapi** adalah repositori yang berisi data dan kode pemrosesan seismik dan infrasonik dari 5 stasiun yang terpasang di Gunung Merapi, Indonesia. Proyek ini adalah kolaborasi antara Laboratorium Geofisika UGM dengan [Gempa GmbH](https://www.gempa.de/) yang bertujuan untuk menampilkan, memilih, dan menganalisis event seismik dan infrasonik dengan pendekatan **array processing**.

![Alt text](Gambar/AntennaMerapi.jpg)

---

## 📁 Struktur Repositori

```
Antenna-Merapi/
│
├── Data/
│   ├── seismic/           # Data mentah seismik (MiniSEED, SAC, dll.)
│   └── infrasound/        # Data mentah infrasonik
│
├── Code/
│   ├── view_event.py      # Menampilkan sinyal event
│   ├── cut_event.py       # Memotong sinyal berdasarkan waktu event
│   ├── select_event.py    # Antarmuka atau skrip pemilihan event penting
│   ├── array_processing.py# Beamforming atau FK analysis
│   └── utils/             # Fungsi bantu (filtering, plotting, dll.)
│
├── Manuscript/
│   └── Paper-paper related to infrasonic or antenna project  # Contoh analisis interaktif
│
└── README.md
```

---

## 📌 Fitur Utama

- ✅ **Menampilkan event** dari data mentah seismik dan infrasonik
- ✂️ **Memotong event** berdasarkan waktu atau katalog <br>

 ![Alt text](Code/Gambar/bukpot.png)
- ⭐ **Memilih event** untuk dianalisis lebih lanjut
- 📡 **Array processing** (beamforming, FK analysis) untuk estimasi arah datang dan kecepatan fasa
- 📊 Visualisasi waveforms, array response, dan peta polar

---
![Alt text](Code/Gambar/psd.png)
## 🔧 Persyaratan

### MATLAB
Repositori ini juga mendukung lingkungan MATLAB (Code telah ditest dengan MatlabR2025a) untuk pemrosesan data seismik dan infrasonik. Pastikan Anda memiliki MATLAB dengan toolbox berikut:
- Signal Processing Toolbox
- Mapping Toolbox
- Statistics and Machine Learning Toolbox
- Deep Learning Toolbox
- Wavelet Toolbox

### Python (Under Construction)
- Python ≥ 3.8
- Paket yang diperlukan:
  - `obspy`
  - `numpy`
  - `matplotlib`
  - `scipy`
  - `pandas`
  - `pyproj`
  - (opsional) `ipympl` untuk interaktivitas

Install dependencies:

```bash
pip install -r requirements.txt
```

---

<!--## 🚀 Cara Menggunakan

### 1. Menampilkan Event
```bash
python scripts/view_event.py --start 2023-08-25T16:00:00 --end 2023-08-25T17:00:00
```

### 2. Memotong Event
```bash
python scripts/cut_event.py --catalog catalog.csv --margin 30
```

### 3. Memilih Event
```bash
python scripts/select_event.py --input_folder cut_data/
```

### 4. Array Processing
```bash
python scripts/array_processing.py --method fk --channel EHZ --start 2023-08-25T16:10:00 --end 2023-08-25T16:15:00
```
-->
---

## 📌 Catatan

- Penamaan stasiun mengacu pada kode Raspberry Shake atau Raspberry Boom.
- Semua waktu menggunakan **UTC**.
- Kode ini dikembangkan untuk mendukung riset mitigasi erupsi Merapi berbasis data real-time.

---

## 📚 Lisensi

MIT License © 2025 Wiwit Suryanto – Universitas Gadjah Mada

---

## 📬 Kontak

Wiwit Suryanto  
Geophysics Research Group, FMIPA UGM  
✉️ ws@ugm.ac.id  
🌐 https://physics.ugm.ac.id

![LinkedIn](https://img.shields.io/badge/LinkedIn-wiwit--suryanto-blue?logo=linkedin&style=flat-square) [Wiwit](https://www.linkedin.com/in/wiwit-suryanto-10567711/)



