-- Les politiques existantes sont ajustées sans les supprimer.
create or replace function espace_prive.est_admin()
returns boolean language sql stable security definer set search_path = ''
as $$ select exists(select 1 from public.profiles where id=auth.uid() and role='ADMIN' and actif is true) $$;
revoke all on function espace_prive.est_admin() from public, anon;
grant execute on function espace_prive.est_admin() to authenticated;

alter policy "Autoriser update profils" on public.profiles
using (id=(select auth.uid()) or (select espace_prive.est_admin()))
with check (id=(select auth.uid()) or (select espace_prive.est_admin()));
alter policy profiles_espaces_modification_protegee on public.profiles
using (id=(select auth.uid()) or (select espace_prive.est_admin()))
with check (id=(select auth.uid()) or (select espace_prive.est_admin()));

create or replace function public.proteger_role_profil()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if auth.uid() is not null and
     (new.role is distinct from old.role or new.actif is distinct from old.actif)
     and not espace_prive.est_admin() then
    raise exception 'Seul un administrateur actif peut modifier le rôle ou l''activation' using errcode='42501';
  end if;
  return new;
end $$;
create or replace trigger proteger_role_profil before update on public.profiles
for each row execute function public.proteger_role_profil();
revoke all on public.profiles from anon;
revoke delete, truncate, references, trigger on public.profiles from authenticated;
grant select on public.profiles to authenticated;
grant update (nom,prenom,telephone,photo,date_naissance,genre,actif,role) on public.profiles to authenticated;
alter table public.profiles enable row level security;
revoke all on function public.proteger_role_profil() from public, anon, authenticated;

