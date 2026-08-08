-- =============================================================================
-- KBC Pendampingan Piloting - Supabase Schema
-- Project: kbc-pendampingan-piloting
-- Owner:   Pokjawas Madrasah Kemenag Kab. Jember
-- Version: 1.0 (19 Jun 2026)
-- =============================================================================
-- Cara pakai:
-- 1. Buka Supabase project Bapak.
-- 2. Buka menu SQL Editor → New query.
-- 3. Copy-paste seluruh isi file ini → klik Run.
-- 4. Hasil: 10 tabel + RLS policies + indexes + 1 view + helper function.
-- =============================================================================

-- 0. Pastikan ekstensi yang dibutuhkan aktif
create extension if not exists "uuid-ossp";

-- 1. Tabel profile (extend auth.users)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  nama text not null,
  role text not null check (role in ('admin','pengawas','kepala','viewer')),
  pengawas_id uuid,           -- ref pengawas.id (kalau role pengawas)
  madrasah_id uuid,           -- ref madrasah.id (kalau role kepala)
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 2. Settings (singleton, id = 1)
create table if not exists public.settings (
  id int primary key default 1,
  nama_instansi text not null default 'Kelompok Kerja Pengawas Madrasah',
  sub_instansi text not null default 'Kementerian Agama Kabupaten Jember',
  tahun_pelajaran text not null default '2025/2026',
  ketua_pokjawas text not null default 'Subariyanto, S.Pd, M.Pd.I.',
  nip_ketua text default '197002122005011004',
  logo_url text,
  bobot jsonb not null default '{"perencanaan":20,"pelaksanaan":20,"budaya":20,"panca":20,"evaluasi":20}'::jsonb,
  updated_at timestamptz default now(),
  constraint settings_singleton check (id = 1)
);

