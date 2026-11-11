-- Confirmation Novu uniquement ; les migrations déjà appliquées sont conservées.
alter table espace_prive.notifications_espaces
  add column id_destinataire uuid references public.profiles(id) on delete cascade;
update espace_prive.notifications_espaces
set etat='IGNOREE', dernier_code='CHANGEMENT_FOURNISSEUR', bail=null where etat='EN_ATTENTE';

create or replace function espace_prive.notifier_souscription() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into espace_prive.notifications_espaces(id_abonnement,nature,fin_abonnement,id_destinataire)
    values(new.id_abonnement,'CONFIRMATION',new.date_fin,new.id_athlete);
  return new;
end $$;

create function public.reclamer_confirmations_novu(p_destinataire uuid default null,p_limite integer default 20)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare resultat jsonb;
begin
  update espace_prive.notifications_espaces n set etat='IGNOREE',dernier_code='INVALIDE',bail=null
  where n.etat='EN_ATTENTE' and (p_destinataire is null or n.id_destinataire=p_destinataire)
    and (n.nature<>'CONFIRMATION' or n.cree_le<=now()-interval '24 hours' or not exists (
      select 1 from public.abonnement a join public.profiles p on p.id=a.id_athlete
      where a.id_abonnement=n.id_abonnement and a.id_athlete=n.id_destinataire
        and a.statut='ACTIF' and p.actif is true
    ));
  update espace_prive.notifications_espaces
  set etat='A_VERIFIER',dernier_code='FENETRE_DEDUPLICATION',bail=null
  where etat='EN_ATTENTE' and premier_essai<=now()-interval '25 minutes'
    and (p_destinataire is null or id_destinataire=p_destinataire);
  with selection as (
    select n.id from espace_prive.notifications_espaces n
    where n.etat='EN_ATTENTE' and n.nature='CONFIRMATION' and n.id_destinataire is not null
      and (p_destinataire is null or n.id_destinataire=p_destinataire) and n.prochain_essai<=now()
    order by n.prochain_essai,n.id limit greatest(1,least(coalesce(p_limite,20),20))
    for update of n skip locked
  ), reservees as (
    update espace_prive.notifications_espaces n
    set bail=gen_random_uuid(),prochain_essai=now()+interval '5 minutes',essais=n.essais+1,
        premier_essai=coalesce(n.premier_essai,now())
    from selection s where n.id=s.id returning n.id,n.bail
  ) select coalesce(jsonb_agg(jsonb_build_object('id',id,'bail',bail)),'[]'::jsonb) into resultat from reservees;
  return resultat;
end $$;
revoke all on function public.reclamer_confirmations_novu(uuid,integer) from public,anon,authenticated;
grant execute on function public.reclamer_confirmations_novu(uuid,integer) to service_role;

-- L'ancien point d'entrée ne fabrique plus de rappels.
create or replace function public.reclamer_notifications_espaces(p_limite integer default 20) returns jsonb
language sql security definer set search_path = '' as $$
  select public.reclamer_confirmations_novu(null,p_limite)
$$;

create or replace function public.preparer_notification_espace(p_id uuid,p_bail uuid) returns jsonb
language sql security definer set search_path = '' as $$
  select jsonb_build_object('id',n.id,'subscriber_id',n.id_destinataire)
  from espace_prive.notifications_espaces n
  join public.abonnement a on a.id_abonnement=n.id_abonnement and a.id_athlete=n.id_destinataire
  join public.profiles p on p.id=n.id_destinataire
  where n.id=p_id and n.bail=p_bail and n.etat='EN_ATTENTE' and n.nature='CONFIRMATION'
    and n.prochain_essai>now() and n.premier_essai>now()-interval '25 minutes'
    and n.cree_le>now()-interval '24 hours' and a.statut='ACTIF' and p.actif is true
$$;
