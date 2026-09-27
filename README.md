# Sistem Piutang Usaha CV Kokoh

Sistem informasi piutang usaha untuk distributor bahan bangunan yang dibuat sebagai aplikasi web statis berbasis HTML, CSS, dan JavaScript. Aplikasi ini dirancang untuk memantau pelanggan, invoice, pembayaran, serta status piutang secara sederhana namun fungsional.

## Fitur utama

- Dashboard ringkasan piutang
- Data pelanggan
- Pembuatan invoice dan detail item barang
- Pembayaran pelanggan
- Riwayat pembayaran
- Aging schedule / analisis umur piutang
- Peringatan utang perusahaan
- Download laporan buku besar pembantu piutang
- Fitur diskon 2/10, n/30
- Integrasi dengan Supabase PostgreSQL (opsional)

## Struktur project

```text
SistemPiutangUsaha/
├── backend/
│   ├── app.js
│   └── schema.sql
├── frontend/
│   ├── css/
│   ├── js/
│   └── index.html
├── README.md
└── .gitignore
```

## Teknologi

- HTML
- CSS
- JavaScript
- Supabase (PostgreSQL)
- Browser-based static app

## Cara menjalankan

Karena aplikasi ini dibuat tanpa Node.js dan tanpa build tools, Anda cukup membuka file berikut di browser:

- frontend/index.html

Atau jika ingin lebih rapi saat dipublish, pindahkan file frontend/index.html menjadi halaman utama project atau gunakan GitHub Pages dengan folder frontend sebagai publik.

## Catatan penting

- Aplikasi ini tidak memerlukan `npm install`
- Tidak perlu file `package.json`
- Tidak perlu menjalankan server Node
- Data dapat dipakai secara local di browser, dan dapat dihubungkan ke Supabase bila konfigurasi tersedia

## Supabase

File backend/app.js dan backend/schema.sql sudah menyiapkan struktur database PostgreSQL untuk:

- customers
- products
- invoices
- invoice_items
- payments

Anda dapat mengeksekusi file schema.sql di SQL editor Supabase untuk membuat tabel.

## Deployment ke GitHub Pages

1. Upload project ke repository GitHub
2. Masuk ke Settings > Pages
3. Pilih branch yang akan dipublish
4. Gunakan folder root atau folder frontend sesuai struktur yang Anda inginkan
5. Simpan dan tunggu proses publish selesai

## Penjelasan ringkas

Project ini dibuat sebagai web app untuk mengelola piutang usaha distributor bahan bangunan, dengan fokus pada proses:

- pelanggan membeli barang secara kredit
- invoice diterbitkan dan jatuh tempo dicatat
- pembayaran pelanggan dicatat
- sisa piutang dihitung otomatis
- analisis aging dilakukan berdasarkan umur piutang

## Lisensi

Project ini dibuat untuk kebutuhan pembelajaran dan pengembangan aplikasi akuntansi sederhana.

## Pengembang

CV Kokoh
Distributor Bahan Bangunan
