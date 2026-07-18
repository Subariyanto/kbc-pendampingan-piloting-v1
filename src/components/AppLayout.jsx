import { NavLink, useNavigate } from 'react-router-dom'
import { useState } from 'react'
import { useAuth } from '../context/AuthContext.jsx'
import { useData } from '../context/DataContext.jsx'
import { ROLE_LABELS, ROLES } from '../lib/constants.js'

const ALL_ROLES = ['admin','pengawas','kepala_madrasah','viewer']
const ADMIN_PENGAWAS = ['admin','pengawas']
const NAV_ITEMS = [
  { to: '/', label: 'Dasboard', icon: 'dashboard', roles: ALL_ROLES },
  { to: '/alur-pengawasan', label: 'Alur Pengawasan Digital', icon: 'flow', roles: ALL_ROLES },
  { to: '/madrasah', label: 'Madrasah Piloting KBC', icon: 'school', roles: ALL_ROLES },
  { to: '/pengawas', label: 'Pengawas Pendamping', icon: 'person', roles: ADMIN_PENGAWAS },
  { to: '/program-pendampingan', label: 'Program Pendampingan', icon: 'plan', roles: ALL_ROLES },
  { to: '/jadwal', label: 'Jadwal Pendampingan', icon: 'calendar', roles: ALL_ROLES },
  { to: '/instrumen', label: 'Instrumen Monitoring KBC', icon: 'check', roles: ALL_ROLES },
  { to: '/pendampingan', label: 'Refleksi Kondisi Madrasah', icon: 'note', roles: ALL_ROLES },
  { to: '/eviden', label: 'Dokumentasi / Eviden KBC', icon: 'file', roles: ALL_ROLES },
  { to: '/contoh-eviden', label: 'Contoh Eviden', icon: 'folder', roles: ADMIN_PENGAWAS },
  { to: '/tindak-lanjut', label: 'Rekomendasi & Tindak Lanjut', icon: 'target', roles: ALL_ROLES },
  { to: '/laporan', label: 'Capaian Madrasah Piloting', icon: 'chart', roles: ADMIN_PENGAWAS },
  { to: '/laporan-lengkap', label: 'Laporan Pendukung MAGIS', icon: 'report', roles: ALL_ROLES },
  { to: '/panduan', label: 'Panduan Penggunaan', icon: 'book', roles: ADMIN_PENGAWAS },
  { to: '/backup', label: 'Backup & Restore', icon: 'backup', roles: ADMIN_PENGAWAS },
  { to: '/pengaturan', label: 'Data Utama', icon: 'settings', roles: ADMIN_PENGAWAS },
  { to: '/kode-aktivasi', label: 'Kode Aktivasi', icon: 'key', roles: ['admin'] }
]
export default function AppLayout({ children }) {
  const { user, logout } = useAuth()
  const { state } = useData()
  const navigate = useNavigate()
  const [open, setOpen] = useState(false)

  const items = NAV_ITEMS.filter((it) => it.roles.includes(user?.role))
  const settings = state.settings

  const onLogout = () => {
    logout()
    navigate('/login', { replace: true })
  }

  return (
    <div className="min-h-screen bg-slate-50 flex">
      {/* Sidebar desktop */}
      <aside className="hidden lg:flex w-64 flex-col bg-navy-950 text-white no-print fixed left-0 top-0 bottom-0">
        <Brand settings={settings} />
        <nav className="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
          {items.map((it) => (
            <SidebarItem key={it.to} {...it} />
          ))}
          <div className="pt-3 border-t border-white/10 mt-3">
            <UserBlock user={user} onLogout={onLogout} />
          </div>
        </nav>
      </aside>

      {/* Sidebar mobile */}
      {open && (
        <div className="lg:hidden fixed inset-0 z-40 no-print">
          <div className="absolute inset-0 bg-navy-950/60" onClick={() => setOpen(false)} />
          <aside className="absolute left-0 top-0 bottom-0 w-72 bg-navy-950 text-white flex flex-col">
            <Brand settings={settings} />
            <nav className="flex-1 px-3 py-4 space-y-1">
              {items.map((it) => (
                <SidebarItem key={it.to} {...it} onClick={() => setOpen(false)} />
              ))}
              <div className="pt-3 border-t border-white/10 mt-3">
                <UserBlock user={user} onLogout={onLogout} />
              </div>
            </nav>
          </aside>
        </div>
      )}

      <div className="flex-1 flex flex-col min-w-0 lg:ml-64">
        {/* Desktop topbar */}
        <header className="hidden lg:flex sticky top-0 z-30 bg-white border-b border-slate-200 items-center justify-between px-8 py-3 no-print">
          <div className="flex items-center gap-2">
            {settings.logoDataUrl ? (
              <img src={settings.logoDataUrl} alt="logo" className="w-8 h-8 rounded" />
            ) : (
              <div className="w-8 h-8 rounded bg-navy-900 text-white flex items-center justify-center text-xs font-semibold">KBC</div>
            )}
            <div className="leading-tight">
              <p className="text-sm font-semibold text-navy-900">KBC Pendampingan Piloting</p>
              <p className="text-[10px] text-slate-500">{settings.namaInstansi}</p>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <div className="text-right text-xs text-slate-500">
              <p className="font-medium text-slate-700">{user?.nama}</p>
              <p>{ROLE_LABELS[user?.role] || user?.role}</p>
            </div>
            <button onClick={onLogout} className="p-2 rounded-lg hover:bg-slate-100 text-slate-600" title="Keluar" aria-label="Keluar"><LogoutIcon /></button>
          </div>
        </header>

        {/* Mobile topbar */}
        <header className="lg:hidden sticky top-0 z-30 bg-white border-b border-slate-200 flex items-center justify-between px-4 py-3 no-print">
          <button
            onClick={() => setOpen(true)}
            className="p-2 -ml-2 rounded-lg hover:bg-slate-100"
            aria-label="Buka menu"
          >
            <Hamburger />
          </button>
          <div className="flex items-center gap-2">
            {settings.logoDataUrl ? (
              <img src={settings.logoDataUrl} alt="logo" className="w-8 h-8 rounded" />
            ) : (
              <div className="w-8 h-8 rounded bg-navy-900 text-white flex items-center justify-center text-xs font-semibold">KBC</div>
            )}
            <div className="leading-tight">
              <p className="text-xs font-semibold text-navy-900">KBC Pendampingan</p>
              <p className="text-[10px] text-slate-500">Pokjawas Jember</p>
            </div>
          </div>
          <button onClick={onLogout} className="p-2 rounded-lg hover:bg-slate-100 text-slate-600" title="Keluar" aria-label="Keluar"><LogoutIcon /></button>
        </header>

        <main className="flex-1 px-4 lg:px-8 py-6 lg:py-8 max-w-[1400px] w-full mx-auto">
          {children}
        </main>

        <footer className="text-center text-xs text-slate-400 py-6 no-print">
          © {new Date().getFullYear()} {settings.namaInstansi} · {settings.subInstansi}
        </footer>
      </div>
    </div>
  )
}