-- 3. Pengawas
create table if not exists public.pengawas (
  id uuid primary key default uuid_generate_v4(),
  nama text not null,
  nip text,
  pangkat text,
  jabatan text,
  wilayah text,
  hp text,
  email text,
  user_id uuid references auth.users(id) on delete set null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
create index if not exists idx_pengawas_user on public.pengawas(user_id);

-- 4. Madrasah
create table if not exists public.madrasah (
  id uuid primary key default uuid_generate_v4(),
  nama text not null,
  nsm text,
  npsn text,
  jenjang text check (jenjang in ('RA','MI','MTs','MA','MAK')),
  status_ns text check (status_ns in ('Negeri','Swasta')),
  kecamatan text,
  kepala text,
  hp text,
  email text,
  pengawas_id uuid references public.pengawas(id) on delete set null,
  tahun_pelajaran text,
  status_piloting text default 'Aktif' check (status_piloting in ('Aktif','Cadangan','Selesai')),
  catatan text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
create index if not exists idx_madrasah_pengawas on public.madrasah(pengawas_id);
create index if not exists idx_madrasah_jenjang on public.madrasah(jenjang);
create index if not exists idx_madrasah_kecamatan on public.madrasah(kecamatan);

-- 5. Instrumen (aspek)
create table if not exists public.instrumen_aspek (
  id uuid primary key default uuid_generate_v4(),
  kode text not null,
  nama text not null,
  urutan int default 0,
  created_at timestamptz default now()
);
create unique index if not exists idx_aspek_kode on public.instrumen_aspek(kode);

-- 6. Instrumen (indikator)
create table if not exists public.instrumen_indikator (
  id uuid primary key default uuid_generate_v4(),
  aspek_id uuid not null references public.instrumen_aspek(id) on delete cascade,
  nomor int not null,
  teks text not null,
  created_at timestamptz default now()
);
create index if not exists idx_indikator_aspek on public.instrumen_indikator(aspek_id);

-- 7. Jadwal pendampingan
create table if not exists public.jadwal (
  id uuid primary key default uuid_generate_v4(),
  tanggal date not null,
  madrasah_id uuid not null references public.madrasah(id) on delete cascade,
  pengawas_id uuid references public.pengawas(id) on delete set null,
  bentuk text check (bentuk in ('Sosialisasi','Bimtek','Observasi','Coaching','Refleksi','Monitoring','Evaluasi')),
  materi text,
  tempat text,
  status text default 'Terjadwal' check (status in ('Terjadwal','Terlaksana','Ditunda','Selesai')),
  catatan text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
create index if not exists idx_jadwal_tanggal on public.jadwal(tanggal);
create index if not exists idx_jadwal_madrasah on public.jadwal(madrasah_id);

-- 8. Hasil pendampingan
create table if not exists public.pendampingan (
  id uuid primary key default uuid_generate_v4(),
  tanggal date not null,
  madrasah_id uuid not null references public.madrasah(id) on delete cascade,
  pengawas_id uuid references public.pengawas(id) on delete set null,
  kegiatan text,
  temuan_positif text,
  kendala text,
  observasi text,
  rekomendasi text,
  rencana_tindak_lanjut text,
  batas_tl date,
  status_tl text default 'Belum Dikerjakan' check (status_tl in ('Belum Dikerjakan','Proses','Selesai','Perlu Pendampingan Ulang')),
  bukti_link text,
  skor jsonb default '{}'::jsonb,    -- { "<indikator_id>": 1..4, ... }
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
create index if not exists idx_pendampingan_madrasah on public.pendampingan(madrasah_id);
create index if not exists idx_pendampingan_tanggal on public.pendampingan(tanggal);

-- 9. Eviden
create table if not exists public.eviden (
  id uuid primary key default uuid_generate_v4(),
  madrasah_id uuid not null references public.madrasah(id) on delete cascade,
  jenis text,
  judul text not null,
  deskripsi text,
  tanggal date,
  link text,
  storage_path text,                  -- path di Supabase Storage (opsional)
  uploaded_by uuid references auth.users(id) on delete set null,
  created_at timestamptz default now()
);
create index if not exists idx_eviden_madrasah on public.eviden(madrasah_id);
create index if not exists idx_eviden_jenis on public.eviden(jenis);

-- 10. Tindak lanjut
create table if not exists public.tindak_lanjut (
  id uuid primary key default uuid_generate_v4(),
  madrasah_id uuid not null references public.madrasah(id) on delete cascade,
  temuan text not null,
  rekomendasi text,
  pj text,
  batas date,
  status text default 'Belum Dikerjakan' check (status in ('Belum Dikerjakan','Proses','Selesai','Perlu Pendampingan Ulang')),
  catatan text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
create index if not exists idx_tl_madrasah on public.tindak_lanjut(madrasah_id);
create index if not exists idx_tl_status on public.tindak_lanjut(status);

-- =============================================================================
-- Helper function: cek role user yang sedang login
-- =============================================================================
create or replace function public.current_role()
returns text
language sql stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid()
$$;

create or replace function public.current_pengawas_id()
returns uuid
language sql stable
security definer
set search_path = public
as $$
  select pengawas_id from public.profiles where id = auth.uid()
$$;

create or replace function public.current_madrasah_id()
returns uuid
language sql stable
security definer
set search_path = public
as $$
  select madrasah_id from public.profiles where id = auth.uid()
$$;

-- =============================================================================
-- Row Level Security (RLS)
-- =============================================================================
-- Pola: semua user terautentikasi bisa SELECT (filter by scope kalau kepala/pengawas)
--       INSERT/UPDATE/DELETE: admin = full, pengawas = data binaannya, kepala = madrasahnya, viewer = read-only

-- profiles: user lihat profil sendiri, admin lihat semua
alter table public.profiles enable row level security;
drop policy if exists "profiles_self" on public.profiles;
create policy "profiles_self" on public.profiles
  for select using (auth.uid() = id or public.current_role() = 'admin');
drop policy if exists "profiles_admin_all" on public.profiles;
create policy "profiles_admin_all" on public.profiles
  for all using (public.current_role() = 'admin');

-- settings: semua bisa baca, hanya admin tulis
alter table public.settings enable row level security;
drop policy if exists "settings_read_all" on public.settings;
create policy "settings_read_all" on public.settings for select using (auth.role() = 'authenticated');
drop policy if exists "settings_admin_write" on public.settings;
create policy "settings_admin_write" on public.settings for all using (public.current_role() = 'admin');

-- pengawas: read all (auth), admin write
alter table public.pengawas enable row level security;
drop policy if exists "pengawas_read" on public.pengawas;
create policy "pengawas_read" on public.pengawas for select using (auth.role() = 'authenticated');
drop policy if exists "pengawas_admin_write" on public.pengawas;
create policy "pengawas_admin_write" on public.pengawas for all using (public.current_role() = 'admin');

-- madrasah: scoped read (admin/viewer all, pengawas binaan, kepala sendiri); admin write
alter table public.madrasah enable row level security;
drop policy if exists "madrasah_read" on public.madrasah;
create policy "madrasah_read" on public.madrasah for select using (
  public.current_role() in ('admin','viewer','pengawas','kepala') and (
    public.current_role() in ('admin','viewer')
    or (public.current_role() = 'pengawas' and pengawas_id = public.current_pengawas_id())
    or (public.current_role() = 'kepala' and id = public.current_madrasah_id())
  )
);
drop policy if exists "madrasah_admin_write" on public.madrasah;
create policy "madrasah_admin_write" on public.madrasah for all using (public.current_role() = 'admin');

-- instrumen aspek/indikator: read all, admin write
alter table public.instrumen_aspek enable row level security;
alter table public.instrumen_indikator enable row level security;
drop policy if exists "aspek_read" on public.instrumen_aspek;
create policy "aspek_read" on public.instrumen_aspek for select using (auth.role() = 'authenticated');
drop policy if exists "aspek_admin_write" on public.instrumen_aspek;
create policy "aspek_admin_write" on public.instrumen_aspek for all using (public.current_role() = 'admin');
drop policy if exists "ind_read" on public.instrumen_indikator;
create policy "ind_read" on public.instrumen_indikator for select using (auth.role() = 'authenticated');
drop policy if exists "ind_admin_write" on public.instrumen_indikator;
create policy "ind_admin_write" on public.instrumen_indikator for all using (public.current_role() = 'admin');

-- jadwal: scoped read; admin & pengawas (binaan) write
alter table public.jadwal enable row level security;
drop policy if exists "jadwal_read" on public.jadwal;
create policy "jadwal_read" on public.jadwal for select using (
  public.current_role() in ('admin','viewer')
  or (public.current_role() = 'pengawas' and madrasah_id in (select id from public.madrasah where pengawas_id = public.current_pengawas_id()))
  or (public.current_role() = 'kepala' and madrasah_id = public.current_madrasah_id())
);
drop policy if exists "jadwal_write" on public.jadwal;
create policy "jadwal_write" on public.jadwal for all using (
  public.current_role() = 'admin'
  or (public.current_role() = 'pengawas' and madrasah_id in (select id from public.madrasah where pengawas_id = public.current_pengawas_id()))
);

-- pendampingan
alter table public.pendampingan enable row level security;
drop policy if exists "pen_read" on public.pendampingan;
create policy "pen_read" on public.pendampingan for select using (
  public.current_role() in ('admin','viewer')
  or (public.current_role() = 'pengawas' and madrasah_id in (select id from public.madrasah where pengawas_id = public.current_pengawas_id()))
  or (public.current_role() = 'kepala' and madrasah_id = public.current_madrasah_id())
);
drop policy if exists "pen_write" on public.pendampingan;
create policy "pen_write" on public.pendampingan for all using (
  public.current_role() = 'admin'
  or (public.current_role() = 'pengawas' and madrasah_id in (select id from public.madrasah where pengawas_id = public.current_pengawas_id()))
);

-- eviden: kepala madrasah boleh upload eviden untuk madrasahnya
alter table public.eviden enable row level security;
drop policy if exists "ev_read" on public.eviden;
create policy "ev_read" on public.eviden for select using (
  public.current_role() in ('admin','viewer')
  or (public.current_role() = 'pengawas' and madrasah_id in (select id from public.madrasah where pengawas_id = public.current_pengawas_id()))
  or (public.current_role() = 'kepala' and madrasah_id = public.current_madrasah_id())
);
drop policy if exists "ev_write" on public.eviden;
create policy "ev_write" on public.eviden for all using (
  public.current_role() = 'admin'
  or (public.current_role() = 'pengawas' and madrasah_id in (select id from public.madrasah where pengawas_id = public.current_pengawas_id()))
  or (public.current_role() = 'kepala' and madrasah_id = public.current_madrasah_id())
);

-- tindak_lanjut
alter table public.tindak_lanjut enable row level security;
drop policy if exists "tl_read" on public.tindak_lanjut;
create policy "tl_read" on public.tindak_lanjut for select using (
  public.current_role() in ('admin','viewer')
  or (public.current_role() = 'pengawas' and madrasah_id in (select id from public.madrasah where pengawas_id = public.current_pengawas_id()))
  or (public.current_role() = 'kepala' and madrasah_id = public.current_madrasah_id())
);
drop policy if exists "tl_write" on public.tindak_lanjut;
create policy "tl_write" on public.tindak_lanjut for all using (
  public.current_role() = 'admin'
  or (public.current_role() = 'pengawas' and madrasah_id in (select id from public.madrasah where pengawas_id = public.current_pengawas_id()))
);

-- =============================================================================
-- Trigger: auto bikin profile saat user signup (default role = viewer)
-- Admin akan rotate role lewat panel "Pengaturan Akun" (TBD)
-- =============================================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, nama, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'nama', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'role', 'viewer')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- =============================================================================
-- Seed: default settings + default instrumen
-- =============================================================================
insert into public.settings (id) values (1) on conflict (id) do nothing;

-- Aspek default (kalau belum ada)
insert into public.instrumen_aspek (kode, nama, urutan)
select kode, nama, urutan from (values
  ('A', 'Perencanaan Implementasi KBC', 1),
  ('B', 'Pelaksanaan Pembelajaran Berbasis Cinta', 2),
  ('C', 'Budaya Madrasah Berbasis Cinta', 3),
  ('D', 'Panca Cinta KBC', 4),
  ('E', 'Evaluasi dan Tindak Lanjut', 5)
) as v(kode, nama, urutan)
on conflict (kode) do nothing;

-- Indikator default per aspek (idempotent: hanya kalau aspek belum punya indikator)
do $$
declare
  r record;
  indikator_per_aspek jsonb := '{
    "A": [
      "Madrasah memiliki dokumen rencana implementasi KBC.",
      "Tim pelaksana KBC telah dibentuk.",
      "Program KBC terintegrasi dalam kurikulum madrasah.",
      "Nilai KBC masuk dalam perencanaan pembelajaran.",
      "Madrasah memiliki jadwal kegiatan pembiasaan berbasis cinta."
    ],
    "B": [
      "Guru membangun suasana belajar aman, nyaman, dan menyenangkan.",
      "Guru menanamkan nilai kasih sayang, empati, toleransi, dan kepedulian.",
      "Pembelajaran menghargai perbedaan peserta didik.",
      "Guru memberi teladan komunikasi santun.",
      "Peserta didik aktif, dihargai, dan tidak mengalami kekerasan verbal/fisik."
    ],
    "C": [
      "Warga madrasah membiasakan salam, senyum, sapa, sopan, dan santun.",
      "Madrasah membangun budaya anti-bullying.",
      "Madrasah membiasakan kepedulian sosial.",
      "Madrasah membangun hubungan harmonis guru, siswa, orang tua, dan masyarakat.",
      "Madrasah menerapkan pembiasaan cinta tanah air dan cinta lingkungan."
    ],
    "D": [
      "Cinta kepada Allah dan Rasulullah.",
      "Cinta kepada ilmu.",
      "Cinta kepada diri sendiri dan sesama.",
      "Cinta kepada lingkungan.",
      "Cinta kepada tanah air."
    ],
    "E": [
      "Madrasah melakukan refleksi pelaksanaan KBC.",
      "Guru menyusun catatan perkembangan karakter peserta didik.",
      "Kepala madrasah melakukan supervisi implementasi KBC.",
      "Madrasah menyusun rencana tindak lanjut.",
      "Ada bukti/eviden kegiatan KBC."
    ]
  }'::jsonb;
  i int;
  arr jsonb;
begin
  for r in select id, kode from public.instrumen_aspek loop
    if not exists (select 1 from public.instrumen_indikator where aspek_id = r.id) then
      arr := indikator_per_aspek -> r.kode;
      if arr is not null then
        for i in 0..(jsonb_array_length(arr) - 1) loop
          insert into public.instrumen_indikator (aspek_id, nomor, teks)
          values (r.id, i + 1, arr->>i);
        end loop;
      end if;
    end if;
  end loop;
end;
$$;

-- =============================================================================
-- Selesai. Cek hasil:
--   select count(*) from public.instrumen_aspek;       -- 5
--   select count(*) from public.instrumen_indikator;   -- 25
--   select * from public.settings;
-- =============================================================================
-- =============================================================================
-- KBC Migration 001: FIX RLS - Inline subquery + WITH CHECK
-- =============================================================================
-- Issue diagnosis:
-- 1) `current_role` adalah SQL standard function — konflik penamaan dengan
--    helper kita walau sudah pakai prefix public.
-- 2) Untuk policy `for all`, walau Postgres bilang WITH CHECK default = USING,
--    PostgREST kadang tetap nolak INSERT kalau WITH CHECK tidak eksplisit.
--
-- Fix: rewrite semua policy:
--    - Drop helper functions (current_role, current_pengawas_id, current_madrasah_id)
--    - Pakai inline subquery (select role from profiles where id = auth.uid())
--    - Tambahkan WITH CHECK eksplisit untuk semua INSERT/UPDATE/ALL policy
-- =============================================================================

-- 1. Drop semua policy lama DAN policy baru (idempotent — boleh dijalankan berulang)
drop policy if exists "profiles_self" on public.profiles;
drop policy if exists "profiles_self_read" on public.profiles;
drop policy if exists "profiles_admin_all" on public.profiles;
drop policy if exists "profiles_admin_write" on public.profiles;
drop policy if exists "settings_read_all" on public.settings;
drop policy if exists "settings_read" on public.settings;
drop policy if exists "settings_admin_write" on public.settings;
drop policy if exists "pengawas_read" on public.pengawas;
drop policy if exists "pengawas_admin_write" on public.pengawas;
drop policy if exists "madrasah_read" on public.madrasah;
drop policy if exists "madrasah_admin_write" on public.madrasah;
drop policy if exists "aspek_read" on public.instrumen_aspek;
drop policy if exists "aspek_admin_write" on public.instrumen_aspek;
drop policy if exists "ind_read" on public.instrumen_indikator;
drop policy if exists "ind_admin_write" on public.instrumen_indikator;
drop policy if exists "jadwal_read" on public.jadwal;
drop policy if exists "jadwal_write" on public.jadwal;
drop policy if exists "pen_read" on public.pendampingan;
drop policy if exists "pen_write" on public.pendampingan;
drop policy if exists "ev_read" on public.eviden;
drop policy if exists "ev_write" on public.eviden;
drop policy if exists "tl_read" on public.tindak_lanjut;
drop policy if exists "tl_write" on public.tindak_lanjut;

-- 2. Drop helper function lama (boleh gagal kalau memang tidak ada)
drop function if exists public.current_role();
drop function if exists public.current_pengawas_id();
drop function if exists public.current_madrasah_id();

-- 3. PROFILES — user lihat profil sendiri, admin lihat semua
create policy "profiles_self_read" on public.profiles
  for select to authenticated
  using (
    auth.uid() = id
    or exists (select 1 from public.profiles p2 where p2.id = auth.uid() and p2.role = 'admin')
  );
create policy "profiles_admin_write" on public.profiles
  for all to authenticated
  using (exists (select 1 from public.profiles p2 where p2.id = auth.uid() and p2.role = 'admin'))
  with check (exists (select 1 from public.profiles p2 where p2.id = auth.uid() and p2.role = 'admin'));

-- 4. SETTINGS — read all authed, admin write
create policy "settings_read" on public.settings
  for select to authenticated using (true);
create policy "settings_admin_write" on public.settings
  for all to authenticated
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'))
  with check (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

-- 5. PENGAWAS
create policy "pengawas_read" on public.pengawas
  for select to authenticated using (true);
create policy "pengawas_admin_write" on public.pengawas
  for all to authenticated
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'))
  with check (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

-- 6. MADRASAH
create policy "madrasah_read" on public.madrasah
  for select to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and (
          p.role in ('admin','viewer')
          or (p.role = 'pengawas' and madrasah.pengawas_id = p.pengawas_id)
          or (p.role = 'kepala' and madrasah.id = p.madrasah_id)
        )
    )
  );
create policy "madrasah_admin_write" on public.madrasah
  for all to authenticated
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'))
  with check (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

-- 7. INSTRUMEN
create policy "aspek_read" on public.instrumen_aspek
  for select to authenticated using (true);
create policy "aspek_admin_write" on public.instrumen_aspek
  for all to authenticated
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'))
  with check (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));
create policy "ind_read" on public.instrumen_indikator
  for select to authenticated using (true);
create policy "ind_admin_write" on public.instrumen_indikator
  for all to authenticated
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'))
  with check (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

-- 8. JADWAL
create policy "jadwal_read" on public.jadwal
  for select to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and (
          p.role in ('admin','viewer')
          or (p.role = 'pengawas' and jadwal.madrasah_id in (select m.id from public.madrasah m where m.pengawas_id = p.pengawas_id))
          or (p.role = 'kepala' and jadwal.madrasah_id = p.madrasah_id)
        )
    )
  );
