import { Link } from 'react-router-dom'
import PageHeader from '../components/PageHeader.jsx'

const steps = [
  ['01','Refleksi Kondisi','Identifikasi kondisi awal, potensi, kendala, dan kebutuhan pendampingan madrasah.','/pendampingan'],
  ['02','Rencana Kerja','Susun program, tujuan, sasaran, indikator keberhasilan, waktu, dan output pendampingan.','/program-pendampingan'],
  ['03','Kegiatan Supervisi','Atur jadwal sosialisasi, coaching, observasi, monitoring, refleksi, dan evaluasi.','/jadwal'],
  ['04','Monitoring KBC','Nilai lima aspek implementasi KBC dengan instrumen dan skor capaian terukur.','/instrumen'],
  ['05','Dokumentasi Eviden','Himpun dokumen, foto, jurnal, modul, notulen, instrumen, dan bukti implementasi.','/eviden'],
  ['06','Rekomendasi & Tindak Lanjut','Catat temuan, rekomendasi, penanggung jawab, tenggat, status, dan bukti penyelesaian.','/tindak-lanjut'],
  ['07','Finalisasi & Laporan','Susun rekap, berita acara, laporan per madrasah/pengawas, lalu cetak atau ekspor.','/laporan-lengkap']
]

export default function AlurPengawasanPage() {
  return <div>
    <PageHeader title="Alur Pengawasan Digital" subtitle="Alur pendampingan KBC yang selaras dengan semangat pengawasan digital MAGIS" />
    <div className="mb-5 rounded-xl border border-blue-200 bg-blue-50 p-4 text-sm text-blue-900">
      Alur ini menjadi panduan kerja aplikasi pendukung pendampingan KBC. Aplikasi tidak menggantikan, mengambil data, atau terintegrasi langsung dengan MAGIS.
    </div>
    <div className="space-y-3">
      {steps.map(([no,title,desc,path], i) => <div key={no} className="relative rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
        <div className="flex gap-4">
          <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-navy-900 font-bold text-white">{no}</div>
          <div className="flex-1">
            <h3 className="font-bold text-slate-900">{title}</h3>
            <p className="mt-1 text-sm text-slate-600">{desc}</p>
            <Link to={path} className="mt-3 inline-block text-sm font-semibold text-blue-700 hover:underline">Buka tahap →</Link>
          </div>
        </div>
        {i < steps.length - 1 && <div className="absolute -bottom-4 left-10 z-10 text-slate-400">↓</div>}
      </div>)}
    </div>
  </div>
}
