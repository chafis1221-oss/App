# QRIS Monitor

Aplikasi Android untuk menerima notifikasi pembayaran QRIS secara real-time melalui WebSocket.

## Fitur

- Koneksi WebSocket ke server STB
- Notifikasi Android real-time
- Pemutaran audio WAV dari server
- Riwayat notifikasi (maksimal 100 item)
- Background service dengan foreground notification
- Auto-reconnect saat koneksi terputus

## Teknologi

- Flutter 3.x
- Provider (state management)
- WebSocket (web_socket_channel)
- Audio Player (audioplayers)
- Local Notifications (flutter_local_notifications)
- Foreground Service (flutter_foreground_task)

## Build APK

Build otomatis menggunakan GitHub Actions.
Setiap push ke branch `main` akan menghasilkan APK release.

Download artifact dari tab **Actions** > workflow terbaru > **Artifacts**.

## Konfigurasi

1. Buka halaman **Settings**
2. Masukkan WebSocket URL (contoh: `ws://192.168.1.100:8080/ws`)
3. Masukkan token WebSocket
4. Kembali ke halaman utama dan tekan **Mulai Monitoring**

## Lisensi

Internal use only.
