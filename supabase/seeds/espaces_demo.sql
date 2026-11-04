-- Données fictives de présentation. Relancer ce fichier ne duplique pas les lieux.
begin;
select pg_advisory_xact_lock(20261104,42);
do $$
declare
  gestionnaire uuid;
  lieu record;
  materiel record;
  espace bigint;
  jour_ouverture public.jour_semaine;
  aujourd_hui date := (current_timestamp at time zone 'Africa/Tunis')::date;
begin
  select p.id into gestionnaire from public.profiles p join auth.users u on u.id=p.id
    where lower(u.email)='manager@test.com' and p.role='GESTIONNAIRE_ESPACE' and p.actif is true;
  if gestionnaire is null then raise exception 'Un compte gestionnaire actif est requis.'; end if;
  for lieu in select * from (values
    ('Atlas Training Club','SALLE','Les Berges du Lac, Tunis',36.837,10.246,15.000,80.000),
    ('Terrain Horizon','TERRAIN','El Menzah, Ariana',36.848,10.175,10.000,60.000),
    ('Bassin Azur','PISCINE','La Marsa, Tunis',36.878,10.325,12.000,70.000),
    ('Parc Énergie','PARC','Zone de loisirs, Sousse',35.829,10.640,0.000,25.000)
  ) as v(nom,type,adresse,latitude,longitude,prix_jour,prix_abonnement) loop
    if exists(select 1 from public.espace_sportif where nom in (lieu.nom,'Démo · ' || lieu.nom) and id_gestionnaire=gestionnaire) then continue; end if;
    insert into public.espace_sportif(nom,type,adresse,description,latitude,longitude,statut,id_gestionnaire)
    values(lieu.nom,lieu.type::public.type_espace,lieu.adresse,
      'Lieu fictif pour tester FitLife. Adresse et coordonnées indicatives, sans établissement réel associé.',
      lieu.latitude,lieu.longitude,'ACTIF',gestionnaire)
    returning id_espace into espace;
    for materiel in select * from (values
      ('SALLE','Haltères',16,'BON'),('SALLE','Tapis de course',4,'BON'),('SALLE','Rameur',1,'EN_MAINTENANCE'),
      ('TERRAIN','Ballons',8,'BON'),('TERRAIN','Chasubles',20,'BON'),('TERRAIN','Plots',12,'BON'),
      ('PISCINE','Planches de natation',15,'BON'),('PISCINE','Palmes',12,'BON'),('PISCINE','Bouée',1,'HORS_SERVICE'),
      ('PARC','Tapis de sol',10,'BON'),('PARC','Bandes élastiques',12,'BON'),('PARC','Kettlebells',6,'BON')
    ) as v(type,nom,quantite,etat) where v.type=lieu.type loop
      insert into public.equipement(nom,description,quantite,etat,id_espace)
      values(materiel.nom,'Matériel d’entraînement.',materiel.quantite,materiel.etat::public.etat_equipement,espace);
    end loop;
    foreach jour_ouverture in array enum_range(null::public.jour_semaine) loop
      insert into public.disponibilite_espace(jour,heure_ouverture,heure_fermeture,id_espace)
      values(jour_ouverture,
        case when jour_ouverture='DIMANCHE' then time '09:00' else time '07:00' end,
        case when jour_ouverture='DIMANCHE' then time '14:00' else time '22:00' end,espace);
    end loop;
    insert into public.offre(nom,description,type,prix,duree,date_debut,date_fin,statut,id_espace) values
      ('Pass découverte','Accès pendant une journée aux horaires d’ouverture. Ne réserve pas une séance coach.',
       'SEANCE',lieu.prix_jour,1,aujourd_hui,null,'ACTIVE',espace),
      ('Essentiel 30 jours','Accès aux installations pendant 30 jours consécutifs. Offre fictive, sans paiement intégré.',
       'ABONNEMENT',lieu.prix_abonnement,30,aujourd_hui,null,'ACTIVE',espace);
  end loop;
end $$;
commit;
select e.nom,e.type,e.statut,
  (select count(*) from public.equipement q where q.id_espace=e.id_espace) as equipements,
  (select count(*) from public.disponibilite_espace d where d.id_espace=e.id_espace) as horaires,
  (select count(*) from public.offre o where o.id_espace=e.id_espace and o.statut='ACTIVE') as offres_actives
from public.espace_sportif e
where e.id_gestionnaire=(select id from auth.users where lower(email)='manager@test.com')
  and e.nom in ('Atlas Training Club','Terrain Horizon','Bassin Azur','Parc Énergie') order by e.id_espace;

