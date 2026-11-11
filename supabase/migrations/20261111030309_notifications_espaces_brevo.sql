create table espace_prive.notifications_espaces (
  id uuid primary key default gen_random_uuid(),
  id_abonnement bigint not null references public.abonnement(id_abonnement) on delete cascade,
  nature text not null check (nature in ('CONFIRMATION', 'EXPIRATION')),
  fin_abonnement date not null,
  cree_le timestamptz not null default now(),
  etat text not null default 'EN_ATTENTE' check (etat in ('EN_ATTENTE','ACCEPTEE','IGNOREE','A_VERIFIER')),
  prochain_essai timestamptz not null default now(),
  bail uuid,
  essais integer not null default 0,
  premier_essai timestamptz,
  message_fournisseur text,
  dernier_code text,
  unique (id_abonnement, nature, fin_abonnement)
);
create index notifications_espaces_attente_idx
  on espace_prive.notifications_espaces(prochain_essai) where etat='EN_ATTENTE';
alter table espace_prive.notifications_espaces enable row level security;
revoke all on espace_prive.notifications_espaces from public, anon, authenticated;

-- L'événement et la souscription sont validés ensemble ; aucun appel HTTP dans la transaction.
create function espace_prive.notifier_souscription() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into espace_prive.notifications_espaces(id_abonnement,nature,fin_abonnement)
    values(new.id_abonnement,'CONFIRMATION',new.date_fin);
  return new;
end $$;
revoke all on function espace_prive.notifier_souscription() from public, anon, authenticated;
create trigger notifier_souscription after insert on public.abonnement
  for each row execute function espace_prive.notifier_souscription();

-- Cette opération est exclusivement appelée par le worker serveur.
create function public.reclamer_notifications_espaces(p_limite integer default 20) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare resultat jsonb; jour date := (now() at time zone 'Africa/Tunis')::date;
begin
  insert into espace_prive.notifications_espaces(id_abonnement,nature,fin_abonnement)
    select a.id_abonnement,'EXPIRATION',a.date_fin from public.abonnement a
    join public.profiles p on p.id=a.id_athlete
    where a.statut='ACTIF' and p.actif is true and a.date_fin=jour+3
    on conflict (id_abonnement,nature,fin_abonnement) do nothing;

  -- Les rappels périmés ou invalidés ne sont jamais rattrapés après leur fenêtre.
  update espace_prive.notifications_espaces n set etat='IGNOREE',dernier_code='PERIMEE'
  where n.etat='EN_ATTENTE' and not exists (
    select 1 from public.abonnement a join public.profiles p on p.id=a.id_athlete
    where a.id_abonnement=n.id_abonnement and a.statut='ACTIF' and p.actif is true
      and a.date_fin=n.fin_abonnement and a.date_fin>=jour
      and ((n.nature='CONFIRMATION' and n.cree_le>now()-interval '24 hours')
        or (n.nature='EXPIRATION' and a.date_fin=jour+3))
  );

  -- Brevo ne déduplique que 30 minutes : aucune reprise automatique après une incertitude longue.
  update espace_prive.notifications_espaces set etat='A_VERIFIER',dernier_code='FENETRE_DEDUPLICATION'
    where etat='EN_ATTENTE' and premier_essai<=now()-interval '25 minutes';

  with selection as (
    select n.id from espace_prive.notifications_espaces n
    join public.abonnement a on a.id_abonnement=n.id_abonnement
    join auth.users u on u.id=a.id_athlete and u.email_confirmed_at is not null
      and nullif(u.email,'') is not null
    where n.etat='EN_ATTENTE' and n.prochain_essai<=now()
    order by n.prochain_essai,n.id
    limit greatest(1,least(coalesce(p_limite,20),20))
    for update of n skip locked
  ), reservees as (
    update espace_prive.notifications_espaces n
    set bail=gen_random_uuid(),prochain_essai=now()+interval '5 minutes',essais=n.essais+1,
        premier_essai=coalesce(n.premier_essai,now())
    from selection s where n.id=s.id returning n.id,n.bail
  )
  select coalesce(jsonb_agg(jsonb_build_object('id',id,'bail',bail)),'[]'::jsonb)
    into resultat from reservees;
  return resultat;
end $$;

-- L'état est revérifié juste avant chaque envoi et l'identité vient exclusivement du serveur.
create function public.preparer_notification_espace(p_id uuid,p_bail uuid) returns jsonb
language sql security definer set search_path = '' as $$
  select jsonb_build_object(
    'id',n.id,'email',u.email,'id_abonnement',a.id_abonnement::text,'nature',n.nature,
    'offre',o.nom,'espace',e.nom,'date_debut',a.date_debut,'date_fin',a.date_fin,'montant',a.montant::text
  )
  from espace_prive.notifications_espaces n
  join public.abonnement a on a.id_abonnement=n.id_abonnement
  join public.profiles p on p.id=a.id_athlete
  join auth.users u on u.id=a.id_athlete and u.email_confirmed_at is not null
  join public.offre o on o.id_offre=a.id_offre
  join public.espace_sportif e on e.id_espace=o.id_espace
  where n.id=p_id and n.bail=p_bail and n.etat='EN_ATTENTE'
    and n.prochain_essai>now() and a.statut='ACTIF' and p.actif is true
    and nullif(u.email,'') is not null
    and n.premier_essai>now()-interval '25 minutes'
    and a.date_fin=n.fin_abonnement
    and a.date_fin >= (now() at time zone 'Africa/Tunis')::date
    and ((n.nature='CONFIRMATION' and n.cree_le>now()-interval '24 hours')
      or (n.nature='EXPIRATION' and a.date_fin=(now() at time zone 'Africa/Tunis')::date+3))
$$;

create function public.terminer_notification_espace(
  p_id uuid,p_bail uuid,p_etat text,p_code text default null,p_message text default null
) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if p_etat not in ('EN_ATTENTE','ACCEPTEE','IGNOREE','A_VERIFIER') or p_etat is null then
    raise exception 'État invalide.';
  end if;
  update espace_prive.notifications_espaces
  set etat=p_etat,dernier_code=left(p_code,80),message_fournisseur=left(p_message,100),
      prochain_essai=now()+interval '15 minutes',bail=null
  where id=p_id and bail=p_bail and etat='EN_ATTENTE';
end $$;

revoke all on function public.reclamer_notifications_espaces(integer) from public,anon,authenticated;
revoke all on function public.preparer_notification_espace(uuid,uuid) from public,anon,authenticated;
revoke all on function public.terminer_notification_espace(uuid,uuid,text,text,text) from public,anon,authenticated;
grant execute on function public.reclamer_notifications_espaces(integer) to service_role;
grant execute on function public.preparer_notification_espace(uuid,uuid) to service_role;
grant execute on function public.terminer_notification_espace(uuid,uuid,text,text,text) to service_role;

