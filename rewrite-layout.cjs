const fs=require('fs'),p='src/components/AppLayout.jsx';let s=fs.readFileSync(p,'utf8');const a=s.indexOf('const NAV_ITEMS = ['),b=s.indexOf('\n]\n',a)+3;const nav=`const NAV_ITEMS = [
  { to: '/', label: 'Dashboard Pendampingan KBC', icon: '01', roles: ['admin','pengawas','kepala_madrasah','viewer'] },
  { to: '/madrasah', label: 'Madrasah Binaan Piloting KBC', icon: '02', roles: ['admin','pengawas','viewer'] },
  { to: '/program-pendampingan', label: 'Program Pendampingan KBC', icon: '03', roles: ['admin','pengawas','viewer'] },
  { to: '/jadwal', label: 'Jadwal Pendampingan', icon: '04', roles: ['admin','pengawas','kepala_madrasah','viewer'] },
  { to: '/instrumen', label: 'Instrumen Monitoring KBC', icon: '05', roles: ['admin','pengawas','viewer'] },
  { to: '/pendampingan', label: 'Catatan Hasil Pendampingan', icon: '06', roles: ['admin','pengawas','kepala_madrasah','viewer'] },
  { to: '/eviden', label: 'Eviden Implementasi KBC', icon: '07', roles: ['admin','pengawas','kepala_madrasah','viewer'] },
  { to: '/tindak-lanjut', label: 'Rekomendasi dan Tindak Lanjut', icon: '08', roles: ['admin','pengawas','kepala_madrasah','viewer'] },
  { to: '/laporan-lengkap', label: 'Laporan Pendukung MAGIS', icon: '09', roles: ['admin','pengawas','viewer'] },
  { to: '/pengaturan', label: 'Pengaturan', icon: '10', roles: ['admin','pengawas'] }
]`;
s=s.slice(0,a)+nav+s.slice(b);s=s.replace('KBC Pendampingan Piloting','Pendampingan KBC • Pendukung MAGIS').replace('Pendampingan Piloting','Aplikasi Pendukung Pengawas');fs.writeFileSync(p,s);