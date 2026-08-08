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
