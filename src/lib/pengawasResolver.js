/**
 * Helper untuk resolve data pengawas dari user yang sedang login
 * Digunakan di semua template cetak untuk mengisi tanda tangan otomatis
 */

/**
 * Cari pengawas yang match dengan user login
 * Priority:
 * 1. user.pengawasId (kalau ada mapping langsung)
 * 2. Match by nama (case-insensitive, partial match)
 * 3. Return virtual pengawas dari user data
 */
/**
 * True saat laporan dibuat oleh Ketua Pokjawas.
 * Role adalah sinyal utama; nama/jabatan/settings menjadi fallback agar tetap
 * aman untuk user lokal, user Supabase, serta data lama tanpa role konsisten.
 */
export function isKetuaPokjawas(user, settings = {}) {
  if (!user) return false
  const norm = (value) => String(value || '').toLowerCase().replace(/[^a-z0-9]/g, '')
  const role = norm(user.role || user.peran || user.jabatan || user.user_metadata?.role)
  if (role === 'admin' || role.includes('ketuapokjawas')) return true

  const userName = norm(user.nama || user.namaLengkap || user.name || user.username)
  const ketuaName = norm(settings.ketuaPokjawas || settings.namaKetuaPokjawas)
  if (!userName || !ketuaName) return false
  // Includes mengakomodasi gelar yang hanya tersimpan di salah satu sumber.
  return userName === ketuaName || (
    Math.min(userName.length, ketuaName.length) >= 5 &&
    (userName.includes(ketuaName) || ketuaName.includes(userName))
  )
}

export function resolvePengawasFromUser(user, pengawasList = []) {
  if (!user) return null

  // 1. Kalau user punya pengawasId langsung
  if (user.pengawasId) {
    const found = pengawasList.find((p) => p.id === user.pengawasId)
    if (found) return found
  }

  // 2. Match by nama (case-insensitive)
  if (user.nama) {
    const userName = user.nama.toLowerCase()
    const found = pengawasList.find((p) => {
      const pengawasName = p.nama?.toLowerCase() || ''
      // Match kalau salah satu contains yang lain
      return pengawasName.includes(userName) || userName.includes(pengawasName)
    })
    if (found) return found
  }

  // 3. Return virtual pengawas dari user data
  return {
    id: user.id,
    nama: user.nama || user.username || '____________________',
    namaLengkap: user.namaLengkap || user.nama || '',
    nip: user.nip || '',
    pangkat: user.pangkat || '',
    jabatan: user.jabatan || 'Pengawas Pendamping',
    // Field lain kosong
    wilayah: '',
    hp: '',
    email: user.username || ''
  }
}