create policy "jadwal_write" on public.jadwal
  for all to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and (
          p.role = 'admin'
          or (p.role = 'pengawas' and jadwal.madrasah_id in (select m.id from public.madrasah m where m.pengawas_id = p.pengawas_id))
        )
    )
  )
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and (
          p.role = 'admin'
          or (p.role = 'pengawas' and jadwal.madrasah_id in (select m.id from public.madrasah m where m.pengawas_id = p.pengawas_id))
        )
    )
  );

-- 9. PENDAMPINGAN
create policy "pen_read" on public.pendampingan
  for select to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and (
          p.role in ('admin','viewer')
          or (p.role = 'pengawas' and pendampingan.madrasah_id in (select m.id from public.madrasah m where m.pengawas_id = p.pengawas_id))
          or (p.role = 'kepala' and pendampingan.madrasah_id = p.madrasah_id)
        )
    )
  );
create policy "pen_write" on public.pendampingan
  for all to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and (
          p.role = 'admin'
          or (p.role = 'pengawas' and pendampingan.madrasah_id in (select m.id from public.madrasah m where m.pengawas_id = p.pengawas_id))
        )
    )
  )
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and (
          p.role = 'admin'
          or (p.role = 'pengawas' and pendampingan.madrasah_id in (select m.id from public.madrasah m where m.pengawas_id = p.pengawas_id))
        )
    )
  );

