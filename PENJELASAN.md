# 📱 Kos Bae - Dokumentasi Arsitektur Aplikasi

> **Nama Aplikasi**: Kos Bae  
> **Bahasa Pemrograman**: Dart (Flutter)  
> **Backend**: Supabase (PostgreSQL + Auth + Storage)  
> **State Management**: GetX  
> **Versi SDK**: Flutter 3.9.2+

---

## 📋 Daftar Isi

1. [Gambaran Umum](#-gambaran-umum)
2. [Struktur Directory](#-struktur-directory)
3. [Arsitektur Aplikasi](#-arsitektur-aplikasi)
4. [Layer Detail](#-layer-detail)
5. [Database Schema](#-database-schema)
6. [Fitur Aplikasi](#-fitur-aplikasi)
7. [Alur Aplikasi](#-alur-aplikasi)

---

## 🎯 Gambaran Umum

**Kos Bae** adalah aplikasi manajemen kos-kosan berbasis mobile yang dibangun menggunakan Flutter dengan backend Supabase. Aplikasi ini memiliki dua jenis pengguna:

| Role | Deskripsi |
|------|-----------|
| **Admin** | Pemilik/pengelola kos yang dapat mengelola kamar, penyewa, kontrak, tagihan, dan pengumuman |
| **Tenant** | Penyewa/penghuni kos yang dapat melihat tagihan, mengajukan komplain, dan melihat pengumuman |

### 🛠️ Tech Stack

```
┌─────────────────────────────────────────────────────────┐
│                    FRONTEND (Flutter)                    │
├─────────────────────────────────────────────────────────┤
│  • State Management: GetX                               │
│  • UI: Material 3 + Google Fonts                        │
│  • Caching: Hive (Local Storage)                        │
│  • Image: Cached Network Image + Image Picker           │
│  • PDF: pdf + printing packages                         │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                   BACKEND (Supabase)                     │
├─────────────────────────────────────────────────────────┤
│  • Database: PostgreSQL                                 │
│  • Authentication: Supabase Auth                        │
│  • File Storage: Supabase Storage                       │
│  • Security: Row Level Security (RLS)                   │
└─────────────────────────────────────────────────────────┘
```

---

## 📁 Struktur Directory

### Root Project

```
kos_bae/
├── 📁 lib/                    # Source code utama
│   ├── main.dart              # Entry point aplikasi
│   └── 📁 app/                # Kode aplikasi terstruktur
├── 📁 supabase/               # SQL scripts untuk database
├── 📁 assets/                 # Assets (gambar, font, dll)
├── 📁 android/                # Platform-specific Android
├── 📁 ios/                    # Platform-specific iOS
├── 📁 web/                    # Platform-specific Web
├── 📁 windows/                # Platform-specific Windows
├── 📁 linux/                  # Platform-specific Linux
├── 📁 macos/                  # Platform-specific macOS
├── pubspec.yaml               # Dependencies & Config
├── .env                       # Environment variables
└── .env.example               # Contoh environment
```

### Struktur `lib/app/` (Clean Architecture)

```
lib/app/
├── 📁 bindings/               # Dependency Injection (GetX Bindings)
│   └── initial_binding.dart   # Inisialisasi global services
│
├── 📁 core/                   # Core utilities & shared code
│   ├── core.dart              # Barrel file exports
│   ├── 📁 exceptions/         # Custom exception classes
│   │   ├── app_exception.dart
│   │   └── network_exception.dart
│   └── 📁 logger/             # Logging utility
│       └── app_logger.dart
│
├── 📁 middlewares/            # Route middlewares
│   └── auth_middleware.dart   # Proteksi route berdasarkan auth status
│
├── 📁 models/                 # Data models (Entities)
│   ├── announcement_model.dart
│   ├── bill_model.dart
│   ├── complaint_model.dart
│   ├── contract_model.dart
│   ├── payment_detail_model.dart
│   ├── room_model.dart
│   └── tenant_model.dart
│
├── 📁 modules/                # Feature modules (UI + Controller)
│   ├── 📁 admin/              # Modul untuk Admin
│   ├── 📁 tenant/             # Modul untuk Tenant
│   ├── 📁 auth/               # Modul Autentikasi
│   └── 📁 initial/            # Initial/Splash screen
│
├── 📁 routes/                 # Routing configuration
│   ├── app_routes.dart        # Route constants
│   └── app_pages.dart         # Route definitions (GetPages)
│
├── 📁 services/               # Business logic & API services
│   ├── auth_service.dart      # Autentikasi & session
│   ├── supabase_service.dart  # CRUD operations ke Supabase
│   ├── cache_service.dart     # Local caching dengan Hive
│   ├── connectivity_service.dart  # Network status monitoring
│   ├── app_settings_service.dart  # App configuration
│   └── report_service.dart    # PDF report generation
│
├── 📁 theme/                  # Theming & Styling
│   └── app_theme.dart         # Color palette & ThemeData
│
├── 📁 utils/                  # Utility functions
│   ├── image_compressor.dart  # Kompresi gambar sebelum upload
│   └── 📁 validators/         # Form validators
│
└── 📁 widgets/                # Reusable widgets
    ├── menu_item_widget.dart  # Widget menu item
    ├── room_card.dart         # Card kamar
    └── status_badge.dart      # Badge status
```

---

## 🏗️ Arsitektur Aplikasi

Aplikasi ini menggunakan **Clean Architecture** yang dimodifikasi dengan GetX Pattern:

```
┌─────────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                           │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │    Views     │◄───│  Controllers │◄───│   Bindings   │       │
│  │ (UI Widgets) │    │  (GetX Ctrl) │    │ (Dep. Inject)│       │
│  └──────────────┘    └──────────────┘    └──────────────┘       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       SERVICE LAYER                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │ AuthService  │    │SupabaseService│   │ CacheService │       │
│  └──────────────┘    └──────────────┘    └──────────────┘       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        DATA LAYER                                │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │    Models    │    │   Supabase   │    │  Hive (Local)│       │
│  │  (Entities)  │    │   (Remote)   │    │   Storage    │       │
│  └──────────────┘    └──────────────┘    └──────────────┘       │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📚 Layer Detail

### 1️⃣ Entry Point (`main.dart`)

Entry point aplikasi yang menginisialisasi:
- **Flutter Widgets Binding** - Pastikan Flutter engine ready
- **Environment Variables** - Load `.env` untuk config Supabase
- **Date Formatting** - Inisialisasi locale Indonesia
- **Supabase Client** - Koneksi ke backend
- **Async Services** - Services yang butuh async init

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('id_ID', null);
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
  runApp(const KosBaeApp());
  ServiceInitializer.initAsyncServices();
}
```

### 2️⃣ Bindings (`initial_binding.dart`)

Menggunakan **GetX Dependency Injection** untuk register services:

| Service | Type | Deskripsi |
|---------|------|-----------|
| `SupabaseService` | Permanent | CRUD operations ke database |
| `AuthService` | Permanent | Login, logout, session management |
| `CacheService` | Lazy | Local caching dengan Hive |
| `ConnectivityService` | Lazy | Monitor koneksi internet |
| `AppSettingsService` | Lazy | Pengaturan aplikasi |

### 3️⃣ Services Layer

#### `SupabaseService` (31KB, 1058 lines)
Service utama untuk semua operasi database:

**Room Operations:**
- `fetchRooms()` - Ambil semua kamar dengan filter & sorting
- `getRoomById()` - Detail kamar
- `createRoom()` - Buat kamar baru
- `updateRoom()` - Update data kamar
- `deleteRoom()` - Hapus kamar
- `getRoomStatistics()` - Statistik kamar

**Tenant Operations:**
- `fetchTenants()` - Ambil semua penyewa
- `getTenantById()` - Detail penyewa
- `createTenant()` - Registrasi penyewa baru
- `updateTenant()` - Update data penyewa
- `deleteTenant()` - Hapus penyewa

**Bill Operations:**
- `fetchBills()` - Ambil tagihan
- `createBill()` - Buat tagihan
- `updateBillStatus()` - Update status pembayaran

**Storage Operations:**
- `uploadFile()` - Upload foto ke Supabase Storage
- `uploadMultipleFiles()` - Upload multiple files
- `deleteFile()` - Hapus file dari storage

#### `AuthService` (3.9KB, 144 lines)
Manajemen autentikasi:

| Method | Deskripsi |
|--------|-----------|
| `signIn()` | Login dengan email & password |
| `signOut()` | Logout user |
| `changePassword()` | Ganti password |
| `getCurrentUserRole()` | Ambil role (admin/tenant) |
| `getCurrentTenantId()` | Ambil tenant ID dari user login |

#### `CacheService` - Local caching dengan Hive
#### `ConnectivityService` - Monitor koneksi internet
#### `ReportService` - Generate laporan PDF

### 4️⃣ Models Layer

#### `Tenant` Model
```dart
class Tenant {
  final String id;
  final String name;
  final String phone;
  final String? nik;
  final String? address;
  final String? photoUrl;
  final String? roomNumber;      // Dari join contract → room
  final String? contractId;      // Kontrak aktif
  final DateTime? contractStartDate;
  final DateTime? contractEndDate;
  final String status;           // aktif, nonaktif, keluar
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? userId;          // Link ke auth.users
}
```

#### Model Lainnya:
| Model | Deskripsi |
|-------|-----------|
| `Room` | Data kamar (nomor, harga, status, fasilitas, foto) |
| `Bill` | Tagihan bulanan (tenant, amount, due date, status) |
| `Contract` | Kontrak sewa (tenant, room, start/end date) |
| `Complaint` | Laporan komplain dari tenant |
| `Announcement` | Pengumuman dari admin |
| `PaymentDetail` | Detail pembayaran tagihan |

### 5️⃣ Modules Layer

#### Admin Modules (`lib/app/modules/admin/`)

```
admin/
├── 📁 admin_drawer/       # Sidebar navigation
├── 📁 admin_layout/       # Main layout dengan drawer
├── 📁 dashboard/          # Dashboard statistik
├── 📁 rooms_management/   # CRUD kamar
├── 📁 tenants/            # CRUD penyewa
├── 📁 contracts/          # Manajemen kontrak
├── 📁 bills/              # Manajemen tagihan
├── 📁 payments/           # Konfirmasi pembayaran
├── 📁 complaints/         # Kelola komplain
├── 📁 announcements/      # Buat pengumuman
├── 📁 billing/            # Generate tagihan otomatis
└── 📁 settings/           # Pengaturan aplikasi
```

#### Tenant Modules (`lib/app/modules/tenant/`)

```
tenant/
├── 📁 tenant_layout/      # Main layout dengan bottom nav
├── 📁 tenant_nav/         # Bottom navigation
├── 📁 home/               # Home dashboard
├── 📁 bills/              # Lihat & bayar tagihan
├── 📁 complaints/         # Ajukan komplain
├── 📁 announcements/      # Lihat pengumuman
├── 📁 profile/            # Profile & edit profile
└── 📁 help/               # Bantuan
```

#### Auth Modules (`lib/app/modules/auth/`)

```
auth/
├── 📁 login/              # Halaman login
└── 📁 splash/             # Splash screen & routing
```

### 6️⃣ Routes Layer

#### Route Constants (`app_routes.dart`)

```dart
abstract class AppRoutes {
  // Initial & Auth
  static const INITIAL = '/';
  static const SPLASH = '/splash';
  static const LOGIN = '/login';

  // Admin Routes
  static const ADMIN_LAYOUT = '/admin';
  static const ADMIN_DASHBOARD = '/admin/dashboard';
  static const ADMIN_ROOMS = '/admin/rooms';
  static const ADMIN_TENANTS = '/admin/tenants';
  static const ADMIN_BILLS = '/admin/bills';
  static const ADMIN_CONTRACTS = '/admin/contracts';
  static const ADMIN_PAYMENTS = '/admin/payments';
  static const ADMIN_COMPLAINTS = '/admin/complaints';
  static const ADMIN_ANNOUNCEMENTS = '/admin/announcements';
  static const ADMIN_SETTINGS = '/admin/settings';

  // Tenant Routes
  static const TENANT_LAYOUT = '/tenant';
  static const TENANT_HOME = '/tenant/home';
  static const TENANT_BILLS = '/tenant/bills';
  static const TENANT_COMPLAINTS = '/tenant/complaints';
  static const TENANT_PROFILE = '/tenant/profile';
  static const TENANT_ANNOUNCEMENTS = '/tenant/announcements';
}
```

### 7️⃣ Theme Layer (`app_theme.dart`)

Color palette premium dengan tema Blue & Cream:

| Color | Hex | Deskripsi |
|-------|-----|-----------|
| `primaryBlue` | `#5B8DB8` | Warna utama aplikasi |
| `deepBlue` | `#2C3E50` | Warna sekunder gelap |
| `lightBlue` | `#7BA9CC` | Aksen biru terang |
| `cream` | `#F5E6D3` | Warna cream hangat |
| `gold` | `#D4AF37` | Aksen premium |
| `charcoal` | `#2D3436` | Dark gray untuk teks |

---

## 🗄️ Database Schema

### Entity Relationship Diagram

```
┌─────────────────┐       ┌─────────────────┐
│   auth.users    │       │    profiles     │
│─────────────────│       │─────────────────│
│ id (PK)         │◄──────│ id (FK)         │
│ email           │       │ full_name       │
│ ...             │       │ phone           │
└────────┬────────┘       │ role            │
         │                │ avatar_url      │
         │                └─────────────────┘
         │
         ▼
┌─────────────────┐       ┌─────────────────┐
│    tenants      │       │     rooms       │
│─────────────────│       │─────────────────│
│ id (PK)         │       │ id (PK)         │
│ name            │       │ room_number     │
│ phone           │       │ price           │
│ nik             │       │ status          │
│ address         │       │ photos (JSONB)  │
│ photo_url       │       │ facilities      │
│ contract_id(FK) │───┐   │ description     │
│ user_id (FK)    │   │   └────────┬────────┘
│ status          │   │            │
└────────┬────────┘   │            │
         │            │            │
         │            ▼            │
         │   ┌─────────────────┐   │
         │   │   contracts     │   │
         │   │─────────────────│   │
         │   │ id (PK)         │   │
         └───│ tenant_id (FK)  │   │
             │ room_id (FK)    │───┘
             │ start_date      │
             │ end_date        │
             │ rent_amount     │
             │ status          │
             └────────┬────────┘
                      │
                      ▼
              ┌─────────────────┐
              │     bills       │
              │─────────────────│
              │ id (PK)         │
              │ contract_id(FK) │
              │ tenant_id (FK)  │
              │ type            │
              │ amount          │
              │ due_date        │
              │ status          │
              │ payment_proof   │
              └─────────────────┘

┌─────────────────┐       ┌─────────────────┐
│   complaints    │       │ announcements   │
│─────────────────│       │─────────────────│
│ id (PK)         │       │ id (PK)         │
│ room_id (FK)    │       │ title           │
│ tenant_id (FK)  │       │ content         │
│ title           │       │ is_pinned       │
│ description     │       │ created_by      │
│ media (JSONB)   │       │ created_at      │
│ status          │       └─────────────────┘
└─────────────────┘
```

### Tabel Utama

#### `rooms` - Data Kamar
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| room_number | TEXT | Nomor kamar (unique) |
| price | NUMERIC | Harga sewa bulanan |
| status | TEXT | `kosong`, `terisi`, `maintenance` |
| photos | JSONB | Array URL foto |
| facilities | JSONB | Array fasilitas |
| description | TEXT | Deskripsi kamar |

#### `tenants` - Data Penyewa
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| name | TEXT | Nama lengkap |
| phone | TEXT | Nomor telepon |
| nik | TEXT | NIK/KTP |
| address | TEXT | Alamat asal |
| photo_url | TEXT | URL foto profil |
| contract_id | UUID | FK ke contracts |
| user_id | UUID | FK ke auth.users |
| status | TEXT | `aktif`, `nonaktif`, `keluar` |

#### `contracts` - Data Kontrak
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| tenant_id | UUID | FK ke tenants |
| room_id | UUID | FK ke rooms |
| start_date | DATE | Tanggal mulai |
| end_date | DATE | Tanggal berakhir |
| rent_amount | NUMERIC | Biaya sewa |
| deposit_amount | NUMERIC | Uang deposit |
| status | TEXT | `aktif`, `berakhir`, `dibatalkan` |

#### `bills` - Data Tagihan
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| contract_id | UUID | FK ke contracts |
| tenant_id | UUID | FK ke tenants |
| type | TEXT | `sewa`, `listrik`, `air`, dll |
| amount | NUMERIC | Jumlah tagihan |
| due_date | DATE | Tanggal jatuh tempo |
| status | TEXT | `unpaid`, `pending`, `paid`, `overdue` |
| payment_proof_url | TEXT | Bukti pembayaran |

### Row Level Security (RLS)

Semua tabel dilindungi dengan RLS policies:

```sql
-- Contoh: Hanya admin yang bisa CRUD rooms
CREATE POLICY "Admins can insert rooms"
  ON public.rooms FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
```

---

## ✨ Fitur Aplikasi

### 👨‍💼 Admin Features

| Fitur | Deskripsi |
|-------|-----------|
| **Dashboard** | Statistik kamar, penyewa, tagihan |
| **Manajemen Kamar** | CRUD kamar + upload foto |
| **Manajemen Penyewa** | CRUD penyewa + link account |
| **Manajemen Kontrak** | Buat, perpanjang, akhiri kontrak |
| **Manajemen Tagihan** | Generate tagihan otomatis/manual |
| **Konfirmasi Pembayaran** | Approve/reject pembayaran |
| **Kelola Komplain** | Proses komplain dari tenant |
| **Pengumuman** | Broadcast info ke semua tenant |
| **Pengaturan** | Due date, denda, reminder |
| **Laporan PDF** | Export laporan berbagai periode |

### 👤 Tenant Features

| Fitur | Deskripsi |
|-------|-----------|
| **Home** | Info kamar, kontrak, tagihan terbaru |
| **Tagihan** | Lihat & upload bukti bayar |
| **Komplain** | Ajukan komplain + foto/video |
| **Pengumuman** | Lihat pengumuman dari admin |
| **Profil** | Edit data diri & foto |
| **Ganti Password** | Update password akun |

---

## 🔄 Alur Aplikasi

### 1. Login Flow

```
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│  Splash Screen │────▶│  Check Auth   │────▶│ Fetch Role    │
└───────────────┘     └───────────────┘     └───────┬───────┘
                                                     │
                      ┌──────────────────────────────┴──────┐
                      ▼                                     ▼
               ┌───────────────┐                     ┌───────────────┐
               │  Admin Layout │                     │ Tenant Layout │
               │  (Dashboard)  │                     │    (Home)     │
               └───────────────┘                     └───────────────┘
```

### 2. Billing Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Admin Create│────▶│ Tenant Sees │────▶│Upload Proof │
│    Bill     │     │   Bill      │     │ Pembayaran  │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                    ┌──────────────────────────┘
                    ▼
             ┌─────────────┐     ┌─────────────┐
             │Admin Review │────▶│Update Status│
             │   Payment   │     │(Paid/Reject)│
             └─────────────┘     └─────────────┘
```

### 3. Complaint Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│Tenant Create│────▶│Status: OPEN │────▶│Admin Process│
│  Complaint  │     │             │     │  Complaint  │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                    ┌──────────────────────────┴───────┐
                    ▼                                  ▼
             ┌─────────────┐                    ┌─────────────┐
             │IN_PROGRESS  │───────────────────▶│  RESOLVED   │
             └─────────────┘                    └─────────────┘
```

---

## 📦 Dependencies

### Main Dependencies

| Package | Version | Deskripsi |
|---------|---------|-----------|
| `get` | ^4.6.6 | State management & routing |
| `supabase_flutter` | ^2.8.0 | Supabase client |
| `image_picker` | ^1.1.2 | Ambil foto dari galeri/kamera |
| `cached_network_image` | ^3.4.1 | Caching gambar |
| `file_picker` | ^8.0.0 | Pilih file dari device |
| `flutter_dotenv` | ^5.2.1 | Load environment variables |
| `intl` | ^0.19.0 | Internasionalisasi & formatting |
| `google_fonts` | ^6.1.0 | Google Fonts untuk typography |
| `shimmer` | ^3.0.0 | Loading shimmer effect |
| `hive` | ^2.2.3 | Local database |
| `hive_flutter` | ^1.1.0 | Hive untuk Flutter |
| `connectivity_plus` | ^6.0.3 | Cek koneksi internet |
| `pdf` | ^3.10.8 | Generate PDF |
| `printing` | ^5.12.0 | Print/share PDF |
| `flutter_image_compress` | ^2.3.0 | Kompresi gambar |

---

## ⚙️ Setup & Konfigurasi

### 1. Environment Variables (`.env`)

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Setup Database

Jalankan SQL scripts di folder `supabase/` secara berurutan:
1. `SCHEMA.sql` - Tabel utama & RLS
2. `CONTRACTS_TABLE.sql` - Tabel kontrak
3. `BILLS_TABLE.sql` - Tabel tagihan
4. `ANNOUNCEMENTS_TABLE.sql` - Tabel pengumuman
5. `COMPLAINTS_TABLE.sql` - Tabel komplain

### 4. Run Aplikasi

```bash
flutter run
```

---

## 📝 Catatan Developer

### Konvensi Penamaan

| Kategori | Format | Contoh |
|----------|--------|--------|
| File | snake_case | `tenant_model.dart` |
| Class | PascalCase | `TenantController` |
| Variable | camelCase | `currentTenant` |
| Constant | camelCase | `primaryBlue` |
| Route | SCREAMING_SNAKE | `ADMIN_DASHBOARD` |

### Best Practices

1. **Gunakan `Get.find()` untuk akses service**, bukan buat instance baru
2. **Selalu handle error** dengan try-catch dan tampilkan pesan ke user
3. **Compress gambar** sebelum upload dengan `ImageCompressor`
4. **Gunakan Obx()** untuk reactive UI dengan GetX
5. **Log penting** dengan `AppLogger` untuk debugging

---

*Dokumentasi ini dibuat otomatis - Last updated: Desember 2024*
