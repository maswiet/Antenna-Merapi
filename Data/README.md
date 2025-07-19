## 🔗 Data Source

Untuk menghindari data corrupt atau data hilang atau terhapus, hindari menyimpan data di hardisk Laptop/PC, kecuali hanya sample data, mengingat ukuran file data yang cukup besar, untuk itu disarankan melakukan sinkronisasi data menggunakan drive komersial (Onedrive/GDrive/DrobBox) atau Server Data Geofisika UGM
Karena ukuran file terlalu besar untuk GitHub, sampel data MiniSEED dapat diakses di:

📁 [OneDrive Folder – Seismic Data](https://1drv.ms/f/c/dc41f2b8d85d266b/EmsmXdi48kEggNxmAAAAAAABw-10A6RHaFBtJznXEZrMzg?e=nh7eCc)

📁 Data Server Geofisika UGM 

[](Gambar/folder_sample.png)

Selengkapnya dapat menghubungi saya atau Gempa.GmbH

## Struktur Folder Data
[Nama Stasiun]
└── EHZ.D (folder data seismik)
└── HDF.D (folder data infrasound)

File: AM.[NamaStasiun].00.EHZ.D.[Tahun].[JulianDay]

Contoh: AM.R7D17.00.EHZ.D.2023.248 (artinya data seismik stasiun R7D17 pada hari ke-248 tahun 2023)

Makna Penamaan File:
- AM = Prefix jaringan Raspberry Shake
- R7D17 = Nama stasiun
- 00 = Channel code (umumnya default)
- EHZ.D = Seismik (vertical), HDF.D = Infrasound
- 2023 = Tahun
- 248 = Julian day (hari ke-248)

