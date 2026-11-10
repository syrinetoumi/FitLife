begin;
-- Les lignes créées par ce contrôle sont toutes annulées à la fin.
select set_config('request.jwt.claims', jsonb_build_object('sub',(select id from auth.users where email='manager@test.com'),'role','authenticated')::text,true);
set local role authenticated;
do $$
declare e bigint; o bigint;
begin
  assert public.contexte_espaces()->>'role'='GESTIONNAIRE_ESPACE';
  insert into public.espace_sportif(nom,type,adresse)
  values ('Validation temporaire','SALLE','Tunis') returning id_espace into e;
  update public.espace_sportif set statut='ACTIF' where id_espace=e;
  insert into public.equipement(nom,quantite,etat,id_espace) values ('Test',2,'BON',e);
  insert into public.disponibilite_espace(jour,heure_ouverture,heure_fermeture,id_espace) values ('LUNDI','08:00','12:00',e);
  begin
    insert into public.disponibilite_espace(jour,heure_ouverture,heure_fermeture,id_espace) values ('LUNDI','11:00','13:00',e);
    raise exception 'Chevauchement accepté à tort';
  exception when exclusion_violation then null; end;
  insert into public.disponibilite_espace(jour,heure_ouverture,heure_fermeture,id_espace) values ('LUNDI','12:00','18:00',e);
  insert into public.offre(nom,type,prix,duree,date_debut,statut,id_espace)
  values ('Validation offre','ABONNEMENT',12345.678,30,(current_timestamp at time zone 'Africa/Tunis')::date,'ACTIVE',e) returning id_offre into o;
  perform set_config('fitlife.test_espace',e::text,true);
  perform set_config('fitlife.test_offre',o::text,true);
end $$;
reset role;
select set_config('request.jwt.claims', jsonb_build_object('sub',(select id from auth.users where email='athlete@test.com'),'role','authenticated')::text,true);
set local role authenticated;
do $$
declare a jsonb; n integer;
begin
  assert public.contexte_espaces()->>'role'='ATHLETE';
  a:=public.souscrire_offre(current_setting('fitlife.test_offre')::bigint);
  assert a->>'montant'='12345.678';
  assert (a->>'date_fin')::date=(a->>'date_debut')::date+29;
  perform set_config('fitlife.test_abonnement',a->>'id_abonnement',true);
  begin
    perform public.souscrire_offre(current_setting('fitlife.test_offre')::bigint);
    raise exception 'Doublon accepté à tort';
  exception when exclusion_violation then null; end;
  update public.espace_sportif set nom='Interdit' where id_espace=current_setting('fitlife.test_espace')::bigint;
  get diagnostics n=row_count;
  assert n=0;
  begin
    update public.profiles set role='ADMIN' where id=auth.uid();
    raise exception 'Élévation de rôle acceptée à tort';
  exception when insufficient_privilege then null; end;
  begin
    perform public.changer_statut_abonnement(current_setting('fitlife.test_abonnement')::bigint,'SUSPENDU');
    raise exception 'Suspension athlète acceptée à tort';
  exception when insufficient_privilege or invalid_parameter_value then null; end;
end $$;
reset role;
select set_config('request.jwt.claims', jsonb_build_object('sub',(select id from auth.users where email='manager@test.com'),'role','authenticated')::text,true);
set local role authenticated;
do $$
declare a jsonb;
begin
  a:=public.changer_statut_abonnement(current_setting('fitlife.test_abonnement')::bigint,'SUSPENDU');
  assert a->>'statut'='SUSPENDU';
  a:=public.changer_statut_abonnement(current_setting('fitlife.test_abonnement')::bigint,'ACTIF');
  assert a->>'statut'='ACTIF';
  assert (a->>'date_fin')::date=(a->>'date_debut')::date+29;
end $$;
reset role;
select set_config('request.jwt.claims', jsonb_build_object('sub',(select id from auth.users where email='admin@test.com'),'role','authenticated')::text,true);
set local role authenticated;
do $$
declare n integer;
begin
  assert public.contexte_espaces()->>'role'='ADMIN';
  update public.profiles set actif=false where id=(select id_gestionnaire from public.espace_sportif where id_espace=current_setting('fitlife.test_espace')::bigint);
  get diagnostics n=row_count;
  assert n=1;
end $$;
reset role;
select set_config('request.jwt.claims','{}',true);
set local role anon;
do $$ begin
  begin
    perform id from public.profiles limit 1;
    raise exception 'Lecture anonyme des profils acceptée à tort';
  exception when insufficient_privilege then null; end;
end $$;
rollback;