-- 10. EVIDEN
create policy "ev_read" on public.eviden
  for select to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and (
          p.role in ('admin','viewer')
          or (p.role = 'pengawas' and eviden.madrasah_id in (select m.id from public.madrasah m where m.pengawas_id = p.pengawas_id))
          or (p.role = 'kepala' and eviden.madrasah_id = p.madrasah_id)
        )
    )
  );
create policy "ev_write" on public.eviden
  for all to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and (
          p.role = 'admin'
          or (p.role = 'pengawas' and eviden.madrasah_id in (select m.id from public.madrasah m where m.pengawas_id = p.pengawas_id))
          or (p.role = 'kepala' and eviden.madrasah_id = p.madrasah_id)
        )
    )
  )
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and (
          p.role = 'admin'
          or (p.role = 'pengawas' and eviden.madrasah_id in (select m.id from public.madrasah m where m.pengawas_id = p.pengawas_id))
          or (p.role = 'kepala' and eviden.madrasah_id = p.madrasah_id)
        )
    )
  );

-- 11. TINDAK LANJUT
create policy "tl_read" on public.tindak_lanjut
  for select to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and (
          p.role in ('admin','viewer')
          or (p.role = 'pengawas' and tindak_lanjut.madrasah_id in (select m.id from public.madrasah m where m.pengawas_id = p.pengawas_id))
          or (p.role = 'kepala' and tindak_lanjut.madrasah_id = p.madrasah_id)
        )
    )
  );
