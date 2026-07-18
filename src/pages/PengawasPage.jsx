import { useMemo, useState } from 'react'
import PageHeader from '../components/PageHeader.jsx'
import { ConfirmDialog } from '../components/Modal.jsx'
import EmptyState from '../components/EmptyState.jsx'
import PrintHeader from '../components/PrintHeader.jsx'
import { useData } from '../context/DataContext.jsx'
import { useToast } from '../context/ToastContext.jsx'
import { useScope } from '../lib/useScope.js'
import { downloadCSV, formatDate } from '../lib/utils.js'
import { printPrintArea } from '../lib/printHelper.js'

const EMPTY = { nama: '', nip: '', pangkat: '', jabatan: '', wilayah: '', kabupaten: '', hp: '', email: '' }

export default function PengawasPage() {
  const { state, addOrUpdate, remove } = useData()
  const toast = useToast()
  const scope = useScope()
  const [confirm, setConfirm] = useState(null)
  const [print, setPrint] = useState(false)
  const [editMode, setEditMode] = useState(false)

  // Ambil data pengawas dari state (hanya 1 pengawas per device)
  const pengawasList = scope.pengawasList
  const existing = pengawasList.length > 0 ? pengawasList[0] : null
  const jumlahDampingan = existing ? state.madrasah.filter((m) => m.pengawasId === existing.id).length : 0

  const exportCSV = () => {
    if (!existing) { toast.error('Belum ada data pengawas'); return }
    const rows = [{
      Nama: existing.nama, NIP: existing.nip, 'Pangkat/Gol': existing.pangkat, Jabatan: existing.jabatan,
      Wilayah: existing.wilayah, HP: existing.hp, Email: existing.email, 'Jumlah Dampingan': jumlahDampingan
    }]
    downloadCSV(`pengawas-pendamping-${Date.now()}.csv`, rows)
    toast.success('Data CSV diunduh')
  }

  return (
    <>
      <PageHeader
        title="Data Pengawas Pendamping"
        description="Data pengawas madrasah pendamping piloting KBC."
        icon="🧑‍🏫"
        actions={
          <>
            {existing && <button className="btn-ghost" onClick={() => setPrint(true)}>🖨 Cetak</button>}
            {existing && <button className="btn-ghost" onClick={exportCSV}>⬇ CSV</button>}
          </>
        }
      />

      {!existing ? (
        // Belum ada data → tampilkan form kosong langsung
        <PengawasFormInline
          value={EMPTY}
          onSave={(form) => {
            if (!form.nama) { toast.error('Nama pengawas wajib diisi'); return }
            addOrUpdate('pengawas', form)
            toast.success('Data pengawas disimpan')
          }}
          onCancel={null}
          isNew
        />
      ) : !editMode ? (
        // Sudah ada data → tampilkan kartu detail dengan tombol Edit & Hapus
        <div className="card-pad">
          <div className="flex items-start justify-between mb-4">
            <div className="flex items-center gap-4">
              <div className="w-16 h-16 rounded-full bg-navy-100 text-navy-800 flex items-center justify-center text-2xl font-bold">
                {existing.nama?.charAt(0) || '?'}
              </div>
              <div>
                <h3 className="text-lg font-bold text-navy-900">{existing.nama}</h3>
                <p className="text-sm text-slate-500">{existing.jabatan || 'Pengawas Madrasah'}</p>
                <p className="text-xs text-slate-400 mt-1">Wilayah: {existing.wilayah || '-'} • Dampingan: {jumlahDampingan} madrasah</p>
              </div>
            </div>
            <div className="flex gap-2">
              <button className="btn-ghost btn-sm" onClick={() => setEditMode(true)}>✎ Edit</button>
              <button className="btn-danger btn-sm" onClick={() => setConfirm(existing)}>✕ Hapus</button>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mt-4 border-t border-slate-100 pt-4">
            <DetailRow label="NIP" value={existing.nip} />
            <DetailRow label="Pangkat/Golongan" value={existing.pangkat} />
            <DetailRow label="Jabatan" value={existing.jabatan} />
            <DetailRow label="Wilayah Binaan" value={existing.wilayah} />
            <DetailRow label="Nomor HP" value={existing.hp} />
            <DetailRow label="Email" value={existing.email} />
          </div>
        </div>
      ) : (
        // Mode edit → tampilkan form dengan data existing
        <PengawasFormInline
          value={existing}
          onSave={(form) => {
            if (!form.nama) { toast.error('Nama pengawas wajib diisi'); return }
            addOrUpdate('pengawas', { ...form, id: existing.id })
            toast.success('Data pengawas diperbarui')
            setEditMode(false)
          }}
          onCancel={() => setEditMode(false)}
          isNew={false}
        />
      )}

      <ConfirmDialog
        open={!!confirm}
        onClose={() => setConfirm(null)}
        onConfirm={() => {
          remove('pengawas', confirm.id)
          toast.success('Data pengawas dihapus')
          setConfirm(null)
        }}
        title="Hapus Pengawas"
        message={`Yakin menghapus ${confirm?.nama}? Madrasah binaan akan kehilangan referensi pengawas.`}
      />

      {print && existing && (
        <PrintPreviewPengawas
          data={existing}
          jumlahDampingan={jumlahDampingan}
          settings={state.settings}
          onClose={() => setPrint(false)}
        />
      )}
    </>
  )
}

