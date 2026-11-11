-- Jeu fictif demandé pour préparer les essais manuels des API ; aucun appel fournisseur.
-- Réexécutable : ne renomme pas les espaces existants et ne crée aucun abonnement.
begin;
do $$
declare
  gestionnaire uuid;
  espace record;
  lieu record;
  offre_test record;
  materiel record;
  jour_test public.jour_semaine;
  aujourd_hui date := (now() at time zone 'Africa/Tunis')::date;
  marque constant text := '[FITLIFE_API_DATA_20261111]';
begin
  select p.id into gestionnaire from public.profiles p
  where p.role::text='GESTIONNAIRE_ESPACE' and p.actif is true
  order by (select count(*) from public.espace_sportif e where e.id_gestionnaire=p.id) desc,p.id
  limit 1;
  if gestionnaire is null then raise exception 'Gestionnaire actif requis.'; end if;

  for lieu in select * from (values
    ('adfad','SALLE',36.848::double precision,10.175::double precision,'El Menzah, Tunis, Tunisie'),
    ('frasdf','CLUB_SPORTIF',36.878,10.325,'La Marsa, Tunisie'),
    ('nkfodsd','TERRAIN',36.848,10.175,'El Menzah, Tunis, Tunisie'),
    ('zrqplm','CENTRE_SPORTIF',36.878,10.325,'La Marsa, Tunisie'),
    ('plmokn','PISCINE',36.848,10.175,'El Menzah, Tunis, Tunisie'),
    ('vbnqsd','PARC',35.829,10.640,'Sousse, Tunisie'),
    ('qsdfrt','STADE',35.829,10.640,'Sousse, Tunisie'),
    ('xkfod','AUTRE',36.848,10.175,'El Menzah, Tunis, Tunisie')
  ) as x(nom,type,latitude,longitude,adresse)
  loop
    insert into public.espace_sportif(nom,type,adresse,description,latitude,longitude,telephone,email,site_web,statut,id_gestionnaire)
    select lieu.nom,lieu.type::public.type_espace,lieu.adresse,
      marque||' Établissement fictif. Coordonnées de repère réutilisées pour préparer les itinéraires ; elles ne localisent pas un véritable établissement portant ce nom.',
      lieu.latitude,lieu.longitude,'+216 00 000 000',lieu.nom||'@example.invalid',
      'https://example.invalid/'||lieu.nom,'ACTIF',gestionnaire
    where not exists (select 1 from public.espace_sportif e where e.nom=lieu.nom and e.id_gestionnaire=gestionnaire);
  end loop;

  -- Complète uniquement les valeurs manquantes ; conserve noms, statuts et propriétaires.
  update public.espace_sportif set
    latitude=coalesce(latitude,36.848),longitude=coalesce(longitude,10.175),
    description=coalesce(nullif(btrim(description),''),marque||' Espace préparé pour les essais manuels.'),
    telephone=coalesce(nullif(btrim(telephone),''),'+216 00 000 000'),
    email=coalesce(nullif(btrim(email),''),'espace-'||id_espace||'@example.invalid'),
    site_web=coalesce(nullif(btrim(site_web),''),'https://example.invalid/espace-'||id_espace)
  where id_gestionnaire=gestionnaire;

  for espace in select id_espace,nom from public.espace_sportif where id_gestionnaire=gestionnaire
  loop
    for offre_test in select * from (values
      ('adfad','SEANCE',0.000::numeric,1,'ACTIVE'),
      ('frasdf','ABONNEMENT',39.900,7,'ACTIVE'),
      ('nkfodsd','ABONNEMENT',89.500,30,'ACTIVE'),
      ('plmqsd','PACK',149.990,60,'ACTIVE'),
      ('zrqfad','PACK',219.750,90,'INACTIVE')
    ) as x(nom,type,prix,duree,statut)
    loop
      insert into public.offre(nom,description,type,prix,duree,date_debut,date_fin,statut,id_espace)
      select offre_test.nom||'-'||espace.id_espace,
        marque||' Offre fictive pour '||espace.nom||'. Accès pour '||offre_test.duree||' jour(s), sans paiement réel intégré.',
        offre_test.type::public.type_offre,offre_test.prix,offre_test.duree,
        aujourd_hui-7,aujourd_hui+365,offre_test.statut::public.statut_offre,espace.id_espace
      where not exists (select 1 from public.offre o where o.id_espace=espace.id_espace and o.nom=offre_test.nom||'-'||espace.id_espace);
    end loop;

    for materiel in select * from (values
      ('adfad',12,'BON'),('frasdf',6,'BON'),('nkfodsd',3,'BON'),('plmokn',0,'EN_MAINTENANCE')
    ) as x(nom,quantite,etat)
    loop
      insert into public.equipement(nom,description,quantite,etat,id_espace)
      select materiel.nom||'-'||espace.id_espace,marque||' Matériel fictif pour vérifier quantité et disponibilité.',
        materiel.quantite,materiel.etat::public.etat_equipement,espace.id_espace
      where not exists (select 1 from public.equipement e where e.id_espace=espace.id_espace and e.nom=materiel.nom||'-'||espace.id_espace);
    end loop;

    foreach jour_test in array enum_range(null::public.jour_semaine)
    loop
      insert into public.disponibilite_espace(jour,heure_ouverture,heure_fermeture,id_espace)
      select jour_test,'07:00'::time,'22:00'::time,espace.id_espace
      where not exists (select 1 from public.disponibilite_espace d where d.id_espace=espace.id_espace and d.jour=jour_test);
    end loop;
  end loop;
end $$;
commit;

select jsonb_build_object(
  'new_spaces',(select count(*) from public.espace_sportif where description like '[FITLIFE_API_DATA_20261111] Établissement fictif.%'),
  'new_offers',(select count(*) from public.offre where description like '[FITLIFE_API_DATA_20261111]%'),
  'new_active_offers',(select count(*) from public.offre where description like '[FITLIFE_API_DATA_20261111]%' and statut='ACTIVE'),
  'new_equipment',(select count(*) from public.equipement where description like '[FITLIFE_API_DATA_20261111]%'),
  'total_spaces',(select count(*) from public.espace_sportif),
  'spaces_without_coordinates',(select count(*) from public.espace_sportif where latitude is null or longitude is null),
  'spaces_without_offers',(select count(*) from public.espace_sportif e where not exists(select 1 from public.offre o where o.id_espace=e.id_espace))
) as data_added;