create policy "tl_write" on public.tindak_lanjut
  for all to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and (
          p.role = 'admin'
          or (p.role = 'pengawas' and tindak_lanjut.madrasah_id in (select m.id from public.madrasah m where m.pengawas_id = p.pengawas_id))
        )
    )
  )
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and (
          p.role = 'admin'
          or (p.role = 'pengawas' and tindak_lanjut.madrasah_id in (select m.id from public.madrasah m where m.pengawas_id = p.pengawas_id))
        )
    )
  );

-- 12. Reload schema cache
notify pgrst, 'reload schema';

-- =============================================================================
-- Test setelah migration:
--   select role from public.profiles where id = auth.uid();    -- should return 'admin'
--   insert into public.madrasah(nama,jenjang,status_ns) values ('Migration Test','MI','Negeri') returning id;
-- =============================================================================
-- =============================================================================
-- KBC Migration 002: User management RPC for admin
-- =============================================================================
-- Tujuan:
-- 1. View `admin_users_list` — admin lihat semua user + email + role + nama
-- 2. RPC `admin_update_profile` — admin update role/nama/pengawas_id/madrasah_id
-- 3. RPC `admin_delete_user` — admin hapus user (auth.users + profiles)
-- 4. Update trigger handle_new_user — baca metadata role/nama saat signup
-- =============================================================================

-- 1. Update handle_new_user trigger biar baca metadata
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  meta jsonb;
  meta_role text;
  meta_nama text;
  meta_pengawas uuid;
  meta_madrasah uuid;
begin
  meta := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  meta_role := nullif(meta->>'role', '');
  meta_nama := nullif(meta->>'nama', '');
  -- pengawas_id / madrasah_id boleh null/uuid
  begin meta_pengawas := nullif(meta->>'pengawas_id','')::uuid; exception when others then meta_pengawas := null; end;
  begin meta_madrasah := nullif(meta->>'madrasah_id','')::uuid; exception when others then meta_madrasah := null; end;

  insert into public.profiles (id, nama, role, pengawas_id, madrasah_id)
  values (
    new.id,
    coalesce(meta_nama, new.email),
    coalesce(meta_role, 'viewer'),
    meta_pengawas,
    meta_madrasah
  )
  on conflict (id) do nothing;
  return new;
end $$;