function Brand({ settings }) {
  return (
    <div className="px-4 py-4 border-b border-white/10 text-center">
      <img src={`${import.meta.env.BASE_URL}logo-magis.png`} alt="Logo MAGIS" className="mx-auto mb-2 h-16 w-auto rounded bg-white/95 p-1" />
      <p className="text-[10px] uppercase tracking-wider text-toska-200">Selaras dengan semangat pengawasan digital</p>
      <p className="text-sm font-serif font-semibold leading-tight">Pendampingan Piloting KBC</p>
      <p className="mt-1 text-[9px] text-slate-400">Aplikasi pendukung — bukan aplikasi resmi MAGIS</p>
    </div>
  )
}

function MenuIcon({ name }) {
  const paths = { dashboard: 'M3 13h7V3H3v10Zm11 8h7V3h-7v18ZM3 21h7v-4H3v4Zm11-4h7v-4h-7v4Z', flow: 'M4 5h5v5H4V5Zm11 9h5v5h-5v-5ZM9 7h6m-3 0v7', school: 'm3 10 9-6 9 6-9 6-9-6Zm3 3v5h12v-5M12 16v5', person: 'M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8Zm-7 8a7 7 0 0 1 14 0', plan: 'M5 4h14v16H5zM8 8h8M8 12h8M8 16h5', calendar: 'M5 4h14v16H5zM8 2v4m8-4v4M5 9h14', check: 'M5 12l4 4L19 6', note: 'M5 4h14v16H5zM8 9h8M8 13h8M8 17h5', file: 'M6 3h8l4 4v14H6zM14 3v5h5', folder: 'M3 6h7l2 2h9v11H3z', target: 'M12 12m-8 0a8 8 0 1 0 16 0a8 8 0 1 0-16 0M12 12m-3 0a3 3 0 1 0 6 0', chart: 'M5 20V10m5 10V4m5 16v-7m5 7V7', report: 'M5 3h14v18H5zM8 8h8M8 12h8M8 16h5', book: 'M4 5a3 3 0 0 1 3-2h13v17H7a3 3 0 0 0-3 2z', backup: 'M12 3v12m0 0 5-5m-5 5-5-5M5 21h14', settings: 'M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8Zm0-5v3m0 12v3M3 12h3m12 0h3', key: 'M14 7a5 5 0 1 0-4 8l7 7 3-3-2-2 2-2-3-3a5 5 0 0 0-3-5Z' }
  return <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d={paths[name] || paths.note} /></svg>
}

function SidebarItem({ to, icon, label, onClick }) {
  return (
    <NavLink
      to={to}
      end={to === '/'}
      onClick={onClick}
      className={({ isActive }) =>
        `flex items-center gap-3 rounded-lg px-3 py-2 text-[11px] transition ${
          isActive
            ? 'bg-toska-500/20 text-white ring-1 ring-toska-400/40 font-medium'
            : 'text-slate-300 hover:bg-white/5 hover:text-white'
        }`
      }
    >
      <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-white/10 text-toska-200"><MenuIcon name={icon} /></span>
      <span className="line-clamp-2 leading-tight">{label}</span>
    </NavLink>
  )
}

function UserBlock({ user, onLogout }) {
  if (!user) return null
  return (
    <div className="px-4 py-4 border-t border-white/10">
      <p className="text-[11px] uppercase tracking-wider text-toska-200 mb-1">Masuk sebagai</p>
      <p className="text-sm font-semibold leading-snug">{user.nama}</p>
      <p className="text-xs text-slate-300">{ROLE_LABELS[user.role] || user.role}</p>
      <button
        onClick={onLogout}
        className="mt-3 w-full text-sm text-white/90 bg-white/10 hover:bg-white/15 rounded-lg py-1.5"
      >
        Keluar
      </button>
      <p className="text-[10px] text-slate-400 mt-3 leading-tight text-center">
        Aplikasi ini dibuat oleh:<br />
        <span className="text-slate-200">Subariyanto, S.Pd, M.Pd.I.</span>
      </p>
    </div>
  )
}

function LogoutIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M10 17l5-5-5-5M15 12H3M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4" /></svg>
}

function Hamburger() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <line x1="3" y1="6" x2="21" y2="6" />
      <line x1="3" y1="12" x2="21" y2="12" />
      <line x1="3" y1="18" x2="21" y2="18" />
    </svg>
  )
}


