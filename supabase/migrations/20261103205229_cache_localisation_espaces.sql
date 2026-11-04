-- Le verrou partagé limite les recherches pour toute l’application, même avec plusieurs instances.
create table if not exists espace_prive.cache_geocodage (
  recherche text primary key,
  resultat jsonb not null,
  expiration timestamptz not null
);
create table if not exists espace_prive.quota_geocodage (
  id boolean primary key default true check (id),
  prochain timestamptz not null default now()
);
insert into espace_prive.quota_geocodage(id) values (true) on conflict do nothing;
alter table espace_prive.cache_geocodage enable row level security;
alter table espace_prive.quota_geocodage enable row level security;

create or replace function public.preparer_geocodage(p_recherche text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare cache jsonb; prochain_appel timestamptz;
begin
  if length(p_recherche) not between 3 and 250 then raise exception 'Recherche invalide'; end if;
  select resultat into cache from espace_prive.cache_geocodage
    where recherche=p_recherche and expiration>now();
  if found then return jsonb_build_object('cache',cache); end if;
  select prochain into prochain_appel from espace_prive.quota_geocodage where id=true for update;
  if prochain_appel>clock_timestamp() then return jsonb_build_object('attendre',true); end if;
  update espace_prive.quota_geocodage set prochain=clock_timestamp()+interval '20 seconds' where id=true;
  return jsonb_build_object('autorise',true);
end $$;
create or replace function public.memoriser_geocodage(p_recherche text,p_resultat jsonb)
returns void language sql security definer set search_path = '' as $$
  update espace_prive.quota_geocodage set prochain=clock_timestamp()+interval '2 seconds' where id=true;
  insert into espace_prive.cache_geocodage(recherche,resultat,expiration)
  values(p_recherche,p_resultat,now()+interval '30 days')
  on conflict(recherche) do update set resultat=excluded.resultat,expiration=excluded.expiration;
$$;
revoke all on function public.preparer_geocodage(text) from public,anon,authenticated;
revoke all on function public.memoriser_geocodage(text,jsonb) from public,anon,authenticated;
grant execute on function public.preparer_geocodage(text) to service_role;
grant execute on function public.memoriser_geocodage(text,jsonb) to service_role;
