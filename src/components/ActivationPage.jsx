import { useState } from 'react'
import { saveLicense, verifyMasterCode } from '../lib/codes.js'
import { verifySignedCode } from '../lib/signedLicense.js'
import { SUPABASE_ENABLED, supabase } from '../lib/supabase.js'
import { useData } from '../context/DataContext.jsx'
import { getDeviceId, isCodeUsed, markCodeUsed, getUsedCodeDevice } from '../lib/deviceLock.js'
import { LOCAL_ONLY_MODE } from '../lib/appMode.js'

const REGISTERED_USERS_KEY = 'kbc_registered_users_v1'

function saveRegisteredUser(nama, password, role, madrasahId, email) {
  try {
    const list = JSON.parse(localStorage.getItem(REGISTERED_USERS_KEY) || '[]')
    const idx = list.findIndex((u) => u.nama.toLowerCase() === nama.toLowerCase())
    const userObj = {
      id: idx >= 0 ? list[idx].id : 'reg-' + Date.now() + '-' + Math.random().toString(36).slice(2, 8),
      nama, password, role, email,
      madrasahId: (role === 'kepala' || role === 'kepala_madrasah') ? madrasahId : null,
      createdAt: idx >= 0 ? list[idx].createdAt : new Date().toISOString(),
      activatedAt: new Date().toISOString()
    }
    if (idx >= 0) list[idx] = userObj; else list.unshift(userObj)
    localStorage.setItem(REGISTERED_USERS_KEY, JSON.stringify(list))
  } catch {}
}