-- Pastikan trigger terpasang
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 2. View untuk list user (security definer wrapper)
create or replace function public.admin_users_list()
returns table (
  id uuid,
  email text,
  nama text,
  role text,
  pengawas_id uuid,
  madrasah_id uuid,
  created_at timestamptz,
  last_sign_in_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    p.id,
    u.email::text,
    p.nama,
    p.role,
    p.pengawas_id,
    p.madrasah_id,
    u.created_at,
    u.last_sign_in_at
  from public.profiles p
  left join auth.users u on u.id = p.id
  where public.is_admin()
  order by u.created_at desc nulls last
$$;

grant execute on function public.admin_users_list() to authenticated;

-- 3. RPC update profile (admin only)
create or replace function public.admin_update_profile(
  target_id uuid,
  new_nama text,
  new_role text,
  new_pengawas_id uuid,
  new_madrasah_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Forbidden: hanya admin yang bisa update profile';
  end if;
  if new_role not in ('admin','pengawas','kepala','viewer') then
    raise exception 'Role tidak valid: %', new_role;
  end if;
  update public.profiles
  set nama = coalesce(new_nama, nama),
      role = new_role,
      pengawas_id = new_pengawas_id,
      madrasah_id = new_madrasah_id
  where id = target_id;
end $$;

grant execute on function public.admin_update_profile(uuid, text, text, uuid, uuid) to authenticated;

-- 4. RPC delete user (admin only) — hapus dari auth.users akan cascade ke profiles
create or replace function public.admin_delete_user(target_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Forbidden: hanya admin yang bisa hapus user';
  end if;
  if target_id = auth.uid() then
    raise exception 'Tidak bisa menghapus akun sendiri';
  end if;
  delete from public.profiles where id = target_id;
  delete from auth.users where id = target_id;
end $$;

grant execute on function public.admin_delete_user(uuid) to authenticated;

-- 5. RPC reset password (admin only) — kirim email reset
-- (tidak bisa dari SQL tanpa service_role, jadi user pakai fitur "Forgot Password" sendiri,
--  atau admin pakai dashboard Supabase. Disabled untuk sekarang.)

notify pgrst, 'reload schema';
-- =============================================================================
-- KBC Migration 003: Kode Aktivasi untuk Registrasi User
-- =============================================================================
-- Tujuan:
-- 1. Tabel `activation_codes` — kode aktivasi yang di-assign ke user baru
-- 2. Trigger `handle_new_user` update — auto-mark kode sebagai used
-- 3. RLS — anon bisa query kode (validasi), admin bisa manage
-- 4. Seed default codes
-- =============================================================================

-- 1. Tabel kode aktivasi
create table if not exists public.activation_codes (
  id uuid primary key default uuid_generate_v4(),
  code text unique not null,
  role text not null check (role in ('admin','pengawas','kepala','viewer')),
  nama text not null,
  pengawas_id uuid references public.pengawas(id) on delete set null,
  madrasah_id uuid references public.madrasah(id) on delete set null,
  used boolean default false,
  used_by uuid references auth.users(id) on delete set null,
  used_at timestamptz,
  created_at timestamptz default now(),
  note text
);

-- 2. Update handle_new_user: baca activation_code dari metadata + mark as used
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  meta jsonb;
  meta_role text;
  meta_nama text;
  meta_pengawas uuid;
  meta_madrasah uuid;
  meta_activation text;
begin
  meta := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  meta_role := nullif(meta->>'role', '');
  meta_nama := nullif(meta->>'nama', '');
  meta_activation := nullif(meta->>'activation_code', '');
  begin meta_pengawas := nullif(meta->>'pengawas_id','')::uuid; exception when others then meta_pengawas := null; end;
  begin meta_madrasah := nullif(meta->>'madrasah_id','')::uuid; exception when others then meta_madrasah := null; end;

  insert into public.profiles (id, nama, role, pengawas_id, madrasah_id)
  values (
    new.id,
    coalesce(meta_nama, new.email),
    coalesce(meta_role, 'viewer'),
    meta_pengawas,
    meta_madrasah
  )
  on conflict (id) do nothing;

  -- Mark activation code as used
  if meta_activation is not null then
    update public.activation_codes
    set used = true, used_by = new.id, used_at = now()
    where upper(code) = upper(meta_activation) and used = false;
  end if;

  return new;
end;
$$;

-- Re-attach trigger
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 3. RLS untuk activation_codes
alter table public.activation_codes enable row level security;

drop policy if exists "codes_select_public" on public.activation_codes;
create policy "codes_select_public" on public.activation_codes
  for select using (true);

drop policy if exists "codes_admin_manage" on public.activation_codes;
create policy "codes_admin_manage" on public.activation_codes
  for all using (
    auth.role() = 'authenticated' 
    and exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- 4. Seed default codes (idempotent)
insert into public.activation_codes (code, role, nama, note)
select code, role, nama, note from (values
  ('KBC-POKJAWAS-JEMBER-2026', 'admin', 'Admin Utama', 'Master admin code — jangan dishare'),
  ('KBC-DEMO-ADMIN', 'admin', 'Admin Demo', 'Demo admin'),
  ('KBC-DEMO-PENGAWAS', 'pengawas', 'Pengawas Demo', 'Demo pengawas'),
  ('KBC-DEMO-KEPALA', 'kepala', 'Kepala Madrasah Demo', 'Demo kepala'),
  ('KBC-DEMO-VIEWER', 'viewer', 'Viewer Demo', 'Demo viewer')
) as v(code, role, nama, note)
where not exists (select 1 from public.activation_codes where upper(code) = upper(v.code));

-- 5. Grant execute on is_admin (dari migration-001) untuk authenticated
grant execute on function public.is_admin() to authenticated;

-- 6. Notify PostgREST untuk reload schema
notify pgrst, 'reload schema';-- =============================================================================
-- KBC Migration 004: Tier & Expired di activation_codes (opsi B)
-- =============================================================================
-- Tujuan:
-- 1. Pastikan kolom dari migration-003 ada (idempotent)
-- 2. Tambah kolom `tier` (pro|demo) dan `validity_days` (int, masa berlaku setelah aktivasi)
--    - tier=pro, validity_days=0  -> akses lifetime
--    - tier=demo, validity_days=N -> trial N hari (default 7)
-- 3. Reload schema cache PostgREST
-- =============================================================================

-- 1. Pastikan kolom dari migration-003 ada (idempotent fix kalau migration-003
--    di-skip atau tabel sudah dibuat duluan tanpa kolom-kolom ini).
alter table public.activation_codes
  add column if not exists pengawas_id uuid references public.pengawas(id) on delete set null;
alter table public.activation_codes
  add column if not exists madrasah_id uuid references public.madrasah(id) on delete set null;
alter table public.activation_codes
  add column if not exists used boolean default false;
alter table public.activation_codes
  add column if not exists used_by uuid references auth.users(id) on delete set null;
alter table public.activation_codes
  add column if not exists used_at timestamptz;
alter table public.activation_codes
  add column if not exists note text;

-- 2. Tier & masa berlaku (opsi B)
alter table public.activation_codes
  add column if not exists tier text not null default 'pro' check (tier in ('pro','demo'));
alter table public.activation_codes
  add column if not exists validity_days integer not null default 0;
-- 0 = lifetime (untuk pro). >0 = trial N hari (untuk demo).

-- 3. Reload schema cache PostgREST (kadang perlu beberapa detik)
select pg_notify('pgrst', 'reload schema');
notify pgrst, 'reload schema';
-- =============================================================================
-- KBC Migration 005: Pembelian (info penjualan) di settings - public read
-- =============================================================================
-- Tujuan:
-- 1. Tambah kolom `pembelian` jsonb di tabel settings
-- 2. Public read access (tabel settings) supaya visitor di login page (belum auth)
--    bisa lihat info harga/WA/bank/banner. Settings non-sensitif, aman jadi public.
-- 3. Admin tetap satu-satunya yang bisa write
-- =============================================================================

-- 1. Tambah kolom pembelian jsonb (default value sesuai default lama)
alter table public.settings
  add column if not exists pembelian jsonb not null default '{
    "wa": "6282330647698",
    "proPrice": "500.000",
    "basicPrice": "0",
    "trialDays": 7,
    "bankInfo": "BCA 1234567890 a.n. Subariyanto, S.Pd, M.Pd.I",
    "bannerText": "Aktifkan akses penuh aplikasi Pendampingan KBC dengan kode aktivasi resmi dari Pokjawas Madrasah Kabupaten Jember."
  }'::jsonb;

-- 2. Pastikan ada baris settings dengan id=1 (idempotent)
insert into public.settings (id) values (1)
on conflict (id) do nothing;

-- 3. Relax policy: public bisa SELECT tabel settings
drop policy if exists "settings_read_all" on public.settings;
create policy "settings_read_all" on public.settings
  for select using (true);

-- 4. Reload schema cache
select pg_notify('pgrst', 'reload schema');
-- =============================================================================
-- migration-006-pengawas-full-write.sql
-- Pengawas yg login via kode aktivasi adalah CUSTOMER yg butuh akses penuh
-- input/edit data sendiri (madrasah, pengawas, jadwal, pendampingan, eviden,
-- tindak lanjut, instrumen, settings).
--
-- Sebelumnya policy *_admin_write/_write hanya izinin role='admin'. Kita
-- relax jadi role IN ('admin', 'pengawas') untuk semua tabel data utama.
--
-- Idempotent: drop policy lama, buat ulang dengan rule baru.
-- =============================================================================

-- 1. PENGAWAS
drop policy if exists "pengawas_admin_write" on public.pengawas;
create policy "pengawas_admin_write" on public.pengawas
  for all to authenticated
  using (exists (select 1 from public.profiles where id = auth.uid() and role in ('admin', 'pengawas')))
  with check (exists (select 1 from public.profiles where id = auth.uid() and role in ('admin', 'pengawas')));

-- 2. MADRASAH
drop policy if exists "madrasah_admin_write" on public.madrasah;
create policy "madrasah_admin_write" on public.madrasah
  for all to authenticated
  using (exists (select 1 from public.profiles where id = auth.uid() and role in ('admin', 'pengawas')))
  with check (exists (select 1 from public.profiles where id = auth.uid() and role in ('admin', 'pengawas')));

-- 3. INSTRUMEN ASPEK & INDIKATOR
drop policy if exists "aspek_admin_write" on public.instrumen_aspek;
create policy "aspek_admin_write" on public.instrumen_aspek
  for all to authenticated
  using (exists (select 1 from public.profiles where id = auth.uid() and role in ('admin', 'pengawas')))
  with check (exists (select 1 from public.profiles where id = auth.uid() and role in ('admin', 'pengawas')));

drop policy if exists "ind_admin_write" on public.instrumen_indikator;
create policy "ind_admin_write" on public.instrumen_indikator
  for all to authenticated
  using (exists (select 1 from public.profiles where id = auth.uid() and role in ('admin', 'pengawas')))
  with check (exists (select 1 from public.profiles where id = auth.uid() and role in ('admin', 'pengawas')));

-- 4. SETTINGS (mendukung pengawas luar kabupaten edit data instansi sendiri)
drop policy if exists "settings_admin_write" on public.settings;
create policy "settings_admin_write" on public.settings
  for all to authenticated
  using (exists (select 1 from public.profiles where id = auth.uid() and role in ('admin', 'pengawas')))
  with check (exists (select 1 from public.profiles where id = auth.uid() and role in ('admin', 'pengawas')));

-- 5. JADWAL — pengawas full akses (tidak lagi terbatas ke madrasah binaan saja
-- karena pengawas customer baru belum di-link ke pengawas record)
drop policy if exists "jadwal_write" on public.jadwal;
create policy "jadwal_write" on public.jadwal
  for all to authenticated
  using (exists (select 1 from public.profiles where id = auth.uid() and role in ('admin', 'pengawas')))
  with check (exists (select 1 from public.profiles where id = auth.uid() and role in ('admin', 'pengawas')));

-- jadwal_read: pengawas bisa baca semua (sebelumnya filter ke madrasah binaan)
drop policy if exists "jadwal_read" on public.jadwal;
create policy "jadwal_read" on public.jadwal
  for select to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and (
          p.role in ('admin', 'viewer', 'pengawas')
          or (p.role = 'kepala' and jadwal.madrasah_id = p.madrasah_id)
        )
    )
  );

-- 6. PENDAMPINGAN
drop policy if exists "pen_write" on public.pendampingan;
create policy "pen_write" on public.pendampingan
  for all to authenticated
  using (exists (select 1 from public.profiles where id = auth.uid() and role in ('admin', 'pengawas')))
  with check (exists (select 1 from public.profiles where id = auth.uid() and role in ('admin', 'pengawas')));

drop policy if exists "pen_read" on public.pendampingan;
create policy "pen_read" on public.pendampingan
  for select to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and (
          p.role in ('admin', 'viewer', 'pengawas')
          or (p.role = 'kepala' and pendampingan.madrasah_id = p.madrasah_id)
        )
    )
  );

