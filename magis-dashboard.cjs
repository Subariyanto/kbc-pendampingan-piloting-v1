const fs=require('fs');const p='src/pages/DashboardPage.jsx';let s=fs.readFileSync(p,'utf8');const old=`  return (
    <>
      <TrialBanner />`;const neu=`  const workflow = [
    { label: 'Refleksi Kondisi', path: '/pendampingan', count: scope.pendampingan.length, hint: 'Isi instrumen kondisi' },
    { label: 'Rencana Kerja', path: '/program-pendampingan', count: scope.jadwal.length, hint: 'Program dan target' },
    { label: 'Kegiatan Supervisi', path: '/jadwal', count: scope.jadwal.filter(j => j.status === 'Terjadwal').length, hint: 'Jadwal berjalan' },
    { label: 'Dokumentasi / Eviden', path: '/eviden', count: scope.eviden.length, hint: 'Bukti kegiatan' },
    { label: 'Tindak Lanjut', path: '/tindak-lanjut', count: scope.tindakLanjut.length, hint: 'Rekomendasi' },
    { label: 'Finalisasi / Laporan', path: '/laporan', count: 0, hint: 'Capaian madrasah' }
  ]

  return (
    <>
      <TrialBanner />`;
if(!s.includes(old))throw Error('return anchor missing');s=s.replace(old,neu);const anchor=`      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">`;const block=`      <div className="card-pad mb-6">
        <div className="flex items-center justify-between mb-4">
          <div><p className="font-semibold text-navy-900">Alur Supervisi KBC v1</p><p className="text-xs text-slate-500">Refleksi → Rencana → Kegiatan → Eviden → Tindak Lanjut → Laporan</p></div>
          <span className="text-xs text-toska-700">Berbasis progres</span>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-6 gap-2">{workflow.map((step, index) => <Link key={step.path} to={step.path} className="rounded-lg border border-slate-200 p-3 hover:border-toska-400 hover:bg-toska-50 transition"><div className="flex items-center gap-2"><span className="w-6 h-6 rounded-full bg-navy-900 text-white text-xs flex items-center justify-center">{index + 1}</span><span className="text-sm font-medium text-navy-900">{step.label}</span></div><p className="text-xl font-semibold text-toska-700 mt-2">{step.count}</p><p className="text-[11px] text-slate-500">{step.hint}</p></Link>)}</div>
      </div>

`;
if(!s.includes(anchor))throw Error('grid anchor missing');s=s.replace(anchor,block+anchor);fs.writeFileSync(p,s);