export default function ActivationPage({ onActivated }) {
  const { state } = useData()
  const madrasahList = state?.madrasah || []

  const [code, setCode] = useState('')
  const [nama, setNama] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [password2, setPassword2] = useState('')
  const [selectedRole, setSelectedRole] = useState('pengawas')
  const [selectedMadrasahId, setSelectedMadrasahId] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const handleActivate = async (e) => {
    e.preventDefault()
    const cleanCode = String(code).trim().toUpperCase()
    const cleanNama = String(nama).trim()
    const cleanEmail = String(email).trim().toLowerCase()
    if (!cleanCode) { setError('Masukkan kode aktivasi'); return }
    if (!cleanNama) { setError('Isi nama Bapak/Ibu'); return }
    if (SUPABASE_ENABLED && !cleanEmail) { setError('Isi email Bapak/Ibu'); return }
    if (SUPABASE_ENABLED && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(cleanEmail)) { setError('Format email tidak valid'); return }
    if (password.length < 4) { setError('Password minimal 4 karakter'); return }
    if (password !== password2) { setError('Konfirmasi password tidak cocok'); return }

    // === Master code diverifikasi server (kode asli tidak ada di file ini) ===
    setLoading(true); setError('')
    let isMaster = false
    try {
      const mv = await verifyMasterCode(cleanCode)
      isMaster = !!(mv && mv.valid)
    } catch { isMaster = false }

    // === One-time use: cek apakah kode sudah pernah dipakai ===
    if (!isMaster && isCodeUsed(cleanCode)) {
      const usedDevice = getUsedCodeDevice(cleanCode)
      const currentDevice = getDeviceId()
      if (usedDevice && usedDevice !== currentDevice) {
        setError('Kode aktivasi ini sudah dipakai di perangkat lain. Setiap kode hanya berlaku untuk 1 perangkat.')
        setLoading(false)
        return
      }
      // Same device re-use: juga ditolak (one-time)
      setError('Kode aktivasi ini sudah pernah dipakai. Setiap kode hanya bisa dipakai 1 kali.')
      setLoading(false)
      return
    }

    try {
      let tier, label = '', exp = 0, role = 'pengawas'
      if (isMaster) {
        tier = 'pro'; label = 'Master (Owner)'; role = 'admin'
      } else {
        const r = await verifySignedCode(cleanCode)
        if (!r.valid) { setError(r.error || 'Kode tidak valid'); setLoading(false); return }
        tier = r.tier; label = r.label
        if (r.expiryDays > 0) exp = Date.now() + r.expiryDays * 86400000
        
        role = selectedRole
        if (role === 'kepala_madrasah' && !selectedMadrasahId) {
          setError('Pilih madrasah piloting Bapak/Ibu')
          setLoading(false)
          return
        }
      }

      // === Device lock: bind lisensi ke device ID ===
      const deviceId = getDeviceId()
      saveLicense(cleanCode, tier, { 
        via: 'signed-license', 
        label, 
        expiresAt: exp, 
        nama: cleanNama, 
        role,
        deviceId,
        deviceLocked: !isMaster
      })

      // === Tandai kode sebagai sudah terpakai (one-time) ===
      if (!isMaster) {
        markCodeUsed(cleanCode, deviceId, cleanNama)
      }

      // Simpan akun lokal di perangkat ini. Ini wajib dilakukan meskipun
      // Supabase aktif, karena LOCAL_ONLY_MODE memakai login lokal untuk akun
      // hasil aktivasi (tanpa ketergantungan konfirmasi email Supabase).
      saveRegisteredUser(cleanNama, password, role, selectedMadrasahId, cleanEmail)

      if (SUPABASE_ENABLED && supabase && !LOCAL_ONLY_MODE) {
        // Klaim atomik di server: satu kode hanya bisa dikunci sekali.
        if (!isMaster) {
          const { data: claim, error: claimError } = await supabase.rpc('claim_activation_code', {
            p_code: cleanCode,
            p_nama: cleanNama,
            p_device_id: deviceId
          })
          if (claimError || !claim?.ok) {
            setError(claimError?.message || claim?.error || 'Kode aktivasi sudah digunakan atau tidak valid')
            setLoading(false)
            return
          }
          tier = claim.tier || tier
          role = claim.role || role
          exp = claim.validity_days > 0 ? Date.now() + claim.validity_days * 86400000 : exp
        }

        const { data, error: signUpError } = await supabase.auth.signUp({
          email: cleanEmail,
          password,
          options: {
            data: {
              nama: cleanNama,
              role,
              pengawas_id: '',
              madrasah_id: role === 'kepala_madrasah' ? selectedMadrasahId : ''
            }
          }
        })
        if (signUpError) {
          setError('Gagal mendaftar: ' + signUpError.message)
          setLoading(false)
          return
        }
        if (!isMaster) {
          try {
            await supabase
              .from('activation_codes')
              .update({ used: true, used_by: data.user?.id, used_at: new Date().toISOString(), device_id: deviceId })
              .eq('code', cleanCode)
              .eq('used', false)
          } catch {}
        }
      }

      try { localStorage.removeItem('kbc_local_user_v1') } catch {}

      onActivated({ code: cleanCode, tier })
      setTimeout(() => window.location.reload(), 100)
    } catch (err) {
      setError('Gagal: ' + (err.message || 'Coba lagi'))
    } finally { setLoading(false) }
  }

  const goToLogin = () => {
    saveLicense('TEMP-LOGIN', 'pro', { 
      via: 'temp-login-bypass',
      expiresAt: Date.now() + 3600000
    })
    window.location.reload()
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-navy-900 to-navy-800 px-4 py-8">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-toska-500/20 ring-4 ring-toska-400/10 mb-4">
            <span className="text-2xl">🔑</span>
          </div>
          <h1 className="text-2xl font-serif font-semibold text-white">Aktivasi Aplikasi</h1>
          <p className="text-sm text-slate-300 mt-2">Pendampingan Piloting KBC</p>
          <p className="text-xs text-slate-400 mt-1">Masukkan kode aktivasi & buat akun login</p>
        </div>

        <form onSubmit={handleActivate} className="bg-white rounded-xl shadow-2xl p-6 space-y-4">
          <div>
            <label className="label text-navy-900">Nama Bapak/Ibu</label>
            <input className="input" placeholder="Contoh: Subariyanto, S.Pd, M.Pd.I"
              value={nama} onChange={(e) => { setNama(e.target.value); setError('') }} autoComplete="name" />
            <p className="text-[10px] text-slate-400 mt-1">Nama ini dipakai untuk profil pengguna.</p>
          </div>

          {SUPABASE_ENABLED && (
            <div>
              <label className="label text-navy-900">Email</label>
              <input className="input" type="email" placeholder="nama@email.com"
                value={email} onChange={(e) => { setEmail(e.target.value); setError('') }}
                autoComplete="email" />
              <p className="text-[10px] text-slate-400 mt-1">Email dipakai untuk login antar perangkat.</p>
            </div>
          )}

          <div>
            <label className="label text-navy-900">Kode Aktivasi</label>
            <input className="input text-center text-base tracking-wider font-mono uppercase"
              placeholder="KBC-XXXX-XXXXXXX"
              value={code} onChange={(e) => { setCode(e.target.value.toUpperCase()); setError('') }}
              autoComplete="off" spellCheck={false} />
            <p className="text-[10px] text-amber-600 mt-1">⚠️ Kode hanya berlaku 1 kali untuk 1 perangkat.</p>
          </div>

          {!isMaster && (
            <>
              <div>
                <label className="label text-navy-900">Peran / Jabatan</label>
                <select className="input" value={selectedRole} onChange={(e) => { setSelectedRole(e.target.value); setError('') }}>
                  <option value="pengawas">Pengawas Madrasah</option>
                  <option value="kepala_madrasah">Kepala Madrasah Piloting</option>
                </select>
              </div>

              {selectedRole === 'kepala_madrasah' && (
                <div>
                  <label className="label text-navy-900">Pilih Madrasah Piloting Bapak/Ibu</label>
                  <select className="input" value={selectedMadrasahId} onChange={(e) => { setSelectedMadrasahId(e.target.value); setError('') }}>
                    <option value="">— pilih madrasah —</option>
                    {madrasahList.map((m) => (
                      <option key={m.id} value={m.id}>{m.nama} ({m.jenjang} - {m.kecamatan})</option>
                    ))}
                  </select>
                </div>
              )}
            </>
          )}

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="label text-navy-900">Password</label>
              <input className="input" type="password" placeholder="Min 4 karakter"
                value={password} onChange={(e) => { setPassword(e.target.value); setError('') }}
                autoComplete="new-password" />
            </div>
            <div>
              <label className="label text-navy-900">Ulangi Password</label>
              <input className="input" type="password" placeholder="Konfirmasi"
                value={password2} onChange={(e) => { setPassword2(e.target.value); setError('') }}
                autoComplete="new-password" />
            </div>
          </div>

          {error && (
            <div className="bg-rose-50 border border-rose-200 text-rose-700 text-sm rounded-lg px-4 py-2">{error}</div>
          )}

          <button type="submit" className="btn-primary w-full py-3 text-base" disabled={loading}>
            {loading ? 'Memvalidasi…' : 'Aktivasi & Masuk'}
          </button>

          <p className="text-xs text-slate-400 text-center">
            Belum punya kode?{' '}
            <a href="https://wa.me/6282330647698" target="_blank" rel="noreferrer" className="text-toska-700 hover:underline">
              Hubungi Admin
            </a>
          </p>
        </form>

        <div className="text-center mt-6">
          <button type="button" onClick={goToLogin} className="text-sm text-toska-300 hover:text-white hover:underline">
            ← Sudah punya akun? Login di sini
          </button>
        </div>
        <p className="text-center text-xs text-slate-500 mt-4">Pokjawas Madrasah Kemenag Kab. Jember</p>
      </div>
    </div>
  )
}