-- 7. EVIDEN
drop policy if exists "ev_write" on public.eviden;
create policy "ev_write" on public.eviden
  for all to authenticated
  using (exists (select 1 from public.profiles where id = auth.uid() and role in ('admin', 'pengawas')))
  with check (exists (select 1 from public.profiles where id = auth.uid() and role in ('admin', 'pengawas')));

drop policy if exists "ev_read" on public.eviden;
create policy "ev_read" on public.eviden
  for select to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and (
          p.role in ('admin', 'viewer', 'pengawas')
          or (p.role = 'kepala' and eviden.madrasah_id = p.madrasah_id)
        )
    )
  );

-- 8. TINDAK LANJUT
drop policy if exists "tl_write" on public.tindak_lanjut;
create policy "tl_write" on public.tindak_lanjut
  for all to authenticated
  using (exists (select 1 from public.profiles where id = auth.uid() and role in ('admin', 'pengawas')))
  with check (exists (select 1 from public.profiles where id = auth.uid() and role in ('admin', 'pengawas')));

drop policy if exists "tl_read" on public.tindak_lanjut;
create policy "tl_read" on public.tindak_lanjut
  for select to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and (
          p.role in ('admin', 'viewer', 'pengawas')
          or (p.role = 'kepala' and tindak_lanjut.madrasah_id = p.madrasah_id)
        )
    )
  );

-- ===== Verify =====
-- select tablename, policyname, cmd, roles, qual, with_check
-- from pg_policies
-- where schemaname = 'public'
--   and policyname like '%admin_write%' or policyname like '%_write%';
-- =============================================================================
-- migration-007-claim-activation-code-rpc.sql
-- RPC public untuk klaim kode aktivasi tanpa perlu login Supabase.
-- Mendukung mode aplikasi LOCAL_ONLY: user di browser cukup masukkan kode +
-- nama, RPC ini validasi & tandai kode sebagai used dalam 1 transaksi atomik.
-- =============================================================================

