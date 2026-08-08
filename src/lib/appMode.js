// =============================================================================
// Mode aplikasi: multi-user (Supabase cloud sync antar perangkat)
// =============================================================================
// false = mode multi-user: data tersinkron via Supabase, semua role lihat data sama
// true  = mode lokal-only (emergency fallback, data per-browser)
//
// Supabase dipakai untuk:
//   1. Auth (login email + password)
//   2. Validasi kode aktivasi (read activation_codes)
//   3. Sinkronisasi data (madrasah, pengawas, jadwal, pendampingan, eviden, dll)
//   4. Tag kode aktivasi sebagai 'used' setelah aktivasi
// =============================================================================
export const LOCAL_ONLY_MODE = false
