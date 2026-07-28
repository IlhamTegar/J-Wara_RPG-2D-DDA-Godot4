# 🗡️ RPG 2D Adaptif dengan Dynamic Difficulty Adjustment (DDA)

![Godot Engine](https://img.shields.io/badge/Godot_Engine-4.x-blue?logo=godotengine)
![License](https://img.shields.io/badge/License-MIT-green)
![Testing](https://img.shields.io/badge/Testing-GUT_100%25_Passed-brightgreen)

Purwarupa *game* RPG 2D adaptif yang dikembangkan menggunakan **Godot Engine 4.x**. Game ini menerapkan mekanisme **Dynamic Difficulty Adjustment (DDA)** berbasis Logika Fuzzy untuk menyesuaikan tingkat kesulitan permainan secara otomatis berdasarkan performa pemain secara *real-time*.

---

## 🎮 Unduh & Mainkan Game (Executable)

Kamu dapat mengunduh dan memainkan langsung *build game* ini tanpa perlu membuka Godot Engine:

[![Download Game](https://img.shields.io/badge/Download_Game-v1.0.0_(ZIP)-blue?style=for-the-badge&logo=windows)](https://github.com/IlhamTegar/J-Wara_RPG-2D-DDA-Godot4/releases/download/v1.0.0/game.zip)

> **Cara Menjalankan Game:**
> 1. Unduh file `.zip` melalui tombol di atas.
> 2. *Extract* (ekstrak) folder `.zip` tersebut di komputer kamu.

---


## 🌟 Fitur Utama

- **Real-Time DDA Mikro (Fuzzy Mamdani):** Menyesuaikan kapasitas *spawner* musuh secara dinamis saat pertempuran berlangsung berdasarkan *sisa HP* dan *rate sukses defensif (dodge/parry)* pemain.
- **Wave-Based DDA Makro (Fuzzy Sugeno Orde-0):** Mengevaluasi agregat performa pemain di akhir gelombang (*wave*) untuk memperbarui koefisien pengali (*multiplier*) kekuatan musuh pada gelombang berikutnya.
- **Wave-Completion Combat System:** Mekanik permainan berfokus pada penyelesaian gelombang musuh untuk mengakses kembali area *Safezone*.
- **Automated Integration Testing (GUT):** Seluruh modul fungsionalitas diuji secara otomatis menggunakan *framework* **GUT (Godot Unit Test)** dengan hasil kelolosan 100% (9/9 Passed).

---

## 📸 Tampilan Permainan (Screenshots)

| Main Menu & Input Nama | Area Safezone (Desa) |
| :---: | :---: |
| *(Isi Link / Gambar Screenshot Main Menu)* | *(Isi Link / Gambar Screenshot Safezone)* |

| Pertempuran Arena Combat | Pengujian Otomatis (GUT Console) |
| :---: | :---: |
| *(Isi Link / Gambar Screenshot Combat)* | *(Isi Link / Gambar Screenshot GUT)* |

---

## 🛠️ Teknologi & Tools

- **Game Engine:** Godot Engine 4.x
- **Bahasa Pemrograman:** GDScript
- **Framework Testing:** GUT (Godot Unit Test) v9.x
- **Desain Grafik:** Pixel Art 2D
- **Sistem AI DDA:** Fuzzy Logic (Mamdani & Sugeno Orde-0)

---

## 🚀 Cara Menjalankan Proyek

### Prasyarat
- [Godot Engine 4.x](https://godotengine.org/download) terinstal di komputer.

### Langkah-Langkah
1. *Clone* repositori ini ke komputer lokal:
   ```bash
   git clone [https://github.com/USERNAME_KAMU/NAMA_REPO_KAMU.git](https://github.com/USERNAME_KAMU/NAMA_REPO_KAMU.git)