create or replace function public.claim_activation_code(
  p_code text,
  p_nama text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.activation_codes%rowtype;
  v_master text := 'KBC-POKJAWAS-JEMBER-2026';
begin
  -- Master code: tidak ditandai used (reusable owner backdoor)
  if upper(trim(p_code)) = v_master then
    return jsonb_build_object(
      'ok', true,
      'master', true,
      'tier', 'pro',
      'validity_days', 0,
      'role', 'admin',
      'nama', coalesce(nullif(trim(p_nama), ''), 'Owner')
    );
  end if;

  -- Kode biasa: ambil row, validasi
  select * into v_row
  from public.activation_codes
  where code = upper(trim(p_code));

  if not found then
    return jsonb_build_object('ok', false, 'error', 'Kode aktivasi tidak ditemukan');
  end if;

  if v_row.used then
    return jsonb_build_object('ok', false, 'error', 'Kode aktivasi sudah digunakan');
  end if;

  -- Tandai used
  update public.activation_codes
  set used = true,
      used_at = now(),
      used_by_nama = coalesce(nullif(trim(p_nama), ''), v_row.nama, 'User')
  where id = v_row.id;

  return jsonb_build_object(
    'ok', true,
    'master', false,
    'tier', coalesce(v_row.tier, 'pro'),
    'validity_days', coalesce(v_row.validity_days, 0),
    'role', coalesce(v_row.role, 'pengawas'),
    'nama', coalesce(nullif(trim(p_nama), ''), v_row.nama, 'User')
  );
end;
$$;

-- Public dapat eksekusi RPC ini (anon + authenticated)
grant execute on function public.claim_activation_code(text, text) to anon, authenticated;

-- Tambah kolom used_by_nama kalau belum ada (opsional, untuk lacak siapa pakai)
alter table public.activation_codes
  add column if not exists used_by_nama text;
-- =============================================================================
-- migration-008-signed-code-claims.sql
-- Single-use enforcement untuk signed license codes.
--
-- Saat user aktivasi kode di browser baru, ActivationPage panggil RPC
-- claim_signed_code(p_code, p_device_fp, p_nama). Kalau code sudah ada di
-- tabel ini dengan device_fp berbeda -> reject (kode sudah dipakai). Kalau
-- belum ada atau device_fp sama -> ok.
--
-- Tujuan: customer tidak bisa pakai 1 kode di banyak device. Pindah device
-- legitimate dilakukan via backup/restore JSON (di-export dari device lama,
-- import ke device baru, lisensi + device_fp ikut di-restore -> RPC re-claim
-- dengan device_fp sama -> ok).
-- =============================================================================

create table if not exists public.signed_code_claims (
  code text primary key,
  device_fp text not null,
  nama text,
  tier text,
  claimed_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now()
);

alter table public.signed_code_claims enable row level security;

-- Public read (untuk admin panel statistik kalau perlu, lewat RPC saja)
drop policy if exists "claims_select" on public.signed_code_claims;
create policy "claims_select" on public.signed_code_claims
  for select to authenticated using (true);

-- Tidak ada policy insert/update direct -- semua via RPC security definer.

-- =============================================================================
-- RPC claim_signed_code
-- =============================================================================
create or replace function public.claim_signed_code(
  p_code text,
  p_device_fp text,
  p_nama text default null,
  p_tier text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_clean_code text := upper(trim(p_code));
  v_clean_fp text := trim(p_device_fp);
  v_existing public.signed_code_claims%rowtype;
begin
  if v_clean_code = '' or v_clean_fp = '' then
    return jsonb_build_object('ok', false, 'error', 'Kode atau device fingerprint kosong');
  end if;

  -- Master code: tidak di-track, tidak ada single-use enforcement
  if v_clean_code = 'KBC-POKJAWAS-JEMBER-2026' then
    return jsonb_build_object('ok', true, 'master', true);
  end if;

  select * into v_existing from public.signed_code_claims where code = v_clean_code;

  if found then
    -- Device sama -> ok (re-aktivasi setelah clear localStorage di device sama
    -- masih dianggap legitimate, atau restore backup di device sama)
    if v_existing.device_fp = v_clean_fp then
      update public.signed_code_claims
        set last_seen_at = now()
        where code = v_clean_code;
      return jsonb_build_object('ok', true, 'rebind', false, 'first_claimed_at', v_existing.claimed_at);
    else
      -- Device beda -> reject
      return jsonb_build_object(
        'ok', false,
        'error', 'Kode sudah digunakan di device lain pada ' ||
                 to_char(v_existing.claimed_at at time zone 'Asia/Jakarta', 'DD Mon YYYY HH24:MI'),
        'first_claimed_at', v_existing.claimed_at,
        'first_nama', v_existing.nama
      );
    end if;
  else
    -- Belum ada -> klaim
    insert into public.signed_code_claims (code, device_fp, nama, tier)
      values (v_clean_code, v_clean_fp, nullif(trim(p_nama), ''), nullif(trim(p_tier), ''));
    return jsonb_build_object('ok', true, 'first_claim', true);
  end if;
end;
$$;

grant execute on function public.claim_signed_code(text, text, text, text) to anon, authenticated;
-- =============================================================================
-- KBC Migration 009: Accept 'kepala_madrasah' role
-- =============================================================================
-- App menggunakan 'kepala_madrasah', schema lama cuma terima 'kepala'.
-- Update check constraint + admin_update_profile agar konsisten.
-- Idempotent: boleh dijalankan berulang.
-- =============================================================================

-- 1. Update check constraint pada profiles.role
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles drop constraint if exists profiles_role_check1;
alter table public.profiles add constraint profiles_role_check
  check (role in ('admin','pengawas','kepala','kepala_madrasah','viewer'));

-- 2. Update admin_update_profile agar terima kepala_madrasah
create or replace function public.admin_update_profile(
  target_id uuid,
  new_nama text,
  new_role text,
  new_pengawas_id uuid,
  new_madrasah_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Forbidden: hanya admin yang bisa update profile';
  end if;
  if new_role not in ('admin','pengawas','kepala','kepala_madrasah','viewer') then
    raise exception 'Role tidak valid: %', new_role;
  end if;
  update public.profiles
  set nama = coalesce(new_nama, nama),
      role = new_role,
      pengawas_id = new_pengawas_id,
      madrasah_id = new_madrasah_id
  where id = target_id;
end $$;

grant execute on function public.admin_update_profile(uuid, text, text, uuid, uuid) to authenticated;

-- 3. Update activation_codes check constraint (jika ada)
alter table public.activation_codes drop constraint if exists activation_codes_role_check;
alter table public.activation_codes drop constraint if exists activation_codes_role_check1;
alter table public.activation_codes add constraint activation_codes_role_check
  check (role in ('admin','pengawas','kepala','kepala_madrasah','viewer'));

notify pgrst, 'reload schema';