function PengawasFormInline({ value, onSave, onCancel, isNew }) {
  const [form, setForm] = useState(value)
  const upd = (k, v) => setForm((f) => ({ ...f, [k]: v }))
  const submit = (e) => { e.preventDefault(); onSave(form) }

  return (
    <form onSubmit={submit} className="card-pad">
      <h3 className="text-sm font-semibold text-navy-900 mb-4">
        {isNew ? '📝 Isi Data Pengawas' : '✎ Edit Data Pengawas'}
      </h3>
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <Field label="Nama" required>
          <input className="input" value={form.nama || ''} onChange={(e) => upd('nama', e.target.value)} required placeholder="Nama lengkap" />
        </Field>
        <Field label="NIP">
          <input className="input" value={form.nip || ''} onChange={(e) => upd('nip', e.target.value)} placeholder="NIP" />
        </Field>
        <Field label="Pangkat/Golongan">
          <input className="input" value={form.pangkat || ''} onChange={(e) => upd('pangkat', e.target.value)} placeholder="Pangkat/Golongan" />
        </Field>
        <Field label="Jabatan">
          <input className="input" value={form.jabatan || ''} onChange={(e) => upd('jabatan', e.target.value)} placeholder="Jabatan" />
        </Field>
        <Field label="Wilayah Binaan">
          <input className="input" value={form.wilayah || ''} onChange={(e) => upd('wilayah', e.target.value)} placeholder="Wilayah binaan" />
        </Field>
        <Field label="Kabupaten/Kota">
          <input className="input" value={form.kabupaten || ''} onChange={(e) => upd('kabupaten', e.target.value)} placeholder="Contoh: Jember" />
        </Field>
        <Field label="Nomor HP">
          <input className="input" value={form.hp || ''} onChange={(e) => upd('hp', e.target.value)} placeholder="Nomor HP" />
        </Field>
        <Field label="Email">
          <input className="input" type="email" value={form.email || ''} onChange={(e) => upd('email', e.target.value)} placeholder="Email" />
        </Field>
      </div>
      <div className="flex gap-2 mt-4">
        <button type="submit" className="btn-primary">💾 Simpan</button>
        {onCancel && <button type="button" className="btn-ghost" onClick={onCancel}>Batal</button>}
      </div>
    </form>
  )
}

function DetailRow({ label, value }) {
  return (
    <div>
      <p className="text-xs text-slate-400">{label}</p>
      <p className="text-sm font-medium text-slate-700">{value || '-'}</p>
    </div>
  )
}

function Field({ label, required, children }) {
  return (
    <div>
      <label className="label">{label}{required && <span className="text-rose-500"> *</span>}</label>
      {children}
    </div>
  )
}

function PrintPreviewPengawas({ data, jumlahDampingan, settings, onClose }) {
  return (
    <div className="fixed inset-0 z-50 bg-black/40 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl shadow-2xl max-w-3xl w-full max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between px-6 py-4 border-b">
          <h3 className="font-semibold text-navy-900">Pratinjau Cetak — Pengawas</h3>
          <div className="flex gap-2">
            <button className="btn-ghost btn-sm" onClick={onClose}>Tutup</button>
            <button className="btn-primary btn-sm" onClick={() => printPrintArea()}>🖨 Cetak</button>
          </div>
        </div>
        <div className="print-area bg-white p-6">
          <PrintHeader settings={settings} judul="DATA PENGAWAS PENDAMPING PILOTING KBC" />
          <table className="table-clean">
            <tbody>
              <tr><th className="text-left w-1/3">Nama</th><td>{data.nama}</td></tr>
              <tr><th className="text-left">NIP</th><td>{data.nip}</td></tr>
              <tr><th className="text-left">Pangkat/Golongan</th><td>{data.pangkat}</td></tr>
              <tr><th className="text-left">Jabatan</th><td>{data.jabatan}</td></tr>
              <tr><th className="text-left">Wilayah Binaan</th><td>{data.wilayah}</td></tr>
              <tr><th className="text-left">Nomor HP</th><td>{data.hp}</td></tr>
              <tr><th className="text-left">Email</th><td>{data.email}</td></tr>
              <tr><th className="text-left">Jumlah Dampingan</th><td>{jumlahDampingan} madrasah</td></tr>
            </tbody>
          </table>
          <p className="mt-6 text-xs text-slate-500">Dicetak {formatDate(new Date())}.</p>
        </div>
      </div>
    </div>
  )
}